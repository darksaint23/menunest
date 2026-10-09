
-- MENUNEST DATABASE SETUP
-- Run this in the Supabase SQL Editor.

create extension if not exists pgcrypto;

-- 1. RESTAURANTS TABLE
create table if not exists public.restaurants (
    id uuid primary key default gen_random_uuid(),
    owner_id uuid references auth.users(id) on delete cascade,
    name text not null,
    slug text unique,
    description text default '',
    logo_url text,
    status text not null default 'pending'
        check (status in ('pending', 'approved', 'rejected')),
    created_at timestamptz not null default now()
);

-- Add missing columns if the table already exists.
alter table public.restaurants
    add column if not exists owner_id uuid references auth.users(id) on delete cascade;
alter table public.restaurants
    add column if not exists slug text;
alter table public.restaurants
    add column if not exists description text default '';
alter table public.restaurants
    add column if not exists logo_url text;
alter table public.restaurants
    add column if not exists status text default 'pending';
alter table public.restaurants
    add column if not exists created_at timestamptz default now();

create unique index if not exists restaurants_slug_unique
    on public.restaurants (slug)
    where slug is not null;

-- 2. DISHES TABLE
create table if not exists public.dishes (
    id uuid primary key default gen_random_uuid(),
    restaurant_id uuid not null
        references public.restaurants(id) on delete cascade,
    name text not null,
    description text default '',
    price numeric(10,2) not null default 0
        check (price >= 0),
    image_url text,
    category text default 'Other',
    available boolean not null default true,
    created_at timestamptz not null default now()
);

-- Add missing columns if the table already exists.
alter table public.dishes
    add column if not exists restaurant_id uuid
        references public.restaurants(id) on delete cascade;
alter table public.dishes
    add column if not exists description text default '';
alter table public.dishes
    add column if not exists price numeric(10,2) default 0;
alter table public.dishes
    add column if not exists image_url text;
alter table public.dishes
    add column if not exists category text default 'Other';
alter table public.dishes
    add column if not exists available boolean default true;
alter table public.dishes
    add column if not exists created_at timestamptz default now();

-- 3. PERFORMANCE INDEXES
create index if not exists dishes_restaurant_id_idx
    on public.dishes (restaurant_id);

create index if not exists dishes_category_idx
    on public.dishes (category);

-- 4. ENABLE ROW LEVEL SECURITY
alter table public.restaurants enable row level security;
alter table public.dishes enable row level security;

-- 5. REMOVE OLD POLICIES WITH THESE NAMES
drop policy if exists "Public can view approved restaurants"
    on public.restaurants;
drop policy if exists "Owners can create restaurants"
    on public.restaurants;
drop policy if exists "Owners can update restaurants"
    on public.restaurants;
drop policy if exists "Owners can delete restaurants"
    on public.restaurants;

drop policy if exists "Public can view available dishes"
    on public.dishes;
drop policy if exists "Owners can add dishes"
    on public.dishes;
drop policy if exists "Owners can update dishes"
    on public.dishes;
drop policy if exists "Owners can delete dishes"
    on public.dishes;

-- 6. RESTAURANT SECURITY POLICIES

-- Visitors can see approved restaurants.
-- Owners can also see their own restaurants.
create policy "Public can view approved restaurants"
on public.restaurants
for select
to anon, authenticated
using (
    status = 'approved'
    or owner_id = (select auth.uid())
);

-- Signed-in users can register a restaurant under their account.
create policy "Owners can create restaurants"
on public.restaurants
for insert
to authenticated
with check (
    owner_id = (select auth.uid())
);

create policy "Owners can update restaurants"
on public.restaurants
for update
to authenticated
using (owner_id = (select auth.uid()))
with check (owner_id = (select auth.uid()));

create policy "Owners can delete restaurants"
on public.restaurants
for delete
to authenticated
using (owner_id = (select auth.uid()));

-- 7. DISH SECURITY POLICIES

-- Visitors can view available dishes from approved restaurants.
-- Restaurant owners can view all dishes belonging to their restaurants.
create policy "Public can view available dishes"
on public.dishes
for select
to anon, authenticated
using (
    (
        available = true
        and exists (
            select 1
            from public.restaurants r
            where r.id = dishes.restaurant_id
              and r.status = 'approved'
        )
    )
    or exists (
        select 1
        from public.restaurants r
        where r.id = dishes.restaurant_id
          and r.owner_id = (select auth.uid())
    )
);

create policy "Owners can add dishes"
on public.dishes
for insert
to authenticated
with check (
    exists (
        select 1
        from public.restaurants r
        where r.id = dishes.restaurant_id
          and r.owner_id = (select auth.uid())
    )
);

create policy "Owners can update dishes"
on public.dishes
for update
to authenticated
using (
    exists (
        select 1
        from public.restaurants r
        where r.id = dishes.restaurant_id
          and r.owner_id = (select auth.uid())
    )
)
with check (
    exists (
        select 1
        from public.restaurants r
        where r.id = dishes.restaurant_id
          and r.owner_id = (select auth.uid())
    )
);

create policy "Owners can delete dishes"
on public.dishes
for delete
to authenticated
using (
    exists (
        select 1
        from public.restaurants r
        where r.id = dishes.restaurant_id
          and r.owner_id = (select auth.uid())
    )
);

-- SETUP COMPLETE
