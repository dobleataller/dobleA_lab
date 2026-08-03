-- ============================================================
-- Doble A Lab — unifica el acceso del hub con public.profiles
-- ============================================================
-- Ejecutar una vez en Supabase -> SQL Editor.
-- profiles.is_paid / profiles.is_admin son la fuente de verdad.
-- paid_emails se conserva como compatibilidad con Taller 1.

create or replace function public.has_taller_access()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select
    exists (
      select 1
      from public.profiles p
      where p.id = auth.uid()
        and (p.is_paid = true or p.is_admin = true)
    )
    or exists (
      select 1
      from public.paid_emails pe
      where pe.email = lower(coalesce(auth.jwt() ->> 'email', ''))
    )
    or lower(coalesce(auth.jwt() ->> 'email', '')) in (
      'p.argotetironi@gmail.com',
      'pablo.argote@dobleachile.cl',
      'lucia.argote@dobleachile.cl',
      'isidora.aninat@dobleachile.cl',
      'mauricio.bucca@dobleachile.cl',
      'mpaz.carreno@dobleachile.cl'
    );
$$;

create or replace function public.has_taller_admin_access()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select
    exists (
      select 1
      from public.profiles p
      where p.id = auth.uid()
        and p.is_admin = true
    )
    or lower(coalesce(auth.jwt() ->> 'email', '')) in (
      'p.argotetironi@gmail.com',
      'pablo.argote@dobleachile.cl',
      'lucia.argote@dobleachile.cl',
      'isidora.aninat@dobleachile.cl',
      'mauricio.bucca@dobleachile.cl',
      'mpaz.carreno@dobleachile.cl'
    );
$$;

revoke all on function public.has_taller_access() from public;
revoke all on function public.has_taller_admin_access() from public;
grant execute on function public.has_taller_access() to authenticated;
grant execute on function public.has_taller_admin_access() to authenticated;

drop policy if exists "read mensajes paid or admin" on public.mensajes;
create policy "read mensajes paid or admin"
  on public.mensajes for select
  to authenticated
  using (public.has_taller_access());

drop policy if exists "insert mensajes paid or admin" on public.mensajes;
create policy "insert mensajes paid or admin"
  on public.mensajes for insert
  to authenticated
  with check (user_id = auth.uid() and public.has_taller_access());

drop policy if exists "delete mensajes admin" on public.mensajes;
create policy "delete mensajes admin"
  on public.mensajes for delete
  to authenticated
  using (public.has_taller_admin_access());

drop policy if exists "read materiales paid or admin" on public.materiales;
create policy "read materiales paid or admin"
  on public.materiales for select
  to authenticated
  using (public.has_taller_access());

drop policy if exists "write materiales admin" on public.materiales;
create policy "write materiales admin"
  on public.materiales for all
  to authenticated
  using (public.has_taller_admin_access())
  with check (public.has_taller_admin_access());

drop policy if exists "read materiales bucket" on storage.objects;
create policy "read materiales bucket"
  on storage.objects for select
  to authenticated
  using (bucket_id = 'materiales' and public.has_taller_access());

drop policy if exists "write materiales bucket" on storage.objects;
create policy "write materiales bucket"
  on storage.objects for all
  to authenticated
  using (bucket_id = 'materiales' and public.has_taller_admin_access())
  with check (bucket_id = 'materiales' and public.has_taller_admin_access());

-- Concede admin a cualquiera de las dos cuentas de Pablo si ya existe.
update public.profiles
set is_admin = true
where lower(email) in (
  'p.argotetironi@gmail.com',
  'pablo.argote@dobleachile.cl'
);

-- Cuenta reportada el 3 de agosto de 2026: habilitar acceso pagado.
insert into public.profiles (id, email, full_name, is_paid, is_admin)
select
  u.id,
  u.email,
  coalesce(u.raw_user_meta_data ->> 'full_name', ''),
  true,
  false
from auth.users u
where u.id = '051909a5-c725-467a-a3a8-dc499cb522a9'
on conflict (id) do update
set
  email = excluded.email,
  full_name = case
    when public.profiles.full_name is null or public.profiles.full_name = ''
      then excluded.full_name
    else public.profiles.full_name
  end,
  is_paid = true;
