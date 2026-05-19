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
echo "  2) Ph.D./MS Student"
echo "  3) MS Student"
echo "  4) Ph.D. Student(IAR)"
echo "  5) MS Student(IAR)"
echo "  6) Visiting Scholar"
echo "  7) Alumni"
echo "  8) Intern"
echo "  9) Collaborator"
echo "  10) Postdoctoral Researcher"
read -r position_choice

case $position_choice in
    1) position="Ph.D. Student"; prefix="01";;
    2) position="Ph.D./MS Student"; prefix="02";;
    3) position="MS Student"; prefix="03";;
    4) position="Ph.D. Student(IAR)"; prefix="04";;
    5) position="MS Student(IAR)"; prefix="05";;
    6) position="Visiting Scholar"; prefix="06";;
    7) position="Alumni"; prefix="07";;
    8) position="Intern"; prefix="08";;
    9) position="Collaborator"; prefix="09";;
    10) position="Postdoctoral Researcher"; prefix="01";;
    *) echo "잘못된 선택입니다."; exit 1;;
esac

# 필수 필드: email
echo -e "${GREEN}[필수]${NC} Email을 입력하세요:"
read -r email

# 선택 필드: fields (쉼표로 구분)
echo -e "${YELLOW}[선택]${NC} Fields를 입력하세요 (쉼표로 구분, 예: NLP, Psychology, Multi-agent Problem, Enter로 건너뛰기):"
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

# 선택 필드: affiliation
if [ -n "$works" ]; then
    echo -e "${YELLOW}[선택]${NC} Works 로고 설명을 선택하세요:"
    echo "  1) Internship at"
    echo "  2) Visiting Scholar at"
    echo "  3) Affiliated with"
    echo "  4) 직접 입력"
    echo "  Enter) 건너뛰기"
    read -r affiliation_choice

    case $affiliation_choice in
        1) affiliation_label="Internship at"; default_logo_width="120px";;
        2) affiliation_label="Visiting Scholar at"; default_logo_width="80px";;
        3) affiliation_label="Affiliated with"; default_logo_width="80px";;
        4)
            echo "표시할 문구를 입력하세요 (예: Internship at):"
            read -r affiliation_label
            default_logo_width="80px"
            ;;
        *) affiliation_label="";;
    esac

    if [ -n "$affiliation_label" ]; then
        echo "로고 alt 텍스트를 입력하세요 (예: LG AI Research):"
        read -r affiliation_logo_alt
        echo "로고 너비를 입력하세요 (기본값: $default_logo_width):"
        read -r affiliation_logo_width
        if [ -z "$affiliation_logo_width" ]; then
            affiliation_logo_width="$default_logo_width"
        fi
        if [[ "$affiliation_logo_width" =~ ^[0-9]+$ ]]; then
            affiliation_logo_width="${affiliation_logo_width}px"
        fi
    fi
fi

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

duplicate_file=$(rg -l "^permalink:[[:space:]]*$permalink[[:space:]]*$" "$PEOPLE_DIR" 2>/dev/null | head -1 || true)
if [ -n "$duplicate_file" ]; then
    echo -e "${RED}이미 같은 permalink를 가진 파일이 있습니다: $duplicate_file${NC}"
    echo "동명이인이거나 기존 인물을 수정하는 경우 permalink를 먼저 정리해 주세요: $permalink"
    exit 1
fi

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
    echo "emoji: \"$emoji\"" >> "$filename"
fi

cat >> "$filename" << EOF
position: "$position"
permalink: $permalink
email: $email

EOF

# works 추가 (있으면)
if [ -n "$works" ]; then
    echo "works: $works" >> "$filename"
    if [ -n "$affiliation_label" ]; then
        cat >> "$filename" << EOF
affiliation:
  label: $affiliation_label
  logo_alt: $affiliation_logo_alt
  logo_width: $affiliation_logo_width
EOF
    fi
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
if [ -n "$fields_input" ]; then
    IFS=',' read -ra FIELDS <<< "$fields_input"
    for field in "${FIELDS[@]}"; do
        # trim whitespace
        field=$(echo "$field" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
        if [ -n "$field" ]; then
            echo "    - name : $field" >> "$filename"
        fi
    done
fi

# publications 필드 (비워두기)
cat >> "$filename" << EOF

publications:

---

EOF

echo ""
echo -e "${GREEN}✓ 파일이 생성되었습니다: $filename${NC}"
echo ""
