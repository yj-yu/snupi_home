#!/bin/bash

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"

cd "$PROJECT_ROOT" || exit 1

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}   Latest Work 슬라이드 업데이트${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

ruby - "$PROJECT_ROOT" "$@" <<'RUBY'
require "json"
require "yaml"

root = ARGV.shift
Dir.chdir(root)

dry_run = ARGV.delete("--dry-run")

def natural_key(path)
  File.basename(path).scan(/\d+|\D+/).map { |part| part.match?(/\A\d+\z/) ? part.to_i : part }
end

def front_matter(path)
  text = File.read(path)
  raw = text[/\A---\s*\n(.*?)\n---/m, 1]
  data = raw ? YAML.safe_load(raw, aliases: true) : {}
  data || {}
rescue Psych::SyntaxError => e
  warn "YAML parse warning: #{path}: #{e.message}"
  {}
end

def author_names(data)
  authors = Array(data["author"]).map { |entry| entry.is_a?(Hash) ? entry["name"] : entry }.compact
  equal_indices = Array(data["equal_contributor_idx"]).map(&:to_i)
  authors = authors.each_with_index.map { |name, idx| equal_indices.include?(idx) ? "#{name}*" : name }

  return "" if authors.empty?
  return authors.first if authors.length == 1

  "#{authors[0...-1].join(", ")} and #{authors[-1]}"
end

def external_url(data)
  external = Array(data["external"])
  arxiv = external.find { |item| item.is_a?(Hash) && item["title"].to_s.downcase.include?("arxiv") }
  selected = arxiv || external.find { |item| item.is_a?(Hash) && item["url"] }
  selected && selected["url"]
end

def image_path(data)
  value = data["slide_img"] || data["slide_image"] || data["img"]
  return "images/papers/coming_soon.png" if value.to_s.strip.empty?

  value = value.to_s.strip
  return value if value.start_with?("images/", "/", "http://", "https://")

  slides_path = File.join("images", "slides", value)
  papers_path = File.join("images", "papers", value)

  return slides_path if File.exist?(slides_path)
  return papers_path if File.exist?(papers_path)

  papers_path
end

def js(value)
  JSON.generate(value.to_s)
end

entries = Dir.glob("_publications/*.md").sort_by { |path| natural_key(path) }.map do |path|
  data = front_matter(path)
  name = data["name"].to_s.strip
  next if name.empty?

  { path: path, data: data, name: name }
end.compact

puts "\e[0;32m현재 등록된 논문 목록:\e[0m"
puts ""
entries.each_with_index do |entry, idx|
  data = entry[:data]
  year = data["year"] || "????"
  conference = data["conference"].to_s.strip
  suffix = conference.empty? ? "" : " / #{conference}"
  puts "  #{idx + 1}) [#{year}] #{entry[:name]}#{suffix}"
end

selection_text = ARGV.join(" ").strip
if selection_text.empty?
  puts ""
  puts "\e[1;33m슬라이드에 넣을 논문 번호를 순서대로 입력하세요. 예: 104,102,99\e[0m"
  selection_text = STDIN.gets.to_s.strip
end

indices = selection_text.scan(/\d+/).map(&:to_i)
if indices.empty?
  warn "\e[0;31m논문 번호가 입력되지 않았습니다.\e[0m"
  exit 1
end

selected = indices.map do |idx|
  entry = entries[idx - 1]
  unless entry
    warn "\e[0;31m존재하지 않는 번호입니다: #{idx}\e[0m"
    exit 1
  end
  entry
end

slides = selected.map do |entry|
  data = entry[:data]
  {
    "conference" => data["conference"].to_s.strip,
    "title" => data["name"].to_s.strip,
    "authors" => author_names(data),
    "bgImage" => image_path(data),
    "url" => external_url(data).to_s.strip
  }
end

slide_objects = slides.map do |slide|
lines = [
    "        {",
    "          conference: #{js(slide["conference"])},",
    "          title: #{js(slide["title"])},",
    "          authors: #{js(slide["authors"])},",
    "          bgImage: #{js(slide["bgImage"])}"
  ]
  unless slide["url"].empty?
    lines[-1] = "#{lines[-1]},"
    lines << "          url: #{js(slide["url"])}"
  end
  lines << "        }"
  lines.join("\n")
end.join(",\n")

slide_html = File.read("slide.html")
start_marker = "        // SLIDE_DATA_START\n"
end_marker = "        // SLIDE_DATA_END\n"

unless slide_html.include?(start_marker) && slide_html.include?(end_marker)
  warn "\e[0;31mslide.html에서 SLIDE_DATA_START/END 마커를 찾을 수 없습니다.\e[0m"
  exit 1
end

updated = slide_html.sub(
  /#{Regexp.escape(start_marker)}.*?#{Regexp.escape(end_marker)}/m,
  "#{start_marker}#{slide_objects}\n#{end_marker}"
)

File.write("slide.html", updated) unless dry_run

puts ""
if dry_run
  puts "\e[1;33m--dry-run: slide.html은 수정하지 않고 미리보기만 표시합니다.\e[0m"
else
  puts "\e[0;32m✓ slide.html Latest Work 슬라이드가 업데이트되었습니다.\e[0m"
end
puts ""
slides.each_with_index do |slide, idx|
  puts "  #{idx + 1}) #{slide["conference"]} - #{slide["title"]}"
end
RUBY
