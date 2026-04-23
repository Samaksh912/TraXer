-- TraXer initial production schema for Supabase
create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text,
  display_name text,
  photo_url text,
  provider_ids text[] not null default '{}',
  last_login_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.expenses (
  id bigserial primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  uuid text not null,
  title text not null,
  amount double precision not null,
  category text not null,
  type text not null check (type in ('expense', 'income')),
  created_at timestamptz not null,
  updated_at timestamptz not null,
  is_synced boolean not null default true,
  is_deleted boolean not null default false,
  unique (user_id, uuid)
);

create index if not exists expenses_user_id_idx on public.expenses (user_id);
create index if not exists expenses_user_updated_idx on public.expenses (user_id, updated_at desc);
create index if not exists expenses_user_deleted_idx on public.expenses (user_id, is_deleted);

alter table public.profiles enable row level security;
alter table public.expenses enable row level security;

create policy "profiles_select_own"
  on public.profiles
  for select
  to authenticated
  using (auth.uid() = id);

create policy "profiles_upsert_own"
  on public.profiles
  for insert
  to authenticated
  with check (auth.uid() = id);

create policy "profiles_update_own"
  on public.profiles
  for update
  to authenticated
  using (auth.uid() = id)
  with check (auth.uid() = id);

create policy "expenses_select_own"
  on public.expenses
  for select
  to authenticated
  using (auth.uid() = user_id);

create policy "expenses_insert_own"
  on public.expenses
  for insert
  to authenticated
  with check (auth.uid() = user_id);

create policy "expenses_update_own"
  on public.expenses
  for update
  to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "expenses_delete_own"
  on public.expenses
  for delete
  to authenticated
  using (auth.uid() = user_id);

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists profiles_set_updated_at on public.profiles;
create trigger profiles_set_updated_at
before update on public.profiles
for each row
execute function public.set_updated_at();

