-- SocietyOS multi-tenant foundation for Supabase
-- Run in Supabase SQL Editor. RLS ensures users only access their own society.
create extension if not exists pgcrypto;

create table if not exists public.societies (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  slug text not null unique,
  city text,
  portal_type text not null default 'Housing Society',
  created_at timestamptz not null default now()
);

create table if not exists public.society_members (
  user_id uuid not null references auth.users(id) on delete cascade,
  society_id uuid not null references public.societies(id) on delete cascade,
  role text not null default 'admin' check (role in ('admin','staff','viewer')),
  created_at timestamptz not null default now(),
  primary key (user_id, society_id)
);

create table if not exists public.plots (
  id uuid primary key default gen_random_uuid(),
  society_id uuid not null references public.societies(id) on delete cascade,
  plot_number text not null,
  size text not null,
  price numeric(14,2) not null default 0 check (price >= 0),
  status text not null default 'Available' check (status in ('Available','Booked','Reserved')),
  customer_name text,
  created_at timestamptz not null default now(),
  unique (society_id, plot_number)
);

create table if not exists public.customers (
  id uuid primary key default gen_random_uuid(),
  society_id uuid not null references public.societies(id) on delete cascade,
  full_name text not null,
  phone text,
  national_id text,
  plot_id uuid references public.plots(id) on delete set null,
  created_at timestamptz not null default now()
);

create table if not exists public.payments (
  id uuid primary key default gen_random_uuid(),
  society_id uuid not null references public.societies(id) on delete cascade,
  customer_id uuid references public.customers(id) on delete set null,
  plot_id uuid references public.plots(id) on delete set null,
  amount numeric(14,2) not null check (amount > 0),
  paid_on date not null default current_date,
  note text,
  created_at timestamptz not null default now()
);

create index if not exists society_members_society_idx on public.society_members(society_id);
create index if not exists plots_society_idx on public.plots(society_id);
create index if not exists customers_society_idx on public.customers(society_id);
create index if not exists payments_society_idx on public.payments(society_id);

alter table public.societies enable row level security;
alter table public.society_members enable row level security;
alter table public.plots enable row level security;
alter table public.customers enable row level security;
alter table public.payments enable row level security;

-- SECURITY DEFINER helper avoids recursive RLS checks on society_members.
create or replace function public.is_society_member(target_society uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $
  select exists (
    select 1 from public.society_members m
    where m.society_id = target_society and m.user_id = auth.uid()
  );
$;

revoke all on function public.is_society_member(uuid) from public;
grant execute on function public.is_society_member(uuid) to authenticated;

-- Membership is the tenant boundary: a user only sees data for societies they belong to.
drop policy if exists "members can view their societies" on public.societies;
create policy "members can view their societies" on public.societies
for select to authenticated using (public.is_society_member(id));

drop policy if exists "members can view society membership" on public.society_members;
create policy "members can view society membership" on public.society_members
for select to authenticated using (public.is_society_member(society_id));

drop policy if exists "members can manage plots" on public.plots;
create policy "members can manage plots" on public.plots
for all to authenticated using (
  exists (select 1 from public.society_members m where m.society_id = plots.society_id and m.user_id = auth.uid() and m.role in ('admin','staff'))
) with check (
  exists (select 1 from public.society_members m where m.society_id = plots.society_id and m.user_id = auth.uid() and m.role in ('admin','staff'))
);

drop policy if exists "members can manage customers" on public.customers;
create policy "members can manage customers" on public.customers
for all to authenticated using (
  exists (select 1 from public.society_members m where m.society_id = customers.society_id and m.user_id = auth.uid() and m.role in ('admin','staff'))
) with check (
  exists (select 1 from public.society_members m where m.society_id = customers.society_id and m.user_id = auth.uid() and m.role in ('admin','staff'))
);

drop policy if exists "members can manage payments" on public.payments;
create policy "members can manage payments" on public.payments
for all to authenticated using (
  exists (select 1 from public.society_members m where m.society_id = payments.society_id and m.user_id = auth.uid() and m.role in ('admin','staff'))
) with check (
  exists (select 1 from public.society_members m where m.society_id = payments.society_id and m.user_id = auth.uid() and m.role in ('admin','staff'))
);

-- Important: create society + first membership through a trusted admin process.
-- Never expose a service_role key in browser code. Do not let users self-assign society membership.
