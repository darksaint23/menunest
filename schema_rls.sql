
-- =====================================================
-- MENUNEST: ROW LEVEL SECURITY POLICIES
-- Supabase / PostgreSQL
-- =====================================================

-- Ensure RLS is enabled.
alter table public.restaurants enable row level security;
alter table public.dishes enable row level security;
alter table public.orders enable row level security;
alter table public.order_items enable row level security;

-- =====================================================
-- 1. RESTAURANTS
-- =====================================================

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
with check (
    owner_id = (select auth.uid())
    and status = 'pending'
);

drop policy if exists "Owners update own restaurants"
on public.restaurants;

create policy "Owners update own restaurants"
on public.restaurants
for update
to authenticated
using (
    owner_id = (select auth.uid())
)
with check (
    owner_id = (select auth.uid())
    and status = 'pending'
);

drop policy if exists "Owners delete own restaurants"
on public.restaurants;

create policy "Owners delete own restaurants"
on public.restaurants
for delete
to authenticated
using (
    owner_id = (select auth.uid())
);

-- =====================================================
-- 2. DISHES
-- =====================================================

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

-- =====================================================
-- 3. ORDERS
-- =====================================================

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

drop policy if exists "Customers view own orders"
on public.orders;

create policy "Customers view own orders"
on public.orders
for select
to authenticated
using (
    customer_id = (select auth.uid())
);

-- =====================================================
-- 4. ORDER ITEMS
-- =====================================================

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
-- END OF MENUNEST RLS POLICIES
-- =====================================================
