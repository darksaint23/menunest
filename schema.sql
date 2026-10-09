
-- =====================================================
-- MENUNEST: DATABASE SCHEMA
-- Supabase / PostgreSQL
-- =====================================================

create extension if not exists pgcrypto;

-- 1. RESTAURANTS
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

-- 2. DISHES
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

-- 3. OPTIONAL: ORDERS
create table if not exists public.orders (
    id uuid primary key default gen_random_uuid(),
    restaurant_id uuid not null
        references public.restaurants(id) on delete cascade,
    customer_id uuid references auth.users(id) on delete set null,
    order_number bigint generated always as identity,
    status text not null default 'pending'
        check (status in (
            'pending',
            'accepted',
            'preparing',
            'ready',
            'completed',
            'cancelled'
        )),
    total_amount numeric(10,2) not null default 0
        check (total_amount >= 0),
    created_at timestamptz not null default now()
);

-- 4. ORDER ITEMS
create table if not exists public.order_items (
    id uuid primary key default gen_random_uuid(),
    order_id uuid not null
        references public.orders(id) on delete cascade,
    dish_id uuid references public.dishes(id) on delete set null,
    dish_name text not null,
    quantity integer not null check (quantity > 0),
    unit_price numeric(10,2) not null check (unit_price >= 0),
    created_at timestamptz not null default now()
);

-- 5. INDEXES
create index if not exists restaurants_owner_id_idx
    on public.restaurants(owner_id);

create index if not exists restaurants_status_idx
    on public.restaurants(status);

create index if not exists dishes_restaurant_id_idx
    on public.dishes(restaurant_id);

create index if not exists orders_restaurant_id_idx
    on public.orders(restaurant_id);

create index if not exists order_items_order_id_idx
    on public.order_items(order_id);

-- 6. ENABLE ROW LEVEL SECURITY
alter table public.restaurants enable row level security;
alter table public.dishes enable row level security;
alter table public.orders enable row level security;
alter table public.order_items enable row level security;

-- 7. RESTAURANT POLICIES
drop policy if exists "Public read approved restaurants"
    on public.restaurants;
create policy "Public read approved restaurants"
on public.restaurants
for select
to anon, authenticated
using (
    status = 'approved'
    or owner_id = (select auth.uid())
);

drop policy if exists "Owners register restaurants"
    on public.restaurants;
create policy "Owners register restaurants"
on public.restaurants
for insert
to authenticated
with check (owner_id = (select auth.uid()));

drop policy if exists "Owners update own restaurants"
    on public.restaurants;
create policy "Owners update own restaurants"
on public.restaurants
for update
to authenticated
using (owner_id = (select auth.uid()))
with check (owner_id = (select auth.uid()));

-- 8. DISH POLICIES
drop policy if exists "Public read available approved dishes"
    on public.dishes;
create policy "Public read available approved dishes"
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

drop policy if exists "Owners insert own dishes"
    on public.dishes;
create policy "Owners insert own dishes"
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

drop policy if exists "Owners update own dishes"
    on public.dishes;
create policy "Owners update own dishes"
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

drop policy if exists "Owners delete own dishes"
    on public.dishes;
create policy "Owners delete own dishes"
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

-- 9. ORDER POLICIES
-- Owners can view orders for their restaurants.
drop policy if exists "Owners view restaurant orders"
    on public.orders;
create policy "Owners view restaurant orders"
on public.orders
for select
to authenticated
using (
    exists (
        select 1
        from public.restaurants r
        where r.id = orders.restaurant_id
          and r.owner_id = (select auth.uid())
    )
);

-- Customers can view their own orders.
drop policy if exists "Customers view own orders"
    on public.orders;
create policy "Customers view own orders"
on public.orders
for select
to authenticated
using (customer_id = (select auth.uid()));

-- Owners can view order items for their restaurants.
drop policy if exists "Owners view restaurant order items"
    on public.order_items;
create policy "Owners view restaurant order items"
on public.order_items
for select
to authenticated
using (
    exists (
        select 1
        from public.orders o
        join public.restaurants r
          on r.id = o.restaurant_id
        where o.id = order_items.order_id
          and r.owner_id = (select auth.uid())
    )
);

-- Customers can view items belonging to their own orders.
drop policy if exists "Customers view own order items"
    on public.order_items;
create policy "Customers view own order items"
on public.order_items
for select
to authenticated
using (
    exists (
        select 1
        from public.orders o
        where o.id = order_items.order_id
          and o.customer_id = (select auth.uid())
    )
);

-- =====================================================
-- SCHEMA CREATED
-- =====================================================
