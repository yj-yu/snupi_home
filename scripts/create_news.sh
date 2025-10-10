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

NEWS_DIR="_news"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}   새로운 뉴스 추가하기${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# 필수 필드: title
echo -e "${GREEN}[필수]${NC} Title을 입력하세요 (예: Congratulations! 4 Papers Accepted at ACL2025):"
read -r title

# 필수 필드: subtitle
echo -e "${GREEN}[필수]${NC} Subtitle을 입력하세요 (예: acl-accept):"
read -r subtitle

# 필수 필드: type
echo -e "${GREEN}[필수]${NC} Type을 선택하세요:"
echo "  1) papers"
echo "  2) others"
read -r type_choice

case $type_choice in
    1) type="papers"; categories="news papers";;
    2) type="others"; categories="news others";;
    *) echo "잘못된 선택입니다."; exit 1;;
esac

# 선택 필드: emoji
echo -e "${YELLOW}[선택]${NC} Emoji를 입력하세요 (선택사항, 기본값: 🎉):"
read -r emoji
if [ -z "$emoji" ]; then
    emoji="🎉"
fi

# 필수 필드: year
echo -e "${GREEN}[필수]${NC} Year를 입력하세요 (예: 2025):"
read -r year

# 필수 필드: date
echo -e "${GREEN}[필수]${NC} Date를 입력하세요 (형식: YYYY-MM-DD, 예: 2025-05-16):"
read -r date

# 날짜 형식 검증
if ! [[ $date =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
    echo -e "${RED}잘못된 날짜 형식입니다. YYYY-MM-DD 형식으로 입력해주세요.${NC}"
    exit 1
fi

# 필수 필드: summary
echo -e "${GREEN}[필수]${NC} Summary를 입력하세요 (예: 네 편의 논문이 ACL2025에 accept되었습니다.):"
read -r summary

# 필수 필드: content (body)
echo -e "${GREEN}[필수]${NC} Content를 입력하세요 (여러 줄 입력 가능, 입력 완료 후 빈 줄에서 Ctrl+D):"
echo -e "${YELLOW}(팁: 여러 줄 입력 후 마지막에 빈 줄에서 Ctrl+D를 누르세요)${NC}"
content=""
while IFS= read -r line; do
    content="${content}${line}\n"
done

# 파일명 생성
filename="${NEWS_DIR}/${date}-${subtitle}.md"

# 파일이 이미 존재하는지 확인
if [ -f "$filename" ]; then
    echo -e "${RED}경고: 이미 같은 이름의 파일이 존재합니다: $filename${NC}"
    echo -e "${YELLOW}덮어쓰시겠습니까? (yes/no):${NC}"
    read -r overwrite
    if [ "$overwrite" != "yes" ] && [ "$overwrite" != "y" ] && [ "$overwrite" != "Y" ]; then
        echo "취소되었습니다."
        exit 1
    fi
fi

# Markdown 파일 생성
cat > "$filename" << EOF
---
layout: news-detail
title: $title
subtitle: $subtitle
type: $type
emoji: $emoji
year: $year
date: $date
summary: "$summary"
body: "

$content
  "
excerpt: >
categories: $categories
---

EOF

echo ""
echo -e "${GREEN}✓ 파일이 생성되었습니다: $filename${NC}"
echo ""

