# 홈페이지 관리 스크립트

홈페이지의 `_people`, `_publications`, `_news`, `_gallery` 디렉토리에 있는 데이터를 관리하는 bash 스크립트입니다.

## 📑 목차

- [People (사람) 관리](#people-사람-관리)
  - [생성: create_person.sh](#생성-create_personsh)
  - [수정: update_person.sh](#수정-update_personsh)
  - [삭제: delete_person.sh](#삭제-delete_personsh)
- [Publications (논문) 관리](#publications-논문-관리)
  - [생성: create_publication.sh](#생성-create_publicationsh)
  - [수정: update_publication.sh](#수정-update_publicationsh)
  - [삭제: delete_publication.sh](#삭제-delete_publicationsh)
- [News (뉴스) 관리](#news-뉴스-관리)
  - [생성: create_news.sh](#생성-create_newssh)
  - [수정: update_news.sh](#수정-update_newssh)
  - [삭제: delete_news.sh](#삭제-delete_newssh)
- [Gallery (갤러리) 관리](#gallery-갤러리-관리)
  - [생성: create_gallery.sh](#생성-create_gallerysh)
  - [수정: update_gallery.sh](#수정-update_gallerysh)
  - [삭제: delete_gallery.sh](#삭제-delete_gallerysh)
- [공통 사항](#공통-사항)

---

## People (사람) 관리

### 생성: create_person.sh

새로운 멤버를 추가하는 스크립트입니다.

**⚠️ 주의:** `images/people` 디렉토리에 이미지 파일을 먼저 업로드해야 합니다.

**사용법:**
```bash
./scripts/create_person.sh
```

**입력 항목:**

**필수 필드:**
- **Full Name**: 이름 (예: Seungbeen Lee)
- **Image filename**: 프로필 이미지 파일명 (예: lee_seungbeen.jpg)
- **Position**: 직책 선택
  - Ph.D. Student
  - MS Student
  - Visiting Scholar
  - Alumni
  - Intern
  - Collaborator
- **Email**: 이메일 주소
- **Fields**: 연구 분야 (쉼표로 구분, 예: NLP, LLM, Robotics)

**선택 필드:**
- **Emoji**: 이모지
- **Personal website URL**: 개인 홈페이지 URL
- **Works**: 소속 기관 이미지 파일명

**특징:**
- Permalink는 Full Name의 첫 단어를 소문자로 변환하여 자동 생성
- 파일명 형식: `XX-YY-name.md` (XX: position prefix, YY: 자동 증가 번호)

---

### 수정: update_person.sh

기존 멤버의 정보를 수정하는 스크립트입니다.

**사용법:**
```bash
./scripts/update_person.sh
```

**수정 가능한 필드:**
1. fullname
2. img-filename
3. emoji
4. position
5. email
6. permalink
7. works
8. social (website URL)
9. fields
0. 전체 다시 작성 (에디터로 열기)

**작동 방식:**
1. 현재 등록된 모든 사람의 목록 표시
2. 번호 또는 이름을 입력하여 수정할 사람 선택
3. 현재 정보 확인
4. 수정할 필드 선택 및 새로운 값 입력

---

### 삭제: delete_person.sh

멤버를 삭제하는 스크립트입니다.

**사용법:**
```bash
./scripts/delete_person.sh
```

**작동 방식:**
1. 현재 등록된 모든 사람의 목록 표시
2. 번호 또는 이름을 입력하여 삭제할 사람 선택
3. 삭제할 파일의 내용 확인
4. 확인 후 삭제 진행 (yes/no)

**⚠️ 주의:** 삭제는 되돌릴 수 없으므로 신중하게 진행하세요!

---

## Publications (논문) 관리

### 생성: create_publication.sh

새로운 논문을 추가하는 스크립트입니다.

**⚠️ 주의:** `images/papers` 디렉토리에 이미지 파일을 먼저 업로드해야 합니다.

**사용법:**
```bash
./scripts/create_publication.sh
```

**입력 항목:**

**필수 필드:**
- **Name**: 논문 제목
- **Year**: 연도 (예: 2025)
- **Authors**: 저자 목록 (쉼표로 구분, 예: Saejin Kim, Sungwoong Kim, Youngjae Yu)
- **Image**: 이미지 경로 (예: xxx.png)
- **Keywords**: 키워드 목록 (쉼표로 구분, 예: Multimodal, Reasoning, NLP)

**선택 필드:**
- **Conference**: 학회/저널명 (예: CVPR2025, NeurIPS2025)
- **URL**: Arxiv URL (예: https://arxiv.org/abs/...)
- **Equal Contributor Indices**: 공동 1저자 인덱스 (쉼표로 구분, 예: 0,1)

**특징:**
- 파일명은 연도와 순서 번호를 기반으로 자동 생성
- 파일명 형식: `YYYY-NN-title.md`
- 특수문자는 자동으로 제거됩니다

---

### 수정: update_publication.sh

기존 논문의 정보를 수정하는 스크립트입니다.

**사용법:**
```bash
./scripts/update_publication.sh
```

**수정 가능한 필드:**
1. name (논문 제목)
2. year (연도)
3. conference (학회/저널)
4. authors (저자 목록)
5. img (이미지)
6. url (Arxiv URL)
7. keywords
8. equal_contributor_idx
0. 전체 다시 작성 (에디터로 열기)

**작동 방식:**
1. 번호를 입력하여 수정할 논문 선택
2. 현재 정보 확인
3. 수정할 필드 선택 및 새로운 값 입력

---

### 삭제: delete_publication.sh

논문을 삭제하는 스크립트입니다.

**사용법:**
```bash
./scripts/delete_publication.sh
```

**작동 방식:**
1. 번호를 입력하여 삭제할 논문 선택
2. 삭제할 파일의 내용 확인
3. 확인 후 삭제 진행 (yes/no)

**⚠️ 주의:** 삭제는 되돌릴 수 없으므로 신중하게 진행하세요!

---

## News (뉴스) 관리

### 생성: create_news.sh

새로운 뉴스를 추가하는 스크립트입니다.

**사용법:**
```bash
./scripts/create_news.sh
```

**입력 항목:**

**필수 필드:**
- **Title**: 뉴스 제목 (예: Congratulations! 4 Papers Accepted at ACL2025)
- **Subtitle**: 부제목 (예: acl-accept)
- **Type**: 뉴스 타입 선택
  - papers
  - others
- **Year**: 연도 (예: 2025)
- **Date**: 날짜 (형식: YYYY-MM-DD, 예: 2025-05-16)
- **Summary**: 요약 내용
- **Content**: 본문 내용 (여러 줄 입력 가능, Ctrl+D로 완료)

**선택 필드:**
- **Emoji**: 이모지 (기본값: 🎉)

**특징:**
- 파일명은 `날짜-부제목.md` 형식으로 자동 생성 (예: 2025-05-16-acl-accept.md)
- Type에 따라 categories 필드가 자동 설정 (news papers 또는 news others)
- 여러 줄 content 입력 후 빈 줄에서 Ctrl+D를 눌러 완료

---

### 수정: update_news.sh

기존 뉴스의 정보를 수정하는 스크립트입니다.

**사용법:**
```bash
./scripts/update_news.sh
```

**수정 가능한 필드:**
1. title (제목)
2. subtitle (부제목)
3. type (papers/others)
4. emoji
5. year (연도)
6. date (날짜)
7. summary (요약)
8. body (본문 내용)
0. 전체 다시 작성 (에디터로 열기)

**작동 방식:**
1. 현재 등록된 모든 뉴스 목록을 날짜와 함께 표시
2. 번호를 입력하여 수정할 뉴스 선택
3. 현재 정보 확인
4. 수정할 필드 선택 및 새로운 값 입력

**💡 참고:**
- subtitle이나 date를 변경할 경우 파일명 변경 여부를 묻습니다

---

### 삭제: delete_news.sh

뉴스를 삭제하는 스크립트입니다.

**사용법:**
```bash
./scripts/delete_news.sh
```

**작동 방식:**
1. 현재 등록된 모든 뉴스 목록을 날짜와 함께 표시
2. 번호를 입력하여 삭제할 뉴스 선택
3. 삭제할 파일의 내용 확인
4. 확인 후 삭제 진행 (yes/no)

**⚠️ 주의:** 삭제는 되돌릴 수 없으므로 신중하게 진행하세요!

---

## Gallery (갤러리) 관리

### 생성: create_gallery.sh

새로운 갤러리 항목을 추가하는 스크립트입니다.

**⚠️ 주의:** `images/gallery` 디렉토리에 이미지 파일을 먼저 업로드해야 합니다.

**사용법:**
```bash
./scripts/create_gallery.sh
```

**입력 항목:**

**필수 필드:**
- **Year**: 연도 (예: 2025)
- **Title**: 제목 (예: naacl)
- **Image filename**: 이미지 파일명 (예: naacl_.jpg)
- **Description**: 설명 (예: NAACL 2025)

**특징:**
- 파일명은 `연도-순서번호-제목.md` 형식으로 자동 생성
- 같은 연도 내에서 순서번호가 자동으로 증가합니다

---

### 수정: update_gallery.sh

기존 갤러리 항목의 정보를 수정하는 스크립트입니다.

**사용법:**
```bash
./scripts/update_gallery.sh
```

**수정 가능한 필드:**
1. title (제목)
2. description (설명)
3. img-filename (이미지 파일명)
4. year (연도)
0. 전체 다시 작성 (에디터로 열기)

**작동 방식:**
1. 현재 등록된 모든 갤러리 목록을 연도와 함께 표시
2. 번호 또는 제목을 입력하여 수정할 갤러리 선택
3. 현재 정보 확인
4. 수정할 필드 선택 및 새로운 값 입력

**💡 참고:**
- title을 변경하면 파일명도 자동으로 변경됩니다
- year를 변경하면 새 연도의 순서번호로 자동 재배치됩니다

---

### 삭제: delete_gallery.sh

갤러리 항목을 삭제하는 스크립트입니다.

**사용법:**
```bash
./scripts/delete_gallery.sh
```

**작동 방식:**
1. 현재 등록된 모든 갤러리 목록을 연도와 함께 표시
2. 번호 또는 제목을 입력하여 삭제할 갤러리 선택
3. 삭제할 파일의 내용 확인
4. 확인 후 삭제 진행 (yes/no)

**⚠️ 주의:** 삭제는 되돌릴 수 없으므로 신중하게 진행하세요!

---

## 공통 사항


### 📁 이미지 파일 위치
이미지 파일은 각 카테고리별로 해당 디렉토리에 업로드해야 합니다:
- **People**: `images/people/`
- **Publications**: `images/papers/`
- **Gallery**: `images/gallery/`

