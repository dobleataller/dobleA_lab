-- Otorga rol admin a Isidora Aninat y Mauricio Bucca.
-- Requiere que ambos hayan creado cuenta primero en el sitio (login con magic link).
-- Re-ejecutable (idempotente via on conflict).

insert into public.profiles (id, email, full_name, is_paid, is_admin)
select
  u.id,
  u.email,
  coalesce(u.raw_user_meta_data->>'full_name', ''),
  false,
  true
from auth.users as u
where lower(u.email) in (
  lower('isidora.aninat@dobleachile.cl'),
  lower('mauricio.bucca@dobleachile.cl')
)
on conflict (id) do update
set
  email = excluded.email,
  full_name = case
    when public.profiles.full_name is null or public.profiles.full_name = '' then excluded.full_name
    else public.profiles.full_name
  end,
  is_admin = true;

-- Verificar
select id, email, is_admin
from public.profiles
where lower(email) in (
  lower('isidora.aninat@dobleachile.cl'),
  lower('mauricio.bucca@dobleachile.cl')
)
order by email;
