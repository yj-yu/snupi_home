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
echo -e "${BLUE}   사람 정보 수정하기${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# 모든 사람 리스트 출력
echo -e "${GREEN}현재 등록된 사람 목록:${NC}"
echo ""

declare -a fullnames
declare -a filenames
index=1

for file in "$PEOPLE_DIR"/*.md; do
    if [ -f "$file" ]; then
        # fullname 추출
        fullname=$(grep "^fullname:" "$file" | sed 's/fullname: "\(.*\)"/\1/')
        if [ -n "$fullname" ]; then
            echo "  $index) $fullname"
            fullnames[$index]="$fullname"
            filenames[$index]="$file"
            ((index++))
        fi
    fi
done

echo ""
echo -e "${YELLOW}수정할 사람의 번호 또는 이름을 입력하세요:${NC}"
read -r selection

# 번호로 선택했는지 확인
if [[ "$selection" =~ ^[0-9]+$ ]]; then
    selected_file="${filenames[$selection]}"
    selected_name="${fullnames[$selection]}"
else
    # 이름으로 검색
    for i in "${!fullnames[@]}"; do
        if [[ "${fullnames[$i]}" == "$selection" ]]; then
            selected_file="${filenames[$i]}"
            selected_name="${fullnames[$i]}"
            break
        fi
    done
fi

if [ -z "$selected_file" ] || [ ! -f "$selected_file" ]; then
    echo -e "${RED}해당하는 사람을 찾을 수 없습니다.${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}선택된 사람: $selected_name${NC}"
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
echo "  1) fullname"
echo "  2) img-filename"
echo "  3) emoji"
echo "  4) position"
echo "  5) email"
echo "  6) permalink"
echo "  7) works"
echo "  8) social (website URL)"
echo "  9) fields"
echo "  0) 전체 다시 작성"
read -r field_choice

case $field_choice in
    1)
        echo "새로운 Full Name을 입력하세요:"
        read -r new_value
        sed -i.bak "s/^fullname: .*/fullname: \"$new_value\"/" "$selected_file" && rm "${selected_file}.bak"
        ;;
    2)
        echo "새로운 이미지 파일명을 입력하세요:"
        read -r new_value
        sed -i.bak "s/^img-filename: .*/img-filename: $new_value/" "$selected_file" && rm "${selected_file}.bak"
        ;;
    3)
        echo "새로운 Emoji를 입력하세요:"
        read -r new_value
        if grep -q "^emoji:" "$selected_file"; then
            sed -i.bak "s/^emoji: .*/emoji: $new_value/" "$selected_file" && rm "${selected_file}.bak"
        else
            # emoji 필드가 없으면 img-filename 다음에 추가
            sed -i.bak "/^img-filename:/a\\
emoji: $new_value" "$selected_file" && rm "${selected_file}.bak"
        fi
        ;;
    4)
        echo "새로운 Position을 선택하세요:"
        echo "  1) Ph.D. Student"
        echo "  2) MS Student"
        echo "  3) Visiting Scholar"
        echo "  4) Alumni"
        echo "  5) Intern"
        echo "  6) Collaborator"
        read -r pos_choice
        case $pos_choice in
            1) new_value="Ph.D. Student";;
            2) new_value="MS Student";;
            3) new_value="Visiting Scholar";;
            4) new_value="Alumni";;
            5) new_value="Intern";;
            6) new_value="Collaborator";;
            *) echo "잘못된 선택입니다."; exit 1;;
        esac
        sed -i.bak "s/^position: .*/position: \"$new_value\"/" "$selected_file" && rm "${selected_file}.bak"
        ;;
    5)
        echo "새로운 Email을 입력하세요:"
        read -r new_value
        sed -i.bak "s/^email: .*/email: $new_value/" "$selected_file" && rm "${selected_file}.bak"
        ;;
    6)
        echo "새로운 Permalink를 입력하세요:"
        read -r new_value
        sed -i.bak "s|^permalink: .*|permalink: $new_value|" "$selected_file" && rm "${selected_file}.bak"
        ;;
    7)
        echo "새로운 Works 이미지 파일명을 입력하세요:"
        read -r new_value
        if grep -q "^works:" "$selected_file"; then
            sed -i.bak "s/^works: .*/works: $new_value/" "$selected_file" && rm "${selected_file}.bak"
        else
            # works 필드가 없으면 email 다음에 추가
            sed -i.bak "/^email:/a\\
\\
works: $new_value" "$selected_file" && rm "${selected_file}.bak"
        fi
        ;;
    8)
        echo "새로운 Website URL을 입력하세요:"
        read -r new_value
        # social 섹션 전체를 교체
        if grep -q "^social:" "$selected_file"; then
            # 기존 social 섹션 제거 후 새로 추가
            sed -i.bak '/^social:/,/^$/d' "$selected_file" && rm "${selected_file}.bak"
        fi
        # permalink 또는 email 다음에 social 섹션 추가
        sed -i.bak "/^email:/a\\
\\
social:\\
  - title: home\\
    url: $new_value\\
" "$selected_file" && rm "${selected_file}.bak"
        ;;
    9)
        echo "새로운 Fields를 입력하세요 (쉼표로 구분):"
        read -r new_fields
        # fields 섹션 전체를 교체
        if grep -q "^fields:" "$selected_file"; then
            sed -i.bak '/^fields:/,/^$/d' "$selected_file" && rm "${selected_file}.bak"
        fi
        # social 섹션 뒤에 fields 추가
        temp_fields="fields:\n"
        IFS=',' read -ra FIELDS <<< "$new_fields"
        for field in "${FIELDS[@]}"; do
            field=$(echo "$field" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
            temp_fields="${temp_fields}    - name : $field\n"
        done
        # publications 앞에 삽입
        sed -i.bak "/^publications:/i\\
$temp_fields" "$selected_file" && rm "${selected_file}.bak"
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

