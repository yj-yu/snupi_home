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

NEWS_DIR="_news"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}   뉴스 삭제하기${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# 모든 뉴스 리스트 출력
echo -e "${GREEN}현재 등록된 뉴스 목록:${NC}"
echo ""

declare -a titles
declare -a filenames
index=1

for file in "$NEWS_DIR"/*.md; do
    if [ -f "$file" ]; then
        # title과 date 추출
        title=$(grep "^title:" "$file" | sed 's/title: //')
        date=$(grep "^date:" "$file" | sed 's/date: //')
        if [ -n "$title" ]; then
            echo "  $index) [$date] $title"
            titles[$index]="$title"
            filenames[$index]="$file"
            ((index++))
        fi
    fi
done

echo ""
echo -e "${YELLOW}삭제할 뉴스의 번호를 입력하세요:${NC}"
read -r selection

# 번호로 선택했는지 확인
if [[ "$selection" =~ ^[0-9]+$ ]]; then
    selected_file="${filenames[$selection]}"
    selected_title="${titles[$selection]}"
else
    echo -e "${RED}올바른 번호를 입력해주세요.${NC}"
    exit 1
fi

if [ -z "$selected_file" ] || [ ! -f "$selected_file" ]; then
    echo -e "${RED}해당하는 뉴스를 찾을 수 없습니다.${NC}"
    exit 1
fi

echo ""
echo -e "${YELLOW}다음 파일을 삭제하시겠습니까?${NC}"
echo -e "${RED}제목: $selected_title${NC}"
echo -e "${RED}파일: $selected_file${NC}"
echo ""
echo -e "${BLUE}파일 내용:${NC}"
echo "----------------------------------------"
cat "$selected_file"
echo "----------------------------------------"
echo ""
echo -e "${YELLOW}정말 삭제하시겠습니까? (yes/no):${NC}"
read -r confirm

if [ "$confirm" = "yes" ] || [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
    rm "$selected_file"
    echo ""
    echo -e "${GREEN}✓ 파일이 삭제되었습니다: $selected_file${NC}"
    echo ""
else
    echo ""
    echo -e "${BLUE}삭제가 취소되었습니다.${NC}"
    echo ""
fi

