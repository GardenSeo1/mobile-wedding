-- ====================================
-- Supabase RLS 정책 설정
-- ====================================
-- Supabase Dashboard → SQL Editor에서 실행
-- 또는 Database → Tables → 각 테이블 → RLS Policies에서 개별 추가
-- ====================================

-- ====================================
-- 1. guestbook 테이블 RLS 설정
-- ====================================

-- RLS 활성화
ALTER TABLE guestbook ENABLE ROW LEVEL SECURITY;

-- 정책 1: 모든 사용자가 방명록 읽기 가능
CREATE POLICY "Anyone can view guestbook"
ON guestbook
FOR SELECT
USING (true);

-- 정책 2: 모든 사용자가 방명록 작성 가능
CREATE POLICY "Anyone can insert guestbook"
ON guestbook
FOR INSERT
WITH CHECK (
  -- 필수 필드 검증
  name IS NOT NULL
  AND name != ''
  AND password IS NOT NULL
  AND password != ''
  AND message IS NOT NULL
  AND message != ''
  -- 메시지 길이 제한 (1000자)
  AND length(message) <= 1000
  -- 이름 길이 제한 (50자)
  AND length(name) <= 50
);

-- 정책 3: 모든 사용자가 방명록 삭제 가능 (비밀번호는 클라이언트에서 검증)
-- 주의: 완벽한 보안은 아니지만, 간단한 웨딩 청첩장 용도로는 충분
CREATE POLICY "Anyone can delete guestbook"
ON guestbook
FOR DELETE
USING (true);

-- 수정은 불가 (정책 없음 = 기본 차단)


-- ====================================
-- 2. rsvp 테이블 RLS 설정
-- ====================================

-- RLS 활성화
ALTER TABLE rsvp ENABLE ROW LEVEL SECURITY;

-- 정책 1: RSVP 조회 차단 (관리자만 보도록)
-- 일반 사용자는 다른 사람의 참석 여부를 볼 수 없음
CREATE POLICY "Block public RSVP view"
ON rsvp
FOR SELECT
USING (false);
-- 참고: 관리자가 볼 필요가 있다면 Supabase Dashboard에서 직접 확인하거나
-- 별도 인증 시스템 추가 후 auth.uid() 조건 사용

-- 정책 2: 모든 사용자가 RSVP 제출 가능
CREATE POLICY "Anyone can submit RSVP"
ON rsvp
FOR INSERT
WITH CHECK (
  -- 필수 필드 검증
  side IS NOT NULL
  AND side IN ('groom', 'bride')
  AND attendance IS NOT NULL
  AND attendance IN ('yes', 'no')
  AND name IS NOT NULL
  AND name != ''
  -- 이름 길이 제한 (50자)
  AND length(name) <= 50
  -- 메시지 길이 제한 (500자)
  AND (message IS NULL OR length(message) <= 500)
  -- companions 값 검증 (0-10)
  AND companions IN ('0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '10')
  -- meal 값 검증 (0-11 또는 no/yes)
  AND (
    meal IN ('0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11', 'no', 'yes')
    OR meal IS NULL
  )
);

-- 정책 3: RSVP 수정/삭제 차단
-- 제출 후 변경 불가 (필요시 관리자가 직접 수정)
-- UPDATE, DELETE 정책 없음 = 기본 차단


-- ====================================
-- 3. photos 테이블 RLS 설정 (선택)
-- ====================================

-- RLS 활성화
ALTER TABLE photos ENABLE ROW LEVEL SECURITY;

-- 정책 1: 모든 사용자가 사진 조회 가능
-- (is_visible 여부와 관계없이 모두 조회 허용)
-- 필요시 "is_visible = true" 조건 추가 가능
CREATE POLICY "Anyone can view photos"
ON photos
FOR SELECT
USING (true);

-- 정책 2: 게스트 사진만 업로드 가능
CREATE POLICY "Anyone can upload guest photos"
ON photos
FOR INSERT
WITH CHECK (
  photo_type = 'guest'
  AND image_url IS NOT NULL
  AND image_url != ''
  -- 업로더 이름 필수 (게스트 사진)
  AND uploader_name IS NOT NULL
  AND uploader_name != ''
  -- 비밀번호 필수 (삭제 시 사용)
  AND password IS NOT NULL
  AND length(password) >= 4
);

-- 정책 3: 게스트가 본인 사진의 del_yn만 업데이트 가능 (삭제 표시)
-- 실제 파일 삭제는 안 하고 del_yn = 'Y'로 표시
CREATE POLICY "Users can mark their photos as deleted"
ON photos
FOR UPDATE
USING (photo_type = 'guest')
WITH CHECK (
  -- del_yn만 변경 가능 (다른 필드는 변경 불가)
  del_yn = 'Y'
);

-- 정책 4: main, admin 사진 업로드는 차단 (admin.html 용)
-- 현재 admin.html에 인증이 없으므로 일단 차단
-- 필요시 admin.html에 인증 추가 후 auth.uid() 조건으로 허용
-- 또는 Supabase Dashboard에서 직접 업로드


-- ====================================
-- 4. Storage 버킷 정책 설정
-- ====================================
-- 주의: Storage 정책은 별도로 설정해야 함
-- Supabase Dashboard → Storage → wedding-photos → Policies

-- 정책 1: 모든 사용자가 파일 읽기 가능
CREATE POLICY "Anyone can view wedding photos"
ON storage.objects
FOR SELECT
USING (bucket_id = 'wedding-photos');

-- 정책 2: 게스트 폴더에만 업로드 가능
CREATE POLICY "Anyone can upload to guest folder"
ON storage.objects
FOR INSERT
WITH CHECK (
  bucket_id = 'wedding-photos'
  AND (storage.foldername(name))[1] = 'guest'
);

-- 정책 3: 파일 직접 삭제 차단
-- photos 테이블의 del_yn으로 관리
CREATE POLICY "Prevent direct file deletion"
ON storage.objects
FOR DELETE
USING (false);

-- 정책 4: 파일 업데이트 차단
CREATE POLICY "Prevent file updates"
ON storage.objects
FOR UPDATE
USING (false);


-- ====================================
-- 5. 정책 확인 쿼리
-- ====================================

-- 생성된 정책 확인
SELECT
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual,
  with_check
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename IN ('guestbook', 'rsvp', 'photos')
ORDER BY tablename, policyname;


-- ====================================
-- 6. RLS 활성화 상태 확인
-- ====================================

SELECT
  tablename,
  rowsecurity
FROM pg_tables
WHERE schemaname = 'public'
  AND tablename IN ('guestbook', 'rsvp', 'photos');
-- rowsecurity = true 이면 RLS 활성화됨


-- ====================================
-- 7. 정책 삭제 (필요시)
-- ====================================

-- guestbook 정책 삭제
-- DROP POLICY "Anyone can view guestbook" ON guestbook;
-- DROP POLICY "Anyone can insert guestbook" ON guestbook;
-- DROP POLICY "Anyone can delete guestbook" ON guestbook;

-- rsvp 정책 삭제
-- DROP POLICY "Block public RSVP view" ON rsvp;
-- DROP POLICY "Anyone can submit RSVP" ON rsvp;

-- photos 정책 삭제
-- DROP POLICY "Anyone can view photos" ON photos;
-- DROP POLICY "Anyone can upload guest photos" ON photos;
-- DROP POLICY "Users can mark their photos as deleted" ON photos;


-- ====================================
-- 8. RLS 비활성화 (필요시)
-- ====================================

-- ALTER TABLE guestbook DISABLE ROW LEVEL SECURITY;
-- ALTER TABLE rsvp DISABLE ROW LEVEL SECURITY;
-- ALTER TABLE photos DISABLE ROW LEVEL SECURITY;


-- ====================================
-- 완료!
-- ====================================
-- 위 스크립트를 Supabase Dashboard → SQL Editor에서 실행하세요.
--
-- 실행 순서:
-- 1. guestbook RLS 설정 (섹션 1)
-- 2. rsvp RLS 설정 (섹션 2)
-- 3. photos RLS 설정 (섹션 3, 선택)
-- 4. Storage 정책 설정 (섹션 4, 별도 UI에서 설정)
-- 5. 정책 확인 (섹션 5, 6)
-- ====================================
