insert into public.profiles (id, email, full_name, is_paid, is_admin)
select
  u.id,
  u.email,
  coalesce(u.raw_user_meta_data->>'full_name', ''),
  false,
  true
from auth.users as u
where lower(u.email) = lower('lucia.argote@dobleachile.cl')
on conflict (id) do update
set
  email = excluded.email,
  full_name = case
    when public.profiles.full_name is null or public.profiles.full_name = '' then excluded.full_name
    else public.profiles.full_name
  end,
  is_admin = true;

select id, email, is_admin
from public.profiles
where lower(email) = lower('lucia.argote@dobleachile.cl');
