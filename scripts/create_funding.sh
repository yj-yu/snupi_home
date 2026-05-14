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

FUNDING_FILE="${FUNDING_FILE:-funding.html}"
FUNDING_IMAGE_DIR="images/fundings"

html_escape() {
    printf '%s' "$1" | sed \
        -e 's/&/\&amp;/g' \
        -e 's/</\&lt;/g' \
        -e 's/>/\&gt;/g' \
        -e 's/"/\&quot;/g'
}

check_logo_file() {
    local logo_file="$1"

    if [ -n "$logo_file" ] && [ ! -f "${FUNDING_IMAGE_DIR}/${logo_file}" ]; then
        echo -e "${YELLOW}경고: ${FUNDING_IMAGE_DIR}/${logo_file} 파일이 없습니다.${NC}"
        echo -e "${YELLOW}그래도 계속 추가하시겠습니까? (y/n):${NC}"
        read -r continue_without_logo
        case "$continue_without_logo" in
            y|Y|yes|YES) ;;
            *) echo "취소되었습니다."; exit 1 ;;
        esac
    fi
}

if [ ! -f "$FUNDING_FILE" ]; then
    echo -e "${RED}오류: ${FUNDING_FILE} 파일을 찾을 수 없습니다.${NC}"
    exit 1
fi

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}   새로운 Funding 추가하기${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

echo -e "${GREEN}[필수]${NC} 추가할 섹션을 선택하세요:"
echo "  1) Grants"
echo "  2) Industry Collaboration"
read -r section_choice

case "$section_choice" in
    1) section="grants";;
    2) section="industry";;
    *) echo -e "${RED}잘못된 선택입니다.${NC}"; exit 1;;
esac

echo -e "${GREEN}[필수]${NC} 과제/협력 이름을 입력하세요 (예: Open Autonomous Digital Twin):"
read -r funding_name

if [ -z "$funding_name" ]; then
    echo -e "${RED}이름은 비워둘 수 없습니다.${NC}"
    exit 1
fi

if [ "$section" = "grants" ]; then
    echo -e "${GREEN}[필수]${NC} 펀딩 주체를 입력하세요 (예: NRF, IITP, KEIT):"
else
    echo -e "${GREEN}[필수]${NC} 협력 기관을 입력하세요 (예: SK Hynix, Google Research):"
fi
read -r primary_name

if [ -z "$primary_name" ]; then
    echo -e "${RED}펀딩/기관 이름은 비워둘 수 없습니다.${NC}"
    exit 1
fi

echo -e "${GREEN}[필수]${NC} 메인 로고 파일명을 입력하세요 (${FUNDING_IMAGE_DIR}/ 아래 파일명, 예: NRF.png):"
read -r primary_logo

if [ -z "$primary_logo" ]; then
    echo -e "${RED}로고 파일명은 비워둘 수 없습니다.${NC}"
    exit 1
fi

check_logo_file "$primary_logo"

lead_name=""
lead_logo=""
if [ "$section" = "grants" ]; then
    echo -e "${YELLOW}[선택]${NC} 주관 기관을 입력하세요 (예: KETI, Holiday Robotics, Enter로 건너뛰기):"
    read -r lead_name

    if [ -n "$lead_name" ]; then
        echo -e "${YELLOW}[선택]${NC} 주관 기관 로고 파일명을 입력하세요 (예: KETI.png, Enter로 건너뛰기):"
        read -r lead_logo
        if [ -n "$lead_logo" ]; then
            check_logo_file "$lead_logo"
        fi
    fi
fi

escaped_name=$(html_escape "$funding_name")
escaped_primary_name=$(html_escape "$primary_name")
escaped_primary_logo=$(html_escape "$primary_logo")
escaped_lead_name=$(html_escape "$lead_name")
escaped_lead_logo=$(html_escape "$lead_logo")

card_file=$(mktemp)

if [ "$section" = "grants" ] && [ -n "$lead_name" ]; then
    if [ -n "$lead_logo" ]; then
        cat > "$card_file" << EOF
          <article class="funding-card">
            <div class="funding-logo-wrap has-secondary">
              <img class="funding-logo" src="images/fundings/${escaped_primary_logo}" alt="${escaped_primary_name}">
              <img class="funding-logo-secondary" src="images/fundings/${escaped_lead_logo}" alt="${escaped_lead_name}">
            </div>
            <div>
              <h3 class="funding-name">${escaped_name}</h3>
              <p class="funding-meta"><strong>Funding</strong> ${escaped_primary_name}<br><strong>Lead</strong> ${escaped_lead_name}</p>
            </div>
          </article>
EOF
    else
        cat > "$card_file" << EOF
          <article class="funding-card">
            <div class="funding-logo-wrap">
              <img class="funding-logo" src="images/fundings/${escaped_primary_logo}" alt="${escaped_primary_name}">
            </div>
            <div>
              <h3 class="funding-name">${escaped_name}</h3>
              <p class="funding-meta"><strong>Funding</strong> ${escaped_primary_name}<br><strong>Lead</strong> ${escaped_lead_name}</p>
            </div>
          </article>
EOF
    fi
elif [ "$section" = "grants" ]; then
    cat > "$card_file" << EOF
          <article class="funding-card">
            <div class="funding-logo-wrap">
              <img class="funding-logo" src="images/fundings/${escaped_primary_logo}" alt="${escaped_primary_name}">
            </div>
            <div>
              <h3 class="funding-name">${escaped_name}</h3>
              <p class="funding-meta"><strong>Funding</strong> ${escaped_primary_name}</p>
            </div>
          </article>
EOF
else
    cat > "$card_file" << EOF
          <article class="funding-card">
            <div class="funding-logo-wrap">
              <img class="funding-logo" src="images/fundings/${escaped_primary_logo}" alt="${escaped_primary_name}">
            </div>
            <div>
              <h3 class="funding-name">${escaped_name}</h3>
              <p class="funding-meta"><strong>Partner</strong> ${escaped_primary_name}</p>
            </div>
          </article>
EOF
fi

ruby - "$FUNDING_FILE" "$card_file" "$section" <<'RUBY'
file, card_file, section = ARGV
html = File.read(file)
card = File.read(card_file).rstrip

patterns = {
  "grants" => /(      <section class="funding-section">\n        <h2 class="funding-section-title">Grants<\/h2>\n        <div class="funding-grid grants-grid">\n)(.*?)(\n        <\/div>\n      <\/section>)/m,
  "industry" => /(      <section class="funding-section">\n        <h2 class="funding-section-title">Industry Collaboration<\/h2>\n        <div class="funding-grid two-column">\n)(.*?)(\n        <\/div>\n      <\/section>)/m
}

pattern = patterns.fetch(section)

unless html.match?(pattern)
  warn "오류: funding.html에서 대상 섹션을 찾지 못했습니다."
  exit 1
end

html.sub!(pattern) do
  "#{$1}#{$2.rstrip}\n\n#{card}#{$3}"
end

File.write(file, html)
RUBY

insert_status=$?
rm -f "$card_file"

if [ $insert_status -ne 0 ]; then
    exit $insert_status
fi

echo ""
echo -e "${GREEN}✓ Funding 항목이 추가되었습니다: ${funding_name}${NC}"
echo -e "${BLUE}수정된 파일:${NC} ${FUNDING_FILE}"
echo ""
