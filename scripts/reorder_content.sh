#!/bin/bash

# 색상 정의
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# 스크립트 디렉토리 찾기
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# 프로젝트 루트로 이동 (scripts의 상위 디렉토리)
PROJECT_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"
cd "$PROJECT_ROOT"

if [ -n "$1" ]; then
  case "$1" in
    gallery|people|funding|publications) target="$1";;
    publication) target="publications";;
    person) target="people";;
    *) echo -e "${RED}잘못된 대상입니다: $1${NC}"; exit 1;;
  esac
else
  echo -e "${BLUE}========================================${NC}"
  echo -e "${BLUE}   콘텐츠 순서 변경하기${NC}"
  echo -e "${BLUE}========================================${NC}"
  echo ""
  echo -e "${GREEN}[필수]${NC} 순서를 바꿀 콘텐츠를 선택하세요:"
  echo "  1) Gallery"
  echo "  2) People"
  echo "  3) Funding"
  echo "  4) Publications"
  read -r content_choice

  case "$content_choice" in
    1) target="gallery";;
    2) target="people";;
    3) target="funding";;
    4) target="publications";;
    *) echo -e "${RED}잘못된 선택입니다.${NC}"; exit 1;;
  esac
fi

ruby_script=$(mktemp)
cat > "$ruby_script" <<'RUBY'
target = ARGV.fetch(0)

def frontmatter(path)
  text = File.read(path)
  block = text[/\A---\n(.*?)\n---/m, 1] || ""
  data = {}
  block.each_line do |line|
    next unless line =~ /\A([A-Za-z0-9_-]+):\s*(.*)\z/
    key = Regexp.last_match(1)
    value = Regexp.last_match(2).strip
    value = value[1..-2] if value.start_with?('"') && value.end_with?('"')
    data[key] = value
  end
  data
end

def natural_key(path)
  File.basename(path).scan(/\d+|\D+/).map { |part| part =~ /\A\d+\z/ ? part.to_i : part.downcase }
end

def choose(prompt, min:, max:)
  print prompt
  input = STDIN.gets&.strip
  unless input&.match?(/\A\d+\z/)
    abort "숫자를 입력해야 합니다."
  end
  value = input.to_i
  unless value.between?(min, max)
    abort "범위를 벗어났습니다."
  end
  value
end

def reorder_array(items, from_index, to_index)
  item = items.delete_at(from_index)
  items.insert(to_index, item)
  items
end

def path_parts(path)
  base = File.basename(path, ".md")
  parts = base.split("-", 3)
  abort "파일명 형식을 읽을 수 없습니다: #{path}" if parts.size < 3
  parts
end

def rename_with_order(files, display_order, reverse:)
  keys = files.map { |path| path_parts(path)[0, 2] }
  assigned_keys = reverse ? keys.sort.reverse : keys.sort
  width_a = keys.map { |key| key[0].length }.max || 2
  width_b = keys.map { |key| key[1].length }.max || 2

  temp_paths = {}
  display_order.each do |path|
    temp = "#{path}.reorder_tmp_#{$$}"
    File.rename(path, temp)
    temp_paths[path] = temp
  end

  display_order.each_with_index do |old_path, index|
    key_a, key_b = assigned_keys[index]
    _old_a, _old_b, slug = path_parts(old_path)
    new_base = "#{key_a.to_i.to_s.rjust(width_a, "0")}-#{key_b.to_i.to_s.rjust(width_b, "0")}-#{slug}.md"
    new_path = File.join(File.dirname(old_path), new_base)
    File.rename(temp_paths.fetch(old_path), new_path)
  end
end

def reorder_file_collection(label:, dir:, reverse:, group_label:, group_proc:, title_proc:)
  files = Dir.glob(File.join(dir, "*.md")).sort_by { |path| natural_key(path) }
  groups = files.group_by { |path| group_proc.call(path) }.sort_by { |group, _| group.to_s }.reverse
  abort "#{label} 파일이 없습니다." if groups.empty?

  puts
  puts "#{label} 그룹을 선택하세요:"
  groups.each_with_index do |(group, items), index|
    puts "  #{index + 1}) #{group_label}: #{group} (#{items.size}개)"
  end
  group_index = choose("번호: ", min: 1, max: groups.size) - 1
  selected_group, group_files = groups[group_index]

  display_order = reverse ? group_files.sort_by { |path| natural_key(path) }.reverse : group_files.sort_by { |path| natural_key(path) }
  abort "해당 그룹에 항목이 없습니다." if display_order.empty?

  puts
  puts "현재 화면 순서 [#{selected_group}]:"
  display_order.each_with_index do |path, index|
    puts "  #{index + 1}) #{title_proc.call(path)}"
  end

  from = choose("옮길 항목 번호: ", min: 1, max: display_order.size) - 1
  to = choose("새 위치 번호 (1이 맨 위): ", min: 1, max: display_order.size) - 1

  if from == to
    puts "순서가 바뀌지 않았습니다."
    return
  end

  new_display_order = reorder_array(display_order.dup, from, to)
  rename_with_order(group_files, new_display_order, reverse: reverse)

  puts
  puts "✓ #{label} 순서가 변경되었습니다."
end

def reorder_gallery
  reorder_file_collection(
    label: "Gallery",
    dir: "_gallery",
    reverse: true,
    group_label: "year",
    group_proc: ->(path) { frontmatter(path)["year"] || path_parts(path)[0] },
    title_proc: ->(path) {
      data = frontmatter(path)
      "[#{data["year"] || path_parts(path)[0]}] #{data["title"] || File.basename(path)}"
    }
  )
end

def people_section(member)
  position = member["position"].to_s
  remarks = member["remarks"].to_s
  return "Professor" if position.include?("Professor")
  return "Postdoctoral Researcher" if position.include?("Postdoctoral Researcher")
  return "Industry-Affiliated Student" if remarks == "Industry-Affiliated Student"
  return "Student" if position.include?("Student")
  return "Visiting Scholar" if position.include?("Visiting Scholar")
  return "Lab Robot" if position.include?("Lab Robot")
  return "Administrative Staff" if position.include?("Administrative Staff")
  return "Collaborator" if position.include?("Collaborator")
  return "Intern" if position.include?("Intern")
  return "Alumni" if position.include?("Alumni")
  "Other"
end

def reorder_people
  reorder_file_collection(
    label: "People",
    dir: "_people",
    reverse: false,
    group_label: "section",
    group_proc: ->(path) { people_section(frontmatter(path)) },
    title_proc: ->(path) {
      data = frontmatter(path)
      "#{data["fullname"] || File.basename(path)} (#{data["position"]})"
    }
  )
end

def reorder_publications
  reorder_file_collection(
    label: "Publications",
    dir: "_publications",
    reverse: true,
    group_label: "year",
    group_proc: ->(path) { frontmatter(path)["year"] || path_parts(path)[0] },
    title_proc: ->(path) {
      data = frontmatter(path)
      "[#{data["year"] || path_parts(path)[0]}] #{data["name"] || File.basename(path)}"
    }
  )
end

def article_title(article)
  article[/<h3 class="funding-name">(.*?)<\/h3>/m, 1]&.gsub(/\s+/, " ")&.strip || "(제목 없음)"
end

def reorder_funding
  file = "funding.html"
  html = File.read(file)
  sections = [
    ["Grants", /(        <div class="funding-grid grants-grid">\n)(.*?)(\n        <\/div>\n      <\/section>)/m],
    ["Industry Collaboration", /(        <div class="funding-grid two-column">\n)(.*?)(\n        <\/div>\n      <\/section>)/m]
  ]

  puts
  puts "Funding 섹션을 선택하세요:"
  sections.each_with_index { |(name, _), index| puts "  #{index + 1}) #{name}" }
  section_index = choose("번호: ", min: 1, max: sections.size) - 1
  section_name, pattern = sections[section_index]

  match = html.match(pattern)
  abort "funding.html에서 #{section_name} 섹션을 찾지 못했습니다." unless match

  prefix, body, suffix = match.captures
  articles = body.scan(/          <article class="funding-card">.*?          <\/article>/m)
  abort "#{section_name} 항목이 없습니다." if articles.empty?

  puts
  puts "현재 화면 순서 [#{section_name}]:"
  articles.each_with_index do |article, index|
    puts "  #{index + 1}) #{article_title(article)}"
  end

  from = choose("옮길 항목 번호: ", min: 1, max: articles.size) - 1
  to = choose("새 위치 번호 (1이 맨 위): ", min: 1, max: articles.size) - 1

  if from == to
    puts "순서가 바뀌지 않았습니다."
    return
  end

  reordered = reorder_array(articles.dup, from, to).join("\n\n")
  html.sub!(pattern, "#{prefix}#{reordered}#{suffix}")
  File.write(file, html)

  puts
  puts "✓ Funding 순서가 변경되었습니다."
end

case target
when "gallery" then reorder_gallery
when "people" then reorder_people
when "funding" then reorder_funding
when "publications" then reorder_publications
else abort "알 수 없는 대상입니다."
end
RUBY

ruby "$ruby_script" "$target"
status=$?
rm -f "$ruby_script"
exit $status
