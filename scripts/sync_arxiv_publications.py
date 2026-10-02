#!/usr/bin/env python3
"""Discover Youngjae Yu's arXiv papers and create reviewable PI Lab drafts.

The default mode is read-only. It queries arXiv, downloads candidate PDFs to a
temporary directory, and reports only papers whose PDF gives positive evidence
that Youngjae Yu is a corresponding author. Use --apply with an explicit
--arxiv-id after reviewing the report to create a display: False draft and a
figure image under images/papers/.
"""

from __future__ import annotations

import argparse
import datetime as dt
import html
import json
import re
import shutil
import subprocess
import sys
import tempfile
import textwrap
import urllib.parse
import urllib.request
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable

from pypdf import PdfReader


ROOT = Path(__file__).resolve().parent.parent
PUBLICATIONS_DIR = ROOT / "_publications"
PAPERS_DIR = ROOT / "images" / "papers"
ARXIV_SEARCH = "https://arxiv.org/search/"
ARXIV_PDF = "https://arxiv.org/pdf/{paper_id}.pdf"
TARGET_NAME = "Youngjae Yu"


@dataclass(frozen=True)
class ArxivPaper:
    paper_id: str
    title: str
    abstract: str
    published: dt.date
    authors: tuple[str, ...]
    categories: tuple[str, ...]

    @property
    def abs_url(self) -> str:
        return f"https://arxiv.org/abs/{self.paper_id}"


def normalized(value: str) -> str:
    return re.sub(r"[^a-z0-9]", "", value.lower())


def compact(value: str) -> str:
    return " ".join(value.split())


def safe_stem(value: str, limit: int = 72) -> str:
    stem = re.sub(r"[^a-z0-9]+", "-", value.lower()).strip("-")
    return (stem[:limit].rstrip("-") or "arxiv-paper")


def yaml_string(value: str) -> str:
    return json.dumps(value, ensure_ascii=False)


def fetch(url: str) -> bytes:
    request = urllib.request.Request(url, headers={"User-Agent": "snupi-home-publication-sync/1.0"})
    with urllib.request.urlopen(request, timeout=30) as response:
        return response.read()


def plain_html(value: str) -> str:
    return compact(html.unescape(re.sub(r"<[^>]+>", " ", value)))


def parse_arxiv_search(payload: bytes) -> list[ArxivPaper]:
    """Parse arXiv's author-search page when the export API is rate limited."""
    page = payload.decode("utf-8", errors="replace")
    papers: list[ArxivPaper] = []
    for chunk in re.split(r'<li class="arxiv-result">', page)[1:]:
        identifier = re.search(r'arXiv:([\d.]+)', chunk)
        title = re.search(r'<p class="title is-5 mathjax">(.*?)</p>', chunk, re.DOTALL)
        authors = re.search(r'<p class="authors">(.*?)</p>', chunk, re.DOTALL)
        abstract = re.search(r'<span class="abstract-full[^>]*>(.*?)</span>', chunk, re.DOTALL)
        submitted = re.search(r'Submitted</span>\s*(\d{1,2})\s+(\w+),\s+(\d{4})', chunk)
        if not all((identifier, title, authors, abstract, submitted)):
            continue
        try:
            published = dt.datetime.strptime(" ".join(submitted.groups()), "%d %B %Y").date()
        except ValueError:
            continue
        author_names = tuple(plain_html(value) for value in re.findall(r'<a [^>]*>(.*?)</a>', authors.group(1)))
        categories = tuple(re.findall(r'>(cs\.[A-Z-]+)</span>', chunk.split('<p class="title', 1)[0]))
        paper = ArxivPaper(
            identifier.group(1), plain_html(title.group(1)), plain_html(abstract.group(1)), published, author_names, categories
        )
        if any(normalized(author) == normalized(TARGET_NAME) for author in paper.authors):
            papers.append(paper)
    return papers


def fetch_papers(limit: int) -> list[ArxivPaper]:
    search = urllib.parse.urlencode(
        {"query": TARGET_NAME, "searchtype": "author", "abstracts": "show", "order": "-announced_date_first", "size": limit}
    )
    return parse_arxiv_search(fetch(f"{ARXIV_SEARCH}?{search}"))


def existing_publications() -> dict[str, Path]:
    records: dict[str, Path] = {}
    for path in PUBLICATIONS_DIR.glob("*.md"):
        text = path.read_text(encoding="utf-8")
        for url in re.findall(r"https?://arxiv\.org/abs/([^\s?#]+)", text):
            records[re.sub(r"v\d+$", "", url.rstrip("/"))] = path
        name = re.search(r'^name:\s*"(.*)"\s*$', text, flags=re.MULTILINE)
        if name:
            records[f"title:{normalized(name.group(1))}"] = path
    return records


def pdf_text(pdf_path: Path, page_limit: int = 2) -> tuple[str, list[str]]:
    reader = PdfReader(str(pdf_path))
    page_texts = [(page.extract_text() or "") for page in reader.pages[:page_limit]]
    return "\n".join(page_texts), page_texts


def correspondence_evidence(text: str) -> tuple[bool, list[str]]:
    """Return only strong, reviewable evidence; never infer correspondence silently."""
    folded = compact(text).lower()
    target = TARGET_NAME.lower()
    evidence: list[str] = []
    for match in re.finditer(r"correspond(?:ing|ence)(?:\s+author)?", folded):
        start = max(0, match.start() - 260)
        end = min(len(folded), match.end() + 260)
        snippet = folded[start:end]
        if target in snippet:
            evidence.append(textwrap.shorten(folded[start:end], width=360, placeholder=" …"))
    # Some PDFs use a star-footnote with an e-mail address and a later note.
    email_pattern = r"[\w.+-]*youngjae[\w.+-]*@[\w.-]+"
    emails = re.findall(email_pattern, folded)
    if emails and "correspond" in folded and target in folded:
        evidence.append(f"PDF includes a Youngjae address ({emails[0]}) and correspondence text.")
    return bool(evidence), evidence[:3]


def choose_keywords(title: str, abstract: str, categories: Iterable[str]) -> list[str]:
    haystack = f"{title} {abstract}".lower()
    rules = [
        ("Multimodal", ("multimodal", "vision-language", "vision language", "image-text", "video-language")),
        ("Reasoning", ("reasoning", "reason", "chain-of-thought", "inference")),
        ("NLP", ("language model", "language", "text", "nlp", "llm")),
        ("Robotics", ("robot", "embodied", "manipulation", "navigation", "vla")),
        ("Computer Vision", ("vision", "image", "video", "visual")),
        ("Benchmark", ("benchmark", "evaluation", "dataset")),
        ("Generative AI", ("generation", "generative", "diffusion")),
        ("Machine Learning", ("learning", "training", "representation")),
    ]
    selected = [label for label, terms in rules if any(term in haystack for term in terms)]
    category_map = {"cs.CL": "NLP", "cs.CV": "Computer Vision", "cs.RO": "Robotics", "cs.AI": "Machine Learning"}
    selected.extend(category_map[category] for category in categories if category in category_map)
    unique: list[str] = []
    for keyword in selected + ["Machine Learning", "AI", "Research"]:
        if keyword not in unique:
            unique.append(keyword)
        if len(unique) == 3:
            return unique
    return unique


def extract_figure(pdf_path: Path, output_path: Path) -> str:
    """Extract the first suitable overview figure from page one; render it as a fallback."""
    reader = PdfReader(str(pdf_path))
    choices: list[tuple[int, object]] = []
    # The first page holds the paper overview in the publications cards; this
    # also avoids scanning every asset in long benchmark appendices.
    for page in reader.pages[:1]:
        for image in page.images:
            try:
                width, height = image.image.size
                # Avoid publisher/project logos; a publication-card figure should
                # be a reasonably balanced image rather than a banner.
                if width >= 240 and height >= 160 and 0.55 <= width / height <= 3:
                    choices.append((width * height, image))
            except Exception:
                continue
    output_path.parent.mkdir(parents=True, exist_ok=True)
    if choices:
        _, image = choices[0]
        image.image.convert("RGB").save(output_path, "PNG", optimize=True)
        return "first-page embedded overview figure"

    renderer = shutil.which("pdftoppm")
    if not renderer:
        raise RuntimeError("No embedded raster figure found and pdftoppm is unavailable.")
    prefix = output_path.with_suffix("")
    subprocess.run(
        [renderer, "-f", "1", "-l", "1", "-png", "-r", "150", str(pdf_path), str(prefix)],
        check=True,
        capture_output=True,
        text=True,
    )
    rendered = prefix.parent / f"{prefix.name}-1.png"
    if not rendered.exists():
        raise RuntimeError("pdftoppm did not produce a preview image.")
    rendered.replace(output_path)
    return "first-page fallback; replace with a paper figure before publishing"


def next_publication_path(year: int, title: str) -> Path:
    numbers = []
    for path in PUBLICATIONS_DIR.glob(f"{year}-*.md"):
        match = re.match(rf"{year}-(\d+)-", path.name)
        if match:
            numbers.append(int(match.group(1)))
    number = max(numbers, default=0) + 1
    return PUBLICATIONS_DIR / f"{year}-{number:02d}-{safe_stem(title)}.md"


def write_draft(paper: ArxivPaper, figure_path: Path, figure_note: str, keywords: list[str]) -> Path:
    destination = next_publication_path(paper.published.year, paper.title)
    lines = [
        "---",
        "layout: publications",
        "section-type: publications",
        f"name: {yaml_string(paper.title)}",
        f"year: {paper.published.year}",
        "",
        "author:",
        *[f"  - name: {yaml_string(author)}" for author in paper.authors],
        "",
        "corresponding_author:",
        f"  - name: {yaml_string(TARGET_NAME)}",
        "",
        "external:",
        "  - title: arXiv",
        f"    url: {paper.abs_url}",
        "",
        f"img: {figure_path.name}",
        "",
        "keywords:",
        *[f"  - name: {yaml_string(keyword)}" for keyword in keywords],
        "",
        "display: False",
        "---",
        "",
    ]
    destination.write_text("\n".join(lines), encoding="utf-8")
    print(f"Created draft: {destination.relative_to(ROOT)}")
    print("  Conference/journal intentionally blank. Add it manually after acceptance.")
    print(f"  Figure source: {figure_note}")
    return destination


def replace_front_matter_section(lines: list[str], key: str, value: list[str]) -> list[str]:
    start = next((index for index, line in enumerate(lines) if line.startswith(f"{key}:")), None)
    if start is None:
        insert_at = next((index for index, line in enumerate(lines) if line.startswith("display:")), len(lines))
        return lines[:insert_at] + value + [""] + lines[insert_at:]
    end = start + 1
    while end < len(lines) and (lines[end].startswith("  ") or not lines[end].strip()):
        end += 1
    return lines[:start] + value + lines[end:]


def update_existing_draft(
    destination: Path,
    paper: ArxivPaper,
    figure_path: Path,
    figure_note: str,
    keywords: list[str],
    corresponding_confirmed: bool,
) -> Path:
    text = destination.read_text(encoding="utf-8")
    parts = text.split("---", 2)
    if len(parts) != 3 or parts[0].strip():
        raise RuntimeError(f"Unexpected front matter in {destination}")
    lines = parts[1].strip("\n").splitlines()
    lines = replace_front_matter_section(lines, "external", ["external:", "  - title: arXiv", f"    url: {paper.abs_url}"])
    lines = replace_front_matter_section(lines, "img", [f"img: {figure_path.name}"])
    lines = replace_front_matter_section(lines, "keywords", ["keywords:", *[f"  - name: {yaml_string(keyword)}" for keyword in keywords]])
    if corresponding_confirmed:
        lines = replace_front_matter_section(lines, "corresponding_author", ["corresponding_author:", f"  - name: {yaml_string(TARGET_NAME)}"])
    destination.write_text("---\n" + "\n".join(lines).rstrip() + "\n---" + parts[2], encoding="utf-8")
    print(f"Updated existing draft: {destination.relative_to(ROOT)}")
    print(f"  Figure source: {figure_note}")
    return destination


def inspect(paper: ArxivPaper, temp_dir: Path) -> dict[str, object]:
    pdf_path = temp_dir / f"{paper.paper_id}.pdf"
    pdf_path.write_bytes(fetch(ARXIV_PDF.format(paper_id=paper.paper_id)))
    first_pages, _ = pdf_text(pdf_path)
    confirmed, evidence = correspondence_evidence(first_pages)
    return {
        "paper": paper,
        "pdf_path": pdf_path,
        "corresponding_confirmed": confirmed,
        "correspondence_evidence": evidence,
        "keywords": choose_keywords(paper.title, paper.abstract, paper.categories),
    }


def print_candidate(result: dict[str, object], known: bool) -> None:
    paper: ArxivPaper = result["paper"]  # type: ignore[assignment]
    status = "ALREADY REGISTERED" if known else ("CORRESPONDING CONFIRMED" if result["corresponding_confirmed"] else "REVIEW REQUIRED")
    print(f"\n[{status}] {paper.title}")
    print(f"  arXiv: {paper.abs_url}")
    print(f"  Published: {paper.published.isoformat()}")
    print(f"  Authors (arXiv): {', '.join(paper.authors)}")
    print(f"  Keywords: {', '.join(result['keywords'])}")
    for evidence in result["correspondence_evidence"]:  # type: ignore[union-attr]
        print(f"  PDF evidence: {evidence}")
    if not result["corresponding_confirmed"]:
        print("  No positive Youngjae-Yu correspondence evidence in the PDF's first pages; new drafts require review.")


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Discover Youngjae Yu's corresponding-author arXiv papers and create reviewable PI Lab drafts."
    )
    parser.add_argument("--limit", type=int, default=50, help="Maximum arXiv records to inspect (default: 50).")
    parser.add_argument("--arxiv-id", action="append", default=[], help="Explicit arXiv id to apply after review; may be repeated.")
    parser.add_argument("--apply", action="store_true", help="Create display: False drafts and figure assets for approved ids.")
    parser.add_argument("--since-days", type=int, help="Only report entries published within this many days.")
    args = parser.parse_args()

    if args.apply and not args.arxiv_id:
        parser.error("--apply requires one or more explicit --arxiv-id values after reviewing the PDF evidence.")
    if args.limit < 1:
        parser.error("--limit must be positive.")

    try:
        papers = fetch_papers(args.limit)
    except Exception as error:
        print(f"arXiv query failed: {error}", file=sys.stderr)
        return 1

    cutoff = dt.date.today() - dt.timedelta(days=args.since_days) if args.since_days else None
    existing = existing_publications()
    requested = {re.sub(r"v\d+$", "", value) for value in args.arxiv_id}
    if requested:
        papers = [paper for paper in papers if paper.paper_id in requested]
        missing = requested - {paper.paper_id for paper in papers}
        if missing:
            print(f"Requested arXiv ids were not found for {TARGET_NAME}: {', '.join(sorted(missing))}", file=sys.stderr)
            return 1
    elif cutoff:
        papers = [paper for paper in papers if paper.published >= cutoff]

    if not papers:
        print("No matching arXiv entries found.")
        return 0

    with tempfile.TemporaryDirectory(prefix="snupi-arxiv-") as temp:
        temp_dir = Path(temp)
        results: list[dict[str, object]] = []
        for paper in papers:
            try:
                result = inspect(paper, temp_dir)
            except Exception as error:
                print(f"\n[PDF CHECK FAILED] {paper.title}\n  {error}", file=sys.stderr)
                continue
            results.append(result)
            is_known = paper.paper_id in existing or f"title:{normalized(paper.title)}" in existing
            print_candidate(result, is_known)

        if not args.apply:
            print("\nReview the PDF evidence, then create a draft with:")
            print("  ./scripts/create_publication.sh --arxiv --apply --arxiv-id <arXiv-id>")
            print("Drafts are display: False and intentionally omit conference/journal.")
            return 0

        for result in results:
            paper: ArxivPaper = result["paper"]  # type: ignore[assignment]
            if paper.paper_id not in requested:
                continue
            destination = existing.get(paper.paper_id) or existing.get(f"title:{normalized(paper.title)}")
            if not destination and not result["corresponding_confirmed"]:
                print(f"Refusing to create {paper.paper_id}: PDF correspondence evidence is not positive.", file=sys.stderr)
                continue
            figure_name = f"arxiv-{paper.paper_id.replace('/', '-')}-{safe_stem(paper.title, 46)}.png"
            figure_path = PAPERS_DIR / figure_name
            try:
                figure_note = extract_figure(result["pdf_path"], figure_path)  # type: ignore[arg-type]
                if destination:
                    update_existing_draft(
                        destination, paper, figure_path, figure_note, result["keywords"], result["corresponding_confirmed"]  # type: ignore[arg-type]
                    )
                else:
                    write_draft(paper, figure_path, figure_note, result["keywords"])  # type: ignore[arg-type]
            except Exception as error:
                figure_path.unlink(missing_ok=True)
                print(f"Could not create draft for {paper.paper_id}: {error}", file=sys.stderr)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
