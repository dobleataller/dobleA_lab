-- ============================================================
-- Doble A Lab — whitelist de alumnos pagados + chat del taller
-- ============================================================
-- Ejecutar en Supabase → SQL Editor → pegar todo → Run.
-- Idempotente: se puede correr varias veces sin romper nada.
-- ------------------------------------------------------------

-- ───── 1. Whitelist de correos pagados ──────────────────────
create table if not exists public.paid_emails (
  email      text primary key,
  nombre     text,
  nivel      text,
  created_at timestamptz not null default now()
);

insert into public.paid_emails (email, nombre, nivel) values
  ('cristobal.castro2@mail.udp.cl',       'Cristóbal Castro Baeza',     'Intermedio'),
  ('francisca.acevedo@uc.cl',             'Francisca Acevedo',          'Intermedio'),
  ('melanieballesterospalma@gmail.com',   'Melanie Ballesteros Palma',  'Básico'),
  ('czurob@uc.cl',                        'Carola Zurob',               null),
  ('macarena.zuazua@ekhos.cl',            'Macarena Zuazua',            'Intermedio'),
  ('patricio.alarcon@mail.udp.cl',        'Patricio Alarcón',           'Avanzado'),
  ('cristian.carreno@nyu.edu',            'Cristian Carreño',           null),
  ('francisca.catalina@gmail.com',        'Francisca Perez',            null)
on conflict (email) do update
  set nombre = excluded.nombre,
      nivel  = excluded.nivel;

alter table public.paid_emails enable row level security;

drop policy if exists "read paid_emails auth"        on public.paid_emails;
drop policy if exists "admin write paid_emails"      on public.paid_emails;

-- cualquier usuario autenticado puede leer (necesario para el check cliente)
create policy "read paid_emails auth"
  on public.paid_emails for select
  to authenticated using (true);

-- solo admins escriben
create policy "admin write paid_emails"
  on public.paid_emails for all
  to authenticated
  using (
    lower(coalesce(auth.jwt() ->> 'email','')) in (
      'p.argotetironi@gmail.com',
      'lucia.argote@dobleachile.cl',
      'isidora.aninat@dobleachile.cl',
      'mauricio.bucca@dobleachile.cl',
      'mpaz.carreno@dobleachile.cl'
    )
  )
  with check (
    lower(coalesce(auth.jwt() ->> 'email','')) in (
      'p.argotetironi@gmail.com',
      'lucia.argote@dobleachile.cl',
      'isidora.aninat@dobleachile.cl',
      'mauricio.bucca@dobleachile.cl',
      'mpaz.carreno@dobleachile.cl'
    )
  );


-- ───── 2. Chat del taller ───────────────────────────────────
create table if not exists public.mensajes (
  id         bigserial primary key,
  user_id    uuid references auth.users(id) on delete set null,
  user_email text,
  user_name  text,
  contenido  text not null check (char_length(trim(contenido)) between 1 and 2000),
  created_at timestamptz not null default now()
);

create index if not exists mensajes_created_at_idx on public.mensajes (created_at);

alter table public.mensajes enable row level security;

drop policy if exists "read mensajes paid or admin"   on public.mensajes;
drop policy if exists "insert mensajes paid or admin" on public.mensajes;
drop policy if exists "delete mensajes admin"         on public.mensajes;

-- helper: email del caller normalizado
-- (Supabase expone el email del JWT en auth.jwt()->>'email')

-- leer: pagados + admins
create policy "read mensajes paid or admin"
  on public.mensajes for select
  to authenticated
  using (
    exists (
      select 1 from public.paid_emails pe
      where pe.email = lower(coalesce(auth.jwt() ->> 'email',''))
    )
    or lower(coalesce(auth.jwt() ->> 'email','')) in (
      'p.argotetironi@gmail.com',
      'lucia.argote@dobleachile.cl',
      'isidora.aninat@dobleachile.cl',
      'mauricio.bucca@dobleachile.cl',
      'mpaz.carreno@dobleachile.cl'
    )
  );

-- insertar: pagados + admins, siempre como sí mismos
create policy "insert mensajes paid or admin"
  on public.mensajes for insert
  to authenticated
  with check (
    user_id = auth.uid()
    and (
      exists (
        select 1 from public.paid_emails pe
        where pe.email = lower(coalesce(auth.jwt() ->> 'email',''))
      )
      or lower(coalesce(auth.jwt() ->> 'email','')) in (
        'p.argotetironi@gmail.com',
        'lucia.argote@dobleachile.cl',
        'isidora.aninat@dobleachile.cl',
        'mauricio.bucca@dobleachile.cl'
      )
    )
  );

-- eliminar: solo admins (moderación)
create policy "delete mensajes admin"
  on public.mensajes for delete
  to authenticated
  using (
    lower(coalesce(auth.jwt() ->> 'email','')) in (
      'p.argotetironi@gmail.com',
      'lucia.argote@dobleachile.cl',
      'isidora.aninat@dobleachile.cl',
      'mauricio.bucca@dobleachile.cl',
      'mpaz.carreno@dobleachile.cl'
    )
  );

-- ───── 3. Realtime para chat ────────────────────────────────
-- añadir tabla al publication de realtime (si no estaba ya)
do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'mensajes'
  ) then
    execute 'alter publication supabase_realtime add table public.mensajes';
  end if;
end$$;


-- ───── 4. Materiales del taller ─────────────────────────────
create table if not exists public.materiales (
  id                bigserial primary key,
  clase_num         int  not null check (clase_num  between 1 and 4),
  modulo_num        int  not null check (modulo_num between 1 and 3),
  titulo            text not null,
  descripcion       text,
  tipo              text not null default 'archivo' check (tipo in ('archivo','link','video')),
  storage_path      text,       -- ruta dentro del bucket 'materiales' (cuando tipo='archivo')
  external_url      text,       -- URL externa (cuando tipo='link' o 'video')
  file_size         bigint,
  mime_type         text,
  uploaded_by       uuid references auth.users(id) on delete set null,
  uploaded_by_name  text,
  created_at        timestamptz not null default now()
);

create index if not exists materiales_clase_modulo_idx
  on public.materiales(clase_num, modulo_num, created_at desc);

alter table public.materiales enable row level security;

drop policy if exists "read materiales paid or admin"  on public.materiales;
drop policy if exists "write materiales admin"         on public.materiales;

create policy "read materiales paid or admin"
  on public.materiales for select
  to authenticated
  using (
    exists (
      select 1 from public.paid_emails pe
      where pe.email = lower(coalesce(auth.jwt() ->> 'email',''))
    )
    or lower(coalesce(auth.jwt() ->> 'email','')) in (
      'p.argotetironi@gmail.com',
      'lucia.argote@dobleachile.cl',
      'isidora.aninat@dobleachile.cl',
      'mauricio.bucca@dobleachile.cl',
      'mpaz.carreno@dobleachile.cl'
    )
  );

create policy "write materiales admin"
  on public.materiales for all
  to authenticated
  using (
    lower(coalesce(auth.jwt() ->> 'email','')) in (
      'p.argotetironi@gmail.com',
      'lucia.argote@dobleachile.cl',
      'isidora.aninat@dobleachile.cl',
      'mauricio.bucca@dobleachile.cl',
      'mpaz.carreno@dobleachile.cl'
    )
  )
  with check (
    lower(coalesce(auth.jwt() ->> 'email','')) in (
      'p.argotetironi@gmail.com',
      'lucia.argote@dobleachile.cl',
      'isidora.aninat@dobleachile.cl',
      'mauricio.bucca@dobleachile.cl',
      'mpaz.carreno@dobleachile.cl'
    )
  );

-- realtime
do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'materiales'
  ) then
    execute 'alter publication supabase_realtime add table public.materiales';
  end if;
end$$;


-- ───── 5. Storage bucket 'materiales' (privado) ─────────────
insert into storage.buckets (id, name, public)
values ('materiales', 'materiales', false)
on conflict (id) do nothing;

drop policy if exists "read materiales bucket"  on storage.objects;
drop policy if exists "write materiales bucket" on storage.objects;

-- leer archivos: pagados + admins
create policy "read materiales bucket"
  on storage.objects for select
  to authenticated
  using (
    bucket_id = 'materiales'
    and (
      exists (
        select 1 from public.paid_emails pe
        where pe.email = lower(coalesce(auth.jwt() ->> 'email',''))
      )
      or lower(coalesce(auth.jwt() ->> 'email','')) in (
        'p.argotetironi@gmail.com',
        'lucia.argote@dobleachile.cl',
        'isidora.aninat@dobleachile.cl',
        'mauricio.bucca@dobleachile.cl'
      )
    )
  );

-- subir/editar/eliminar: solo admins
create policy "write materiales bucket"
  on storage.objects for all
  to authenticated
  using (
    bucket_id = 'materiales'
    and lower(coalesce(auth.jwt() ->> 'email','')) in (
      'p.argotetironi@gmail.com',
      'lucia.argote@dobleachile.cl',
      'isidora.aninat@dobleachile.cl',
      'mauricio.bucca@dobleachile.cl',
      'mpaz.carreno@dobleachile.cl'
    )
  )
  with check (
    bucket_id = 'materiales'
    and lower(coalesce(auth.jwt() ->> 'email','')) in (
      'p.argotetironi@gmail.com',
      'lucia.argote@dobleachile.cl',
      'isidora.aninat@dobleachile.cl',
      'mauricio.bucca@dobleachile.cl',
      'mpaz.carreno@dobleachile.cl'
    )
  );
