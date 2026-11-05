-- Run once in Supabase: SQL Editor -> New query -> paste -> Run.

create table public.profiles (
  user_id      uuid primary key references auth.users(id) on delete cascade,
  slug         text not null unique
               check (slug ~ '^[a-z0-9][a-z0-9-]{2,29}$'
                      and slug not in ('discover','me','new','login','admin','api')),
  data         jsonb not null default '{}'::jsonb check (pg_column_size(data) < 100000),
  interests    text[] not null default '{}' check (cardinality(interests) <= 100),
  discoverable boolean not null default true,   -- flip default to false for opt-in listing
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now()
);
create index profiles_interests_gin on public.profiles using gin (interests);

alter table public.profiles enable row level security;
-- Only the owner can touch the table directly; everyone else goes through the functions below.
create policy "own select" on public.profiles for select to authenticated using (auth.uid() = user_id);
create policy "own insert" on public.profiles for insert to authenticated with check (auth.uid() = user_id);
create policy "own update" on public.profiles for update to authenticated using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "own delete" on public.profiles for delete to authenticated using (auth.uid() = user_id);

-- Fetch one profile by its URL slug (unlisted profiles are reachable only if you know the slug).
create or replace function public.get_profile(p_slug text) returns jsonb
language sql stable security definer set search_path = public as $$
  select jsonb_build_object('slug', slug, 'data', data) from public.profiles where slug = lower(p_slug)
$$;

-- Find listed profiles that share interests with p_interests (empty list = most recent).
create or replace function public.find_similar(p_interests text[], p_limit int default 30)
returns table (slug text, name text, motto text, shared text[], score int)
language sql stable security definer set search_path = public as $$
  select p.slug, p.data->>'name', p.data->>'motto', s.shared, coalesce(cardinality(s.shared), 0)
  from public.profiles p
  cross join lateral (
    select array(select unnest(p.interests) intersect select unnest(coalesce(p_interests, '{}'))) as shared
  ) s
  where p.discoverable
    and p.user_id is distinct from auth.uid()
    and (coalesce(cardinality(p_interests), 0) = 0 or cardinality(s.shared) > 0)
  order by 5 desc, p.updated_at desc
  limit least(coalesce(p_limit, 30), 50)
$$;

revoke all on function public.get_profile(text), public.find_similar(text[], int) from public;
grant execute on function public.get_profile(text), public.find_similar(text[], int) to anon, authenticated;
