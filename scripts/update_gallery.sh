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

GALLERY_DIR="_gallery"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}   갤러리 정보 수정하기${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# 모든 갤러리 리스트 출력
echo -e "${GREEN}현재 등록된 갤러리 목록:${NC}"
echo ""

declare -a titles
declare -a filenames
index=1

for file in "$GALLERY_DIR"/*.md; do
    if [ -f "$file" ]; then
        # title과 year 추출
        title=$(grep "^title:" "$file" | sed 's/title: "\(.*\)"/\1/')
        year=$(grep "^year:" "$file" | sed 's/year: //')
        if [ -n "$title" ]; then
            echo "  $index) [$year] $title"
            titles[$index]="$title"
            filenames[$index]="$file"
            ((index++))
        fi
    fi
done

echo ""
echo -e "${YELLOW}수정할 갤러리의 번호 또는 제목을 입력하세요:${NC}"
read -r selection

# 번호로 선택했는지 확인
if [[ "$selection" =~ ^[0-9]+$ ]]; then
    selected_file="${filenames[$selection]}"
    selected_title="${titles[$selection]}"
else
    # 제목으로 검색
    for i in "${!titles[@]}"; do
        if [[ "${titles[$i]}" == "$selection" ]]; then
            selected_file="${filenames[$i]}"
            selected_title="${titles[$i]}"
            break
        fi
    done
fi

if [ -z "$selected_file" ] || [ ! -f "$selected_file" ]; then
    echo -e "${RED}해당하는 갤러리를 찾을 수 없습니다.${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}선택된 갤러리: $selected_title${NC}"
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
echo "  1) title"
echo "  2) description"
echo "  3) img-filename"
echo "  4) year"
echo "  0) 전체 다시 작성"
read -r field_choice

# 현재 파일명에서 정보 추출
current_basename=$(basename "$selected_file" .md)
current_year=$(echo "$current_basename" | cut -d'-' -f1)
current_index=$(echo "$current_basename" | cut -d'-' -f2)
current_title=$(echo "$current_basename" | cut -d'-' -f3-)

new_file=""

case $field_choice in
    1)
        echo "새로운 Title을 입력하세요:"
        read -r new_value
        sed -i.bak "s/^title: .*/title: \"$new_value\"/" "$selected_file" && rm "${selected_file}.bak"
        # 파일명 변경 (연도-인덱스-새title.md)
        new_file="${GALLERY_DIR}/${current_year}-${current_index}-${new_value}.md"
        ;;
    2)
        echo "새로운 Description을 입력하세요:"
        read -r new_value
        sed -i.bak "s/^description: .*/description: $new_value/" "$selected_file" && rm "${selected_file}.bak"
        ;;
    3)
        echo "새로운 이미지 파일명을 입력하세요:"
        read -r new_value
        sed -i.bak "s/^img-filename: .*/img-filename: $new_value/" "$selected_file" && rm "${selected_file}.bak"
        ;;
    4)
        echo "새로운 Year를 입력하세요:"
        read -r new_value
        sed -i.bak "s/^year: .*/year: $new_value/" "$selected_file" && rm "${selected_file}.bak"
        # 새 연도의 마지막 인덱스 찾기
        last_file=$(ls -1 "${GALLERY_DIR}/${new_value}-"* 2>/dev/null | tail -1)
        if [ -z "$last_file" ]; then
            new_index="01"
        else
            last_number=$(basename "$last_file" | cut -d'-' -f2)
            new_index=$(printf "%02d" $((10#$last_number + 1)))
        fi
        # 파일명 변경 (새연도-새인덱스-title.md)
        new_file="${GALLERY_DIR}/${new_value}-${new_index}-${current_title}.md"
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

# 파일명 변경이 필요한 경우
if [ -n "$new_file" ] && [ "$new_file" != "$selected_file" ]; then
    mv "$selected_file" "$new_file"
    selected_file="$new_file"
    echo ""
    echo -e "${GREEN}✓ 파일명이 변경되었습니다: $(basename $new_file)${NC}"
fi

echo ""
echo -e "${GREEN}✓ 수정이 완료되었습니다!${NC}"
echo ""
echo -e "${BLUE}수정된 내용:${NC}"
echo "----------------------------------------"
cat "$selected_file"
echo "----------------------------------------"

