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

GALLERY_DIR="_gallery"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}   새로운 갤러리 추가하기${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# 필수 필드: year
echo -e "${GREEN}[필수]${NC} Year를 입력하세요 (예: 2025):"
read -r year

# 필수 필드: title
echo -e "${GREEN}[필수]${NC} Title을 입력하세요 (예: naacl):"
read -r title

# 필수 필드: img-filename
echo -e "${GREEN}[필수]${NC} 이미지 파일명을 입력하세요 (예: naacl_.jpg):"
read -r img_filename

# 필수 필드: description
echo -e "${GREEN}[필수]${NC} Description을 입력하세요 (예: NAACL 2025):"
read -r description

# 해당 연도의 마지막 파일 번호를 찾아서 +1
last_file=$(ls -1 "${GALLERY_DIR}/${year}-"* 2>/dev/null | tail -1)
if [ -z "$last_file" ]; then
    number="01"
else
    last_number=$(basename "$last_file" | cut -d'-' -f2)
    number=$(printf "%02d" $((10#$last_number + 1)))
fi

# 파일명 생성
filename="${GALLERY_DIR}/${year}-${number}-${title}.md"

# Markdown 파일 생성
cat > "$filename" << EOF
---
layout: people-detail
section-type: gallery
title: "$title"
description: $description
img-filename: $img_filename
year: $year
---
EOF

echo ""
echo -e "${GREEN}✓ 갤러리 파일이 생성되었습니다: $filename${NC}"
echo ""
echo -e "${BLUE}생성된 내용:${NC}"
echo "----------------------------------------"
cat "$filename"
echo "----------------------------------------"
echo ""

