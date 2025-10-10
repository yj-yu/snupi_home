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

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}   논문 삭제하기${NC}"
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
echo -e "${YELLOW}삭제할 논문의 번호를 입력하세요:${NC}"
read -r selection

selected_file="${filenames[$selection]}"
selected_name="${names[$selection]}"

if [ -z "$selected_file" ] || [ ! -f "$selected_file" ]; then
    echo -e "${RED}해당하는 논문을 찾을 수 없습니다.${NC}"
    exit 1
fi

echo ""
echo -e "${YELLOW}다음 파일을 삭제하시겠습니까?${NC}"
echo -e "${RED}논문: $selected_name${NC}"
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

