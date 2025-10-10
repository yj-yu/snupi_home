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
echo -e "${BLUE}   뉴스 정보 수정하기${NC}"
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
        # title 추출
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
echo -e "${YELLOW}수정할 뉴스의 번호를 입력하세요:${NC}"
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
echo -e "${GREEN}선택된 뉴스: $selected_title${NC}"
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
echo "  2) subtitle"
echo "  3) type (papers/others)"
echo "  4) emoji"
echo "  5) year"
echo "  6) date"
echo "  7) summary"
echo "  8) body (content)"
echo "  0) 전체 다시 작성"
read -r field_choice

case $field_choice in
    1)
        echo "새로운 Title을 입력하세요:"
        read -r new_value
        sed -i.bak "s/^title: .*/title: $new_value/" "$selected_file" && rm "${selected_file}.bak"
        ;;
    2)
        echo "새로운 Subtitle을 입력하세요:"
        read -r new_value
        # 파일명도 변경할지 물어보기
        old_subtitle=$(grep "^subtitle:" "$selected_file" | sed 's/subtitle: //')
        sed -i.bak "s/^subtitle: .*/subtitle: $new_value/" "$selected_file" && rm "${selected_file}.bak"
        
        echo -e "${YELLOW}파일명도 변경하시겠습니까? (yes/no):${NC}"
        read -r rename_confirm
        if [ "$rename_confirm" = "yes" ] || [ "$rename_confirm" = "y" ]; then
            new_filename=$(echo "$selected_file" | sed "s/${old_subtitle}/${new_value}/")
            mv "$selected_file" "$new_filename"
            selected_file="$new_filename"
            echo -e "${GREEN}파일명이 변경되었습니다: $new_filename${NC}"
        fi
        ;;
    3)
        echo "새로운 Type을 선택하세요:"
        echo "  1) papers"
        echo "  2) others"
        read -r type_choice
        case $type_choice in
            1) new_type="papers"; new_categories="news papers";;
            2) new_type="others"; new_categories="news others";;
            *) echo "잘못된 선택입니다."; exit 1;;
        esac
        sed -i.bak "s/^type: .*/type: $new_type/" "$selected_file" && rm "${selected_file}.bak"
        sed -i.bak "s/^categories: .*/categories: $new_categories/" "$selected_file" && rm "${selected_file}.bak"
        ;;
    4)
        echo "새로운 Emoji를 입력하세요:"
        read -r new_value
        sed -i.bak "s/^emoji: .*/emoji: $new_value/" "$selected_file" && rm "${selected_file}.bak"
        ;;
    5)
        echo "새로운 Year를 입력하세요:"
        read -r new_value
        sed -i.bak "s/^year: .*/year: $new_value/" "$selected_file" && rm "${selected_file}.bak"
        ;;
    6)
        echo "새로운 Date를 입력하세요 (형식: YYYY-MM-DD):"
        read -r new_value
        if ! [[ $new_value =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
            echo -e "${RED}잘못된 날짜 형식입니다.${NC}"
            exit 1
        fi
        
        old_date=$(grep "^date:" "$selected_file" | sed 's/date: //')
        sed -i.bak "s/^date: .*/date: $new_value/" "$selected_file" && rm "${selected_file}.bak"
        
        echo -e "${YELLOW}파일명도 변경하시겠습니까? (yes/no):${NC}"
        read -r rename_confirm
        if [ "$rename_confirm" = "yes" ] || [ "$rename_confirm" = "y" ]; then
            new_filename=$(echo "$selected_file" | sed "s/${old_date}/${new_value}/")
            mv "$selected_file" "$new_filename"
            selected_file="$new_filename"
            echo -e "${GREEN}파일명이 변경되었습니다: $new_filename${NC}"
        fi
        ;;
    7)
        echo "새로운 Summary를 입력하세요:"
        read -r new_value
        sed -i.bak "s/^summary: .*/summary: \"$new_value\"/" "$selected_file" && rm "${selected_file}.bak"
        ;;
    8)
        echo "새로운 Content를 입력하세요 (여러 줄 입력 가능, 입력 완료 후 빈 줄에서 Ctrl+D):"
        new_content=""
        while IFS= read -r line; do
            new_content="${new_content}${line}\n"
        done
        
        # body 필드 전체를 교체
        # body는 'body: "' 로 시작하고 '  "' 로 끝남
        awk -v new_body="$new_content" '
        /^body: "/ {
            print "body: \""
            print ""
            printf "%s", new_body
            print "  \""
            in_body=1
            next
        }
        /^  "$/ && in_body {
            in_body=0
            next
        }
        !in_body {
            print
        }
        ' "$selected_file" > "${selected_file}.tmp" && mv "${selected_file}.tmp" "$selected_file"
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

