#!/bin/bash

# 색상 정의
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 스크립트 디렉토리 찾기
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# 프로젝트 루트로 이동 (scripts의 상위 디렉토리)
PROJECT_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"
cd "$PROJECT_ROOT"

PEOPLE_DIR="_people"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}   새로운 사람 추가하기${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# 필수 필드: fullname
echo -e "${GREEN}[필수]${NC} Full Name을 입력하세요 (예: Seungbeen Lee):"
read -r fullname

# permalink 자동 생성 (첫 단어를 소문자로)
first_name=$(echo "$fullname" | awk '{print tolower($1)}')
permalink="people/${first_name}.html"

# 필수 필드: img-filename
echo -e "${GREEN}[필수]${NC} 이미지 파일명을 입력하세요 (예: lee_seungbeen.jpg):"
read -r img_filename

# 필수 필드: position
echo -e "${GREEN}[필수]${NC} Position을 선택하세요:"
echo "  1) Ph.D. Student"
echo "  2) MS Student"
echo "  3) Visiting Scholar"
echo "  4) Alumni"
echo "  5) Intern"
echo "  6) Collaborator"
read -r position_choice

case $position_choice in
    1) position="Ph.D. Student"; prefix="01";;
    2) position="MS Student"; prefix="01";;
    3) position="Visiting Scholar"; prefix="02";;
    4) position="Alumni"; prefix="03";;
    5) position="Intern"; prefix="04";;
    6) position="Collaborator"; prefix="00";;
    *) echo "잘못된 선택입니다."; exit 1;;
esac

# 필수 필드: email
echo -e "${GREEN}[필수]${NC} Email을 입력하세요:"
read -r email

# 필수 필드: fields (쉼표로 구분)
echo -e "${GREEN}[필수]${NC} Fields를 입력하세요 (쉼표로 구분, 예: NLP, Psychology, Multi-agent Problem):"
read -r fields_input

# 선택 필드: emoji
echo -e "${YELLOW}[선택]${NC} Emoji를 입력하세요 (선택사항, Enter로 건너뛰기):"
read -r emoji

# 선택 필드: social (url만)
echo -e "${YELLOW}[선택]${NC} Personal website URL을 입력하세요 (선택사항, Enter로 건너뛰기):"
read -r social_url

# 선택 필드: works
echo -e "${YELLOW}[선택]${NC} Works 이미지 파일명을 입력하세요 (선택사항, 예: cmu.png, Enter로 건너뛰기):"
read -r works

# 파일명 생성 (마지막 파일의 번호를 찾아서 +1)
last_file=$(ls -1 "${PEOPLE_DIR}/${prefix}-"* 2>/dev/null | tail -1)
if [ -z "$last_file" ]; then
    number="01"
else
    last_number=$(basename "$last_file" | cut -d'-' -f2)
    number=$(printf "%02d" $((10#$last_number + 1)))
fi

# 파일명 생성 (fullname을 snake_case로 변환)
snake_name=$(echo "$fullname" | tr '[:upper:]' '[:lower:]' | tr ' ' '_')
filename="${PEOPLE_DIR}/${prefix}-${number}-${snake_name}.md"

# Markdown 파일 생성
cat > "$filename" << EOF
---
layout: people-detail
section-type: people
fullname: "$fullname"
img-filename: $img_filename
EOF

# emoji 추가 (있으면)
if [ -n "$emoji" ]; then
    echo "emoji: $emoji" >> "$filename"
fi

cat >> "$filename" << EOF
position: "$position"
permalink: $permalink
email: $email

EOF

# works 추가 (있으면)
if [ -n "$works" ]; then
    echo "works: $works" >> "$filename"
fi

# social 추가 (있으면)
if [ -n "$social_url" ]; then
    cat >> "$filename" << EOF
social:
  - title: home
    url: $social_url

EOF
fi

# fields 추가
echo "" >> "$filename"
echo "fields:" >> "$filename"
IFS=',' read -ra FIELDS <<< "$fields_input"
for field in "${FIELDS[@]}"; do
    # trim whitespace
    field=$(echo "$field" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
    echo "    - name : $field" >> "$filename"
done

# publications 필드 (비워두기)
cat >> "$filename" << EOF

publications:

---

EOF

echo ""
echo -e "${GREEN}✓ 파일이 생성되었습니다: $filename${NC}"
echo ""

