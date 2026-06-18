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

PUBLICATIONS_DIR="_publications"

upsert_front_matter_scalar() {
    local file="$1"
    local key="$2"
    local value="$3"
    local quote="$4"

    ruby - "$file" "$key" "$value" "$quote" <<'RUBY'
file, key, value, quote = ARGV
order = %w[
  layout section-type name conference year author equal_contributor_idx
  corresponding_author external img keywords display
]

lines = File.readlines(file, chomp: true)
front_start = lines.index("---")
front_end = nil
if front_start
  ((front_start + 1)...lines.length).each do |idx|
    if lines[idx] == "---"
      front_end = idx
      break
    end
  end
end
front_start ||= 0
front_end ||= lines.length

formatted_value = quote == "quote" ? value.dump : value
new_line = "#{key}: #{formatted_value}"
replaced = false

((front_start + 1)...front_end).each do |idx|
  if lines[idx] =~ /^#{Regexp.escape(key)}:/
    lines[idx] = new_line
    replaced = true
    break
  end
end

unless replaced
  target_order = order.index(key) || order.length
  insert_at = front_end
  ((front_start + 1)...front_end).each do |idx|
    next unless lines[idx] =~ /^([A-Za-z0-9_-]+):/
    current_order = order.index($1)
    next unless current_order && current_order > target_order
    insert_at = idx
    break
  end
  lines.insert(insert_at, new_line)
end

File.write(file, lines.join("\n") + "\n")
RUBY
}

replace_front_matter_section() {
    local file="$1"
    local key="$2"
    local content="$3"

    ruby - "$file" "$key" "$content" <<'RUBY'
file, key, content = ARGV
order = %w[
  layout section-type name conference year author equal_contributor_idx
  corresponding_author external img keywords display
]

lines = File.readlines(file, chomp: true)
front_start = lines.index("---")
front_end = nil
if front_start
  ((front_start + 1)...lines.length).each do |idx|
    if lines[idx] == "---"
      front_end = idx
      break
    end
  end
end
front_start ||= 0
front_end ||= lines.length

section_start = nil
section_end = nil
((front_start + 1)...front_end).each do |idx|
  next unless lines[idx] =~ /^#{Regexp.escape(key)}:/
  section_start = idx
  section_end = front_end
  ((idx + 1)...front_end).each do |j|
    if lines[j] =~ /^[A-Za-z0-9_-]+:/
      section_end = j
      break
    end
  end
  break
end

new_lines = content.split("\n", -1)
new_lines.pop while new_lines.last == ""

if section_start
  lines[section_start...section_end] = new_lines
else
  target_order = order.index(key) || order.length
  insert_at = front_end
  ((front_start + 1)...front_end).each do |idx|
    next unless lines[idx] =~ /^([A-Za-z0-9_-]+):/
    current_order = order.index($1)
    next unless current_order && current_order > target_order
    insert_at = idx
    break
  end
  lines.insert(insert_at, *new_lines)
end

File.write(file, lines.join("\n") + "\n")
RUBY
}

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}   논문 정보 수정하기${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# 모든 논문 리스트 출력 (최신순으로)
echo -e "${GREEN}현재 등록된 논문 목록:${NC}"
echo ""

declare -a names
declare -a filenames
index=1

# 파일명에 공백이 있어도 안전하게 처리 (오래된 순 정렬)
while IFS= read -r -d '' file; do
    if [ -f "$file" ]; then
        # name 추출
        pub_name=$(grep "^name:" "$file" | sed 's/name: "\(.*\)"/\1/')
        if [ -n "$pub_name" ]; then
            year=$(grep "^year:" "$file" | sed 's/year: //')
            echo "  $index) [$year] $pub_name"
            names[$index]="$pub_name"
            filenames[$index]="$file"
            ((index++))
        fi
    fi
done < <(find "$PUBLICATIONS_DIR" -maxdepth 1 -name "*.md" -type f -print0 | sort -zV)

echo ""
echo -e "${YELLOW}수정할 논문의 번호를 입력하세요:${NC}"
read -r selection

selected_file="${filenames[$selection]}"
selected_name="${names[$selection]}"

if [ -z "$selected_file" ] || [ ! -f "$selected_file" ]; then
    echo -e "${RED}해당하는 논문을 찾을 수 없습니다.${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}선택된 논문: $selected_name${NC}"
echo -e "${GREEN}파일: $selected_file${NC}"
echo ""

# 현재 필드 정보 출력
echo -e "${BLUE}현재 정보:${NC}"
echo "----------------------------------------"
cat "$selected_file"
echo "----------------------------------------"
echo ""

# 수정할 필드 선택
echo -e "${YELLOW}수정할 필드를 선택하세요:${NC}"
echo "  1) name (논문 제목)"
echo "  2) year (연도)"
echo "  3) conference (학회/저널)"
echo "  4) authors (저자 목록)"
echo "  5) img (이미지)"
echo "  6) url (Arxiv URL)"
echo "  7) keywords"
echo "  8) equal_contributor_idx"
echo "  0) 전체 다시 작성 (에디터로 열기)"
read -r field_choice

case $field_choice in
    1)
        echo "새로운 논문 제목을 입력하세요:"
        read -r new_value
        upsert_front_matter_scalar "$selected_file" "name" "$new_value" "quote"
        ;;
    2)
        echo "새로운 연도를 입력하세요:"
        read -r new_value
        upsert_front_matter_scalar "$selected_file" "year" "$new_value" "raw"
        ;;
    3)
        echo "새로운 학회/저널명을 입력하세요:"
        read -r new_value
        upsert_front_matter_scalar "$selected_file" "conference" "$new_value" "raw"
        ;;
    4)
        echo "새로운 저자 목록을 입력하세요 (쉼표로 구분):"
        read -r new_authors
        temp_authors="author:"
        IFS=',' read -ra AUTHORS <<< "$new_authors"
        for author in "${AUTHORS[@]}"; do
            author=$(echo "$author" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
            temp_authors="${temp_authors}
  - name: \"$author\""
        done
        replace_front_matter_section "$selected_file" "author" "$temp_authors"
        ;;
    5)
        echo "새로운 이미지 경로를 입력하세요:"
        read -r new_value
        upsert_front_matter_scalar "$selected_file" "img" "$new_value" "raw"
        ;;
    6)
        echo "새로운 Arxiv URL을 입력하세요:"
        read -r new_value
        temp_external="external:
  - title: Arxiv
    url: $new_value"
        replace_front_matter_section "$selected_file" "external" "$temp_external"
        ;;
    7)
        echo "새로운 Keywords를 입력하세요 (쉼표로 구분):"
        read -r new_keywords
        temp_keywords="keywords:"
        IFS=',' read -ra KEYWORDS <<< "$new_keywords"
        for keyword in "${KEYWORDS[@]}"; do
            keyword=$(echo "$keyword" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
            if [ -n "$keyword" ]; then
                temp_keywords="${temp_keywords}
  - name: $keyword"
            fi
        done
        replace_front_matter_section "$selected_file" "keywords" "$temp_keywords"
        ;;
    8)
        echo "새로운 Equal contributor indices를 입력하세요 (쉼표로 구분, 예: 0,1):"
        read -r new_idx
        if [ -n "$new_idx" ]; then
            temp_idx="equal_contributor_idx:"
            IFS=',' read -ra INDICES <<< "$new_idx"
            for idx in "${INDICES[@]}"; do
                idx=$(echo "$idx" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
                temp_idx="${temp_idx}
  - $idx"
            done
            replace_front_matter_section "$selected_file" "equal_contributor_idx" "$temp_idx"
        else
            replace_front_matter_section "$selected_file" "equal_contributor_idx" "equal_contributor_idx:"
        fi
        ;;
    0)
        echo "파일을 에디터로 엽니다..."
        ${EDITOR:-nano} "$selected_file"
        ;;
    *)
        echo "잘못된 선택입니다."
        exit 1
        ;;
esac

echo ""
echo -e "${GREEN}✓ 수정이 완료되었습니다!${NC}"
echo ""
echo -e "${BLUE}수정된 내용:${NC}"
echo "----------------------------------------"
cat "$selected_file"
echo "----------------------------------------"
