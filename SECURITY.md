# 보안 가이드 (Security Guide)

## 현재 상태 분석

### ✅ 안전한 부분
- **Anon Key 사용**: 현재 노출된 키는 `anon` (anonymous) 키로, 공개되어도 괜찮은 키입니다.
- **Service Key 미사용**: 관리자 권한이 있는 `service_role` 키는 코드에 없음 (절대 노출 금지!)

### ⚠️ 보안 조치 필요 사항

---

## 1. Supabase RLS (Row Level Security) 설정 ⭐ 가장 중요!

Supabase 대시보드에서 각 테이블의 RLS 정책을 설정해야 합니다.

### 📍 설정 방법
1. Supabase Dashboard → Authentication → Policies
2. 각 테이블별로 정책 활성화

### 테이블별 권장 정책

#### `photos` 테이블
```sql
-- RLS 활성화
ALTER TABLE photos ENABLE ROW LEVEL SECURITY;

-- 모든 사용자 읽기 허용 (is_visible = true인 항목만)
CREATE POLICY "Anyone can view visible photos"
ON photos FOR SELECT
USING (is_visible = true OR true); -- 모든 사진 조회 허용 (필요시 is_visible = true로 제한)

-- 익명 사용자 삽입 허용 (게스트 사진 업로드)
CREATE POLICY "Anyone can upload guest photos"
ON photos FOR INSERT
WITH CHECK (photo_type = 'guest');

-- 게스트가 본인 사진만 삭제 가능 (비밀번호 일치 시)
CREATE POLICY "Users can delete their own photos"
ON photos FOR UPDATE
USING (photo_type = 'guest')
WITH CHECK (del_yn = 'Y');

-- 관리자만 is_visible, display_order 변경 가능 (admin 페이지용)
-- 주의: 현재 인증 시스템이 없으므로 이 정책은 보류
-- 대안: admin.html을 비공개로 유지하거나 별도 인증 추가
```

#### `guestbook` 테이블
```sql
-- RLS 활성화
ALTER TABLE guestbook ENABLE ROW LEVEL SECURITY;

-- 모든 사용자 읽기 허용
CREATE POLICY "Anyone can view guestbook"
ON guestbook FOR SELECT
USING (true);

-- 익명 사용자 삽입 허용
CREATE POLICY "Anyone can insert guestbook"
ON guestbook FOR INSERT
WITH CHECK (true);

-- 비밀번호 일치 시 본인 글만 삭제 허용
-- 주의: 클라이언트에서 비밀번호 체크하므로 완벽한 보안은 아님
CREATE POLICY "Users can delete their own messages"
ON guestbook FOR DELETE
USING (true); -- 클라이언트 측에서 비밀번호 확인 후 삭제
```

#### `rsvp` 테이블
```sql
-- RLS 활성화
ALTER TABLE rsvp ENABLE ROW LEVEL SECURITY;

-- 읽기 차단 (관리자만 보도록)
CREATE POLICY "Only admin can view rsvp"
ON rsvp FOR SELECT
USING (false); -- 일반 사용자는 조회 불가

-- 익명 사용자 삽입만 허용
CREATE POLICY "Anyone can submit rsvp"
ON rsvp FOR INSERT
WITH CHECK (true);

-- 수정/삭제 불가
-- (기본적으로 정책이 없으면 차단됨)
```

---

## 2. Storage 버킷 정책 설정

### `wedding-photos` 버킷 정책

#### 📍 설정 방법
1. Supabase Dashboard → Storage → wedding-photos → Policies

```sql
-- 모든 사용자 파일 읽기 허용
CREATE POLICY "Anyone can view photos"
ON storage.objects FOR SELECT
USING (bucket_id = 'wedding-photos');

-- 게스트는 guest/ 폴더에만 업로드 가능
CREATE POLICY "Anyone can upload to guest folder"
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'wedding-photos'
  AND (storage.foldername(name))[1] = 'guest'
);

-- 관리자만 main/, admin/ 폴더 업로드 가능
-- 주의: 현재 admin.html에 인증이 없으므로 보류
-- 대안: admin.html을 GitHub Pages에서 제외하고 로컬에서만 사용

-- 게스트가 본인 사진만 삭제 (del_yn 업데이트)
-- Storage에서 직접 삭제는 허용하지 않고, photos 테이블의 del_yn만 변경
CREATE POLICY "Prevent direct file deletion"
ON storage.objects FOR DELETE
USING (false); -- 파일 직접 삭제 차단
```

---

## 3. Rate Limiting 설정

### 📍 설정 방법
1. Supabase Dashboard → Settings → API
2. Rate Limits 설정

### 권장 설정
- **Anonymous users**: 100 requests/hour (익명 사용자)
- **Authenticated users**: 500 requests/hour (인증 사용자, 해당 없음)
- **File uploads**: 10 uploads/hour per IP (파일 업로드)

---

## 4. 추가 보안 권장 사항

### A. admin.html 보호

#### 옵션 1: GitHub Pages에서 제외
```bash
# .gitignore에 추가
admin.html
```
- 관리자 페이지를 로컬에서만 사용
- `python3 -m http.server 8000`로 로컬 서버 실행

#### 옵션 2: 간단한 비밀번호 인증 추가
```html
<!-- admin.html 상단에 추가 -->
<script>
  const ADMIN_PASSWORD = prompt("관리자 비밀번호를 입력하세요:");
  if (ADMIN_PASSWORD !== "your-secret-password-here") {
    alert("접근 권한이 없습니다.");
    window.location.href = "index.html";
  }
</script>
```
⚠️ 주의: 이 방법도 개발자도구로 우회 가능하므로 완벽하지 않음

#### 옵션 3: Supabase Auth 추가 (가장 안전)
- Supabase Authentication 활성화
- 이메일/비밀번호 로그인 구현
- RLS 정책에서 `auth.uid()` 사용하여 관리자만 접근 허용

### B. 비밀번호 암호화

현재 `guestbook.password`가 평문 저장됨
```javascript
// 간단한 해싱 예시 (SHA-256)
async function hashPassword(password) {
  const msgBuffer = new TextEncoder().encode(password);
  const hashBuffer = await crypto.subtle.digest('SHA-256', msgBuffer);
  const hashArray = Array.from(new Uint8Array(hashBuffer));
  return hashArray.map(b => b.toString(16).padStart(2, '0')).join('');
}

// 저장 시
const hashedPassword = await hashPassword(password);

// 삭제 시 비교
const inputHash = await hashPassword(inputPassword);
if (storedHash === inputHash) {
  // 삭제 허용
}
```

### C. XSS 방지

사용자 입력값 출력 시 HTML 이스케이프 처리
```javascript
function escapeHtml(unsafe) {
  return unsafe
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#039;");
}

// 방명록 출력 시
messageDiv.textContent = escapeHtml(message); // innerHTML 대신 textContent 사용
```

### D. CORS 설정 확인

Supabase Dashboard → Settings → API → CORS
- 허용된 도메인만 추가: `https://yourdomain.github.io`

---

## 5. 긴급 조치 (키 노출 시)

만약 `service_role` 키가 노출되었다면:
1. Supabase Dashboard → Settings → API
2. **Reset** 버튼으로 키 재생성
3. 모든 코드에서 키 업데이트

`anon` 키는 공개되어도 RLS 정책으로 보호되므로 크게 문제되지 않음.

---

## 6. 모니터링

### 📍 Supabase Dashboard에서 확인
1. **Database** → **Logs**: 쿼리 로그 확인
2. **Storage** → **Usage**: 파일 업로드 현황
3. **API** → **Logs**: API 요청 로그

### 의심스러운 활동 감지 시
- IP 차단
- Rate Limit 강화
- 필요시 키 재생성

---

## 우선순위

### 🔴 필수 (즉시 적용)
1. **RLS 정책 활성화** (photos, guestbook, rsvp)
2. **Storage 정책 설정** (wedding-photos 버킷)
3. **admin.html 보호** (GitHub Pages에서 제외 또는 인증 추가)

### 🟡 권장 (가능하면 적용)
4. Rate Limiting 설정
5. 비밀번호 해싱
6. XSS 방지 처리
7. CORS 도메인 제한

### 🟢 선택 (장기적 개선)
8. Supabase Auth 추가
9. 모니터링 시스템 구축

---

## 정리

**클라이언트 사이드 웹앱의 한계**
- HTML/JavaScript는 모든 코드가 노출되므로 완벽한 보안은 불가능
- **Supabase RLS가 실질적인 보안 계층**
- Anon Key 노출은 괜찮음 (RLS로 권한 제어)
- Service Key는 절대 클라이언트에 노출 금지

**웨딩 청첩장 특성 고려**
- 공개 웹사이트이므로 대부분 읽기는 허용
- 악의적인 대량 데이터 삽입/수정/삭제만 방지하면 충분
- 개인정보(RSVP, 방명록)는 RLS로 보호

위 조치들을 적용하면 실질적인 보안 위험을 크게 줄일 수 있습니다.
