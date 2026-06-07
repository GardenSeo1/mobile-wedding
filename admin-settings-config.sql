-- ====================================
-- 기존 admin_settings 테이블에 설정 추가
-- ====================================
-- Supabase Dashboard → SQL Editor에서 실행
-- admin_settings 테이블이 이미 존재한다고 가정
-- ====================================

-- 1. 기본 설정 데이터 삽입 (admin_settings 테이블 사용)
INSERT INTO admin_settings (setting_key, setting_value) VALUES
('guest_upload_start_date', '2026-10-04T09:00:00+09:00'),
('guest_upload_enabled', 'true')
ON CONFLICT (setting_key)
DO UPDATE SET
    setting_value = EXCLUDED.setting_value,
    updated_at = NOW();

-- 2. RLS 정책 설정 (이미 활성화되어 있을 수 있음)
ALTER TABLE admin_settings ENABLE ROW LEVEL SECURITY;

-- 기존 정책 삭제 (있다면)
DROP POLICY IF EXISTS "Anyone can view admin_settings" ON admin_settings;
DROP POLICY IF EXISTS "Anyone can update guest upload settings" ON admin_settings;

-- 모든 사용자가 설정 읽기 가능
CREATE POLICY "Anyone can view admin_settings"
ON admin_settings
FOR SELECT
USING (true);

-- 게스트 업로드 설정만 업데이트 허용
CREATE POLICY "Anyone can update guest upload settings"
ON admin_settings
FOR UPDATE
USING (
  setting_key IN (
    'guest_upload_start_date',
    'guest_upload_enabled'
  )
)
WITH CHECK (
  setting_key IN (
    'guest_upload_start_date',
    'guest_upload_enabled'
  )
);

-- 3. 설정 확인 쿼리
SELECT * FROM admin_settings
WHERE setting_key IN ('guest_upload_start_date', 'guest_upload_enabled')
ORDER BY setting_key;

-- ====================================
-- 설정값 업데이트 예시
-- ====================================

-- 게스트 업로드 시작일 변경
-- UPDATE admin_settings
-- SET setting_value = '2026-10-04T09:00:00+09:00'
-- WHERE setting_key = 'guest_upload_start_date';

-- 게스트 업로드 활성화/비활성화
-- UPDATE admin_settings
-- SET setting_value = 'false'
-- WHERE setting_key = 'guest_upload_enabled';

-- ====================================
-- 설정 삭제 (필요시)
-- ====================================

-- DELETE FROM admin_settings
-- WHERE setting_key IN ('guest_upload_start_date', 'guest_upload_enabled');
