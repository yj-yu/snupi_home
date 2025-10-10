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

PUBLICATIONS_DIR="_publications"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}   새로운 논문 추가하기${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# 필수 필드: name
echo -e "${GREEN}[필수]${NC} 논문 제목을 입력하세요:"
read -r name

# 필수 필드: year
echo -e "${GREEN}[필수]${NC} 연도를 입력하세요 (예: 2025):"
read -r year

# 필수 필드: authors (쉼표로 구분)
echo -e "${GREEN}[필수]${NC} 저자들을 입력하세요 (쉼표로 구분, 예: Jiwan Chung, Junhyeok Kim, Youngjae Yu):"
read -r authors_input

# 필수 필드: img
echo -e "${GREEN}[필수]${NC} 이미지 파일명을 입력하세요 (예: xxx.png):"
read -r img

# 필수 필드: keywords (쉼표로 구분)
echo -e "${GREEN}[필수]${NC} Keywords를 입력하세요 (쉼표로 구분, 예: Multimodal, Reasoning, NLP):"
read -r keywords_input

# 선택 필드: conference
echo -e "${YELLOW}[선택]${NC} 학회/저널명을 입력하세요 (선택사항, 예: CVPR2025, NeurIPS2025, Enter로 건너뛰기):"
read -r conference

# 선택 필드: url (external)
echo -e "${YELLOW}[선택]${NC} Arxiv URL을 입력하세요 (선택사항, 예: https://arxiv.org/abs/..., Enter로 건너뛰기):"
read -r url

# 선택 필드: equal_contributor_idx
echo -e "${YELLOW}[선택]${NC} Equal contributor indices를 입력하세요 (쉼표로 구분, 예: 0,1 - 선택사항, Enter로 건너뛰기):"
read -r equal_idx_input

# 파일명 생성 (마지막 파일의 번호를 찾아서 +1)
last_file=$(ls -1 "${PUBLICATIONS_DIR}/${year}-"* 2>/dev/null | tail -1)
if [ -z "$last_file" ]; then
    number="01"
else
    last_number=$(basename "$last_file" | sed "s/${year}-\([0-9]*\)-.*/\1/")
    number=$(printf "%02d" $((10#$last_number + 1)))
fi

# 파일명 생성 (title을 사용하되 특수문자 제거)
safe_title=$(echo "$name" | sed 's/[^a-zA-Z0-9 ]//g' | sed 's/  */ /g')
filename="${PUBLICATIONS_DIR}/${year}-${number}-${safe_title}.md"

# Markdown 파일 생성
cat > "$filename" << EOF
---
layout: publications
section-type: publications
name: "$name"
EOF

# conference 추가 (있으면)
if [ -n "$conference" ]; then
    echo "conference: $conference" >> "$filename"
fi

echo "year: $year" >> "$filename"
echo "" >> "$filename"

echo "author:" >> "$filename"

# authors 추가
IFS=',' read -ra AUTHORS <<< "$authors_input"
for author in "${AUTHORS[@]}"; do
    # trim whitespace
    author=$(echo "$author" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
    echo "  - name: \"$author\"" >> "$filename"
done

# 빈 줄 추가
echo "" >> "$filename"
echo "" >> "$filename"
echo "" >> "$filename"

# equal_contributor_idx 추가 (있으면)
if [ -n "$equal_idx_input" ]; then
    echo "equal_contributor_idx:" >> "$filename"
    IFS=',' read -ra INDICES <<< "$equal_idx_input"
    for idx in "${INDICES[@]}"; do
        # trim whitespace
        idx=$(echo "$idx" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
        echo "  - $idx" >> "$filename"
    done
    echo "" >> "$filename"
fi

# external 추가 (url이 있으면)
if [ -n "$url" ]; then
    cat >> "$filename" << EOF
external:
  - title: Arxiv
    url: $url
  

EOF
fi

echo "img: $img" >> "$filename"
echo "" >> "$filename"
echo "keywords:" >> "$filename"

# keywords 추가
IFS=',' read -ra KEYWORDS <<< "$keywords_input"
for keyword in "${KEYWORDS[@]}"; do
    # trim whitespace
    keyword=$(echo "$keyword" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
    echo "  - name: $keyword" >> "$filename"
done

# 마무리
cat >> "$filename" << EOF

display: False
---

EOF

echo ""
echo -e "${GREEN}✓ 파일이 생성되었습니다: $filename${NC}"
echo ""

