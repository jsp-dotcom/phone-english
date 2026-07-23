-- Daily Phone English — Supabase 초기 설정
-- Supabase 대시보드 → SQL Editor 에 붙여넣고 [Run] 한 번 실행하세요.

-- 1) 학습 진도 테이블
create table if not exists public.progress (
  device_id   uuid        primary key,
  xp          integer     not null default 0,
  streak      integer     not null default 0,
  last_day    date,
  lessons     jsonb       not null default '{}'::jsonb,
  updated_at  timestamptz not null default now()
);

-- 2) updated_at 자동 갱신
create or replace function public.touch_updated_at()
returns trigger language plpgsql as $$
begin new.updated_at = now(); return new; end $$;

drop trigger if exists trg_progress_touch on public.progress;
create trigger trg_progress_touch
  before update on public.progress
  for each row execute function public.touch_updated_at();

-- 3) RLS 활성화
alter table public.progress enable row level security;

-- 4) 정책: 로그인 없는 기기ID 기반 앱이므로 anon(publishable) 키에 읽기/쓰기 허용
--    ※ 보안 주의: 이 정책은 anon 키로 모든 행을 읽고 쓸 수 있게 합니다.
--      저장되는 값은 XP/연속일/완료레슨 뿐이라 민감정보는 없지만,
--      제대로 된 사용자별 보호가 필요하면 아래 "인증 버전" 주석을 참고하세요.
drop policy if exists "anon_select" on public.progress;
drop policy if exists "anon_insert" on public.progress;
drop policy if exists "anon_update" on public.progress;

create policy "anon_select" on public.progress for select using (true);
create policy "anon_insert" on public.progress for insert with check (true);
create policy "anon_update" on public.progress for update using (true) with check (true);

-- ─────────────────────────────────────────────────────────────
-- (선택) 인증 버전: Supabase Anonymous 로그인 + auth.uid() 기반 보호
--   1. Dashboard → Authentication → Providers → "Anonymous sign-ins" 활성화
--   2. progress.device_id 대신 user_id uuid 컬럼(기본값 auth.uid())을 쓰고
--      정책을 using (auth.uid() = user_id) 로 제한하면 각자 자기 행만 접근 가능
-- ─────────────────────────────────────────────────────────────
