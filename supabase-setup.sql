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

-- 4) 정책: 회원가입/로그인(Supabase Auth) 기반 — 각 사용자는 '자기 행'만 접근
--    device_id 컬럼에는 로그인 사용자의 auth.uid() 가 저장됩니다.
--    (이전에 만들었던 관대한 anon 정책이 있으면 함께 제거)
drop policy if exists "anon_select" on public.progress;
drop policy if exists "anon_insert" on public.progress;
drop policy if exists "anon_update" on public.progress;
drop policy if exists "own_select" on public.progress;
drop policy if exists "own_insert" on public.progress;
drop policy if exists "own_update" on public.progress;

create policy "own_select" on public.progress for select
  to authenticated using (auth.uid() = device_id);
create policy "own_insert" on public.progress for insert
  to authenticated with check (auth.uid() = device_id);
create policy "own_update" on public.progress for update
  to authenticated using (auth.uid() = device_id) with check (auth.uid() = device_id);

-- 참고
--  · 비로그인(게스트) 사용자는 클라우드에 접근할 수 없고 브라우저 로컬에만 저장됩니다.
--  · 이메일 인증을 끄고 가입 즉시 로그인되게 하려면:
--    Dashboard → Authentication → Sign In / Providers → Email → "Confirm email" 끄기
--  · 이전에 anon 키로 만든 테스트/기기 행은 이제 접근 불가(무해)하며 필요 시 Table Editor에서 삭제하세요.
