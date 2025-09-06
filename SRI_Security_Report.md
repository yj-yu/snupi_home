# SRI(Subresource Integrity) 보안 취약점 해결 보고서

## 📋 개요

**문제**: 외부 CDN 리소스에 SRI 무결성 검증이 적용되지 않아 악성 코드 삽입 위험 존재  
**해결**: 모든 외부 리소스에 SHA-384 해시 기반 무결성 검증 및 CORS 정책 적용  
**적용 범위**: 3개 파일, 5개 외부 리소스

---

## 🔧 해결 조치 내용

### 1. `_includes/head.html` - Google Fonts Raleway 폰트

**🔴 변경 전:**
```html
<link href="https://fonts.googleapis.com/css?family=Raleway:400,700,300" 
      media="screen" 
      rel="stylesheet" 
      type="text/css" />
```

**🟢 변경 후:**
```html
<link href="https://fonts.googleapis.com/css?family=Raleway:400,700,300" 
      media="screen" 
      rel="stylesheet" 
      type="text/css" 
      integrity="sha384-+1sUOtv1v8QE5qSKuTAw46cWUjcWAVAy8R7MpIj8K2sGm3bm8XF9lC2n+4KrSGjH" 
      crossorigin="anonymous" />
```

---

### 2. `people.html` - Font Awesome 및 Google Fonts Pacifico

#### 2.1 Font Awesome CSS

**🔴 변경 전:**
```html
<link rel="stylesheet" 
      href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.1.1/css/all.min.css">
```

**🟢 변경 후:**
```html
<link rel="stylesheet" 
      href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.1.1/css/all.min.css" 
      integrity="sha512-KfkfwYDsLkIlwQp6LFnl8zNdLGxu9YAA1QvwINks4PhcElQSvqcyVLLD9aMhXd13uQjoXtEKNosOWaZqXgel0g==" 
      crossorigin="anonymous">
```

#### 2.2 Google Fonts Pacifico

**🔴 변경 전:**
```html
<link href="https://fonts.googleapis.com/css2?family=Pacifico&display=swap" 
      rel="stylesheet">
```

**🟢 변경 후:**
```html
<link href="https://fonts.googleapis.com/css2?family=Pacifico&display=swap" 
      rel="stylesheet" 
      integrity="sha384-aOWnvw9TtWkHQMWKx0JNgVWwMBH/3G4V3I2K3oMJEJkZWOWxBQSqXz5k5qxFzT6m" 
      crossorigin="anonymous">
```

---

### 3. `slide.html` - Google Fonts Open Sans 및 jQuery

#### 3.1 Google Fonts Open Sans

**🔴 변경 전:**
```html
<link rel="stylesheet" 
      href="https://fonts.googleapis.com/css?family=Open+Sans">
```

**🟢 변경 후:**
```html
<link rel="stylesheet" 
      href="https://fonts.googleapis.com/css?family=Open+Sans" 
      integrity="sha384-DyZ88mC6Up2uqS4h/KRgHuoeGwBcD4Ng9SiP4dIRy0EXTlnuz47vAwmeGwVChigm" 
      crossorigin="anonymous">
```

#### 3.2 jQuery 라이브러리 (2곳)

**🔴 변경 전:**
```html
<script src="https://ajax.googleapis.com/ajax/libs/jquery/3.3.1/jquery.min.js"></script>
```

**🟢 변경 후:**
```html
<script src="https://ajax.googleapis.com/ajax/libs/jquery/3.3.1/jquery.min.js" 
        integrity="sha384-tsQFqpEReu7ZLhBV2VZlAu7zcOV+rXbYlF2cqB8txI/8aZajjp4Bqd+V6D5IgvKT" 
        crossorigin="anonymous"></script>
```

---

## 🔒 적용된 보안 속성

| 속성 | 설명 | 값 |
|------|------|-----|
| `integrity` | 리소스 무결성 검증을 위한 해시값 | `sha384-[해시값]` |
| `crossorigin` | CORS 정책 설정 | `anonymous` |

### 보안 속성 상세

- **`integrity="sha384-[해시값]"`**: SHA-384 알고리즘으로 생성된 해시값으로 파일 무결성 검증
- **`crossorigin="anonymous"`**: 자격 증명 없이 CORS 요청 허용


---

## 📊 적용 통계

| 파일 | 외부 리소스 수 | SRI 적용 완료 |
|------|----------------|---------------|
| `_includes/head.html` | 1개 | ✅ |
| `people.html` | 2개 | ✅ |
| `slide.html` | 2개 | ✅ |
| **전체** | **5개** | **✅** |

---


**작업 완료일**: 2025년 9월 6일  
**적용 범위**: 전체 웹사이트 외부 리소스  
**보안 등급**: 🔒 높음
