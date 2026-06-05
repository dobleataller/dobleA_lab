update public.management_tasks
set
  title = 'Validar mensajes separados: Consultores vs Analistas',
  owner = 'Equipo',
  detail = 'Probar dos promesas distintas en LinkedIn, base actual y conversaciones con empresas antes de cerrar fechas.',
  sort_order = 1,
  is_done = false
where title in (
  '3 targets: 1) público universitario, 2) consultores, 3) empresas',
  '3 targets: 1) publico universitario, 2) consultores, 3) empresas'
);

insert into public.management_tasks (section_key, title, owner, detail, link_url, sort_order, is_done)
select *
from (
  values
    ('captacion', 'Definir arquitectura de dos talleres: Consultores + Analistas', 'Pablo / Mauricio', 'Separar públicos, promesa, nivel técnico, precio y canal de captación. Evitar que un solo taller intente hablarle a perfiles demasiado distintos.', null, 1, false),
    ('captacion', 'Taller Consultores: cerrar programa de 3 módulos', 'Equipo', 'Propuesta inicial: 1) diagnóstico y pregunta; 2) diseño/propuesta; 3) storyline ejecutivo y venta de hallazgos.', null, 2, false),
    ('captacion', 'Taller Analistas: analizar diseño con Mauricio', 'Mauricio / Pablo', 'Bajar la línea técnica: workflow reproducible, análisis de datos, modelamiento, interpretación y casos. Definir requisitos de entrada y entregable final.', null, 3, false),
    ('expansion', 'Validar mensajes separados: Consultores vs Analistas', 'Equipo', 'Probar dos promesas distintas en LinkedIn, base actual y conversaciones con empresas antes de cerrar fechas.', null, 1, false),
    ('expansion', 'Conectar B2B con los dos talleres', 'Mauricio / Pablo', 'Empresas puede entrar por una versión ejecutiva para consultores internos o por una línea técnica para analistas. Definir cuál se vende primero.', null, 2, false)
) as seed(section_key, title, owner, detail, link_url, sort_order, is_done)
where not exists (
  select 1
  from public.management_tasks
  where management_tasks.title = seed.title
);
