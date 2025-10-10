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
echo -e "${BLUE}   논문 정보 수정하기${NC}"
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
echo -e "${YELLOW}수정할 논문의 번호를 입력하세요:${NC}"
read -r selection

selected_file="${filenames[$selection]}"
selected_name="${names[$selection]}"

if [ -z "$selected_file" ] || [ ! -f "$selected_file" ]; then
    echo -e "${RED}해당하는 논문을 찾을 수 없습니다.${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}선택된 논문: $selected_name${NC}"
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
echo "  1) name (논문 제목)"
echo "  2) year (연도)"
echo "  3) conference (학회/저널)"
echo "  4) authors (저자 목록)"
echo "  5) img (이미지)"
echo "  6) url (Arxiv URL)"
echo "  7) keywords"
echo "  8) equal_contributor_idx"
echo "  0) 전체 다시 작성 (에디터로 열기)"
read -r field_choice

case $field_choice in
    1)
        echo "새로운 논문 제목을 입력하세요:"
        read -r new_value
        sed -i.bak "s/^name: .*/name: \"$new_value\"/" "$selected_file" && rm "${selected_file}.bak"
        ;;
    2)
        echo "새로운 연도를 입력하세요:"
        read -r new_value
        sed -i.bak "s/^year: .*/year: $new_value/" "$selected_file" && rm "${selected_file}.bak"
        ;;
    3)
        echo "새로운 학회/저널명을 입력하세요:"
        read -r new_value
        sed -i.bak "s/^conference: .*/conference: $new_value/" "$selected_file" && rm "${selected_file}.bak"
        ;;
    4)
        echo "새로운 저자 목록을 입력하세요 (쉼표로 구분):"
        read -r new_authors
        # author 섹션 전체를 교체
        sed -i.bak '/^author:/,/^$/d' "$selected_file" && rm "${selected_file}.bak"
        # year 다음에 author 섹션 추가
        temp_authors="author:\n"
        IFS=',' read -ra AUTHORS <<< "$new_authors"
        for author in "${AUTHORS[@]}"; do
            author=$(echo "$author" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
            temp_authors="${temp_authors}  - name: \"$author\"\n"
        done
        sed -i.bak "/^year:/a\\
\\
$temp_authors" "$selected_file" && rm "${selected_file}.bak"
        ;;
    5)
        echo "새로운 이미지 경로를 입력하세요:"
        read -r new_value
        sed -i.bak "s|^img: .*|img: $new_value|" "$selected_file" && rm "${selected_file}.bak"
        ;;
    6)
        echo "새로운 Arxiv URL을 입력하세요:"
        read -r new_value
        # external 섹션의 url만 교체
        sed -i.bak "s|    url: .*|    url: $new_value|" "$selected_file" && rm "${selected_file}.bak"
        ;;
    7)
        echo "새로운 Keywords를 입력하세요 (쉼표로 구분):"
        read -r new_keywords
        
        # 임시 파일 생성
        temp_file=$(mktemp)
        in_keywords=0
        
        # 기존 파일을 읽으면서 keywords 섹션 교체
        while IFS= read -r line; do
            # keywords: 시작 감지
            if [[ "$line" == "keywords:" ]]; then
                in_keywords=1
                # 새로운 keywords 섹션 작성
                echo "keywords:" >> "$temp_file"
                IFS=',' read -ra KEYWORDS <<< "$new_keywords"
                for keyword in "${KEYWORDS[@]}"; do
                    keyword=$(echo "$keyword" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
                    echo "  - name: $keyword" >> "$temp_file"
                done
                echo "" >> "$temp_file"
                continue
            fi
            
            # keywords 섹션 내부는 건너뛰기
            if [[ $in_keywords -eq 1 ]]; then
                # 빈 줄이나 다른 섹션 시작 시 keywords 종료
                if [[ "$line" =~ ^[[:space:]]*$ ]] || [[ "$line" =~ ^[a-z_]+: ]] || [[ "$line" == "---" ]]; then
                    in_keywords=0
                else
                    continue
                fi
            fi
            
            echo "$line" >> "$temp_file"
        done < "$selected_file"
        
        mv "$temp_file" "$selected_file"
        ;;
    8)
        echo "새로운 Equal contributor indices를 입력하세요 (쉼표로 구분, 예: 0,1):"
        read -r new_idx
        # equal_contributor_idx 섹션 제거
        sed -i.bak '/^equal_contributor_idx:/,/^$/d' "$selected_file" && rm "${selected_file}.bak"
        if [ -n "$new_idx" ]; then
            # author 섹션 뒤에 추가
            temp_idx="equal_contributor_idx:\n"
            IFS=',' read -ra INDICES <<< "$new_idx"
            for idx in "${INDICES[@]}"; do
                idx=$(echo "$idx" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
                temp_idx="${temp_idx}  - $idx\n"
            done
            temp_idx="${temp_idx}\n"
            # author 다음 빈 줄들 뒤에 삽입
            sed -i.bak "/^author:/,/^$/{
                /^$/a\\
$temp_idx
            }" "$selected_file" && rm "${selected_file}.bak"
        fi
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

