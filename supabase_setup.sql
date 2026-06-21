-- ============================================================
--  LISTA DE COMPRAS WALMART  ·  Setup de Supabase
--  Ejecutá todo este bloque en:  SQL Editor → New query → Run
-- ============================================================

-- 1) TABLA PRINCIPAL ----------------------------------------------------------
create table if not exists public.productos (
  id          uuid primary key default gen_random_uuid(),
  nombre      text        not null,
  cantidad    numeric     not null default 1 check (cantidad > 0),
  unidad      text        not null default 'und',     -- und, kg, lt, paq...
  categoria   text        not null default 'General',
  precio      numeric     not null default 0 check (precio >= 0),
  comprado    boolean     not null default false,
  creado_en   timestamptz not null default now(),
  actualizado_en timestamptz not null default now()
);

-- Índices para ordenar/filtrar rápido
create index if not exists idx_productos_creado   on public.productos (creado_en desc);
create index if not exists idx_productos_comprado on public.productos (comprado);
create index if not exists idx_productos_categoria on public.productos (categoria);

-- 2) AUTO-ACTUALIZAR "actualizado_en" EN CADA UPDATE -------------------------
create or replace function public.set_actualizado_en()
returns trigger language plpgsql as $$
begin
  new.actualizado_en = now();
  return new;
end;
$$;

drop trigger if exists trg_productos_actualizado on public.productos;
create trigger trg_productos_actualizado
  before update on public.productos
  for each row execute function public.set_actualizado_en();

-- 3) ROW LEVEL SECURITY ------------------------------------------------------
-- App personal (vos y Karol) sin login, usando la anon key.
-- Estas políticas dejan leer/escribir a cualquier cliente anónimo.
-- Si más adelante querés candado, agregá auth y cambiá USING/WITH CHECK.
alter table public.productos enable row level security;

drop policy if exists "lectura publica"     on public.productos;
drop policy if exists "insertar publico"     on public.productos;
drop policy if exists "actualizar publico"   on public.productos;
drop policy if exists "eliminar publico"     on public.productos;

create policy "lectura publica"   on public.productos for select using (true);
create policy "insertar publico"  on public.productos for insert with check (true);
create policy "actualizar publico" on public.productos for update using (true) with check (true);
create policy "eliminar publico"  on public.productos for delete using (true);

-- 4) REALTIME (opcional, por si querés sincronizar entre dispositivos) -------
alter publication supabase_realtime add table public.productos;

-- 5) DATOS DE EJEMPLO (opcional, borralos cuando quieras) --------------------
insert into public.productos (nombre, cantidad, unidad, categoria, precio) values
  ('Leche Dos Pinos',      2, 'lt',  'Lácteos',     1450),
  ('Pan cuadrado Bimbo',   1, 'und', 'Panadería',   1290),
  ('Huevos',               1, 'paq', 'Lácteos',     2200),
  ('Arroz Tío Pelón',      1, 'kg',  'Abarrotes',   1100),
  ('Detergente',           1, 'und', 'Limpieza',    3500);
