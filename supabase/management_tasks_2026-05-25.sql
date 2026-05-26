update public.management_tasks
set
  title = 'Reunión con Tania Hutt — jue 28 may',
  owner = 'Mauricio / Pablo',
  detail = 'Expansión a empresas: revisar mineras, B2B outreach, oferta empresas y próximos pasos con Tania.',
  sort_order = 90,
  is_done = false
where title in (
  'Hablar con Tania Hutt sobre expansión a mineras',
  '📅 Reunión con Tania Hutt — finales de mayo'
);

insert into public.management_tasks (section_key, title, owner, detail, link_url, sort_order, is_done)
select *
from (
  values
    ('captacion', 'Segundo taller: validar si hay demanda', 'Equipo', 'Sondear demanda para una segunda edición antes de fijar fecha: lista de espera, referidos, LinkedIn, respuestas del formulario y conversaciones directas.', null, 60, false),
    ('captacion', 'Decidir publicidad para segunda edición', 'Equipo', 'Evaluar si conviene pauta pagada u orgánica; definir canal, presupuesto y criterio mínimo de demanda.', null, 61, false),
    ('captacion', 'Mandar sondeo a la base para medir interés', 'Equipo', 'Mensaje corto a la base de datos para estimar demanda real por una segunda edición.', 'https://docs.google.com/spreadsheets/d/1uwnpSX7iGTc7N5UcYVjIIVHYudL-ERsdCGSq-T2OJI0/edit', 62, false),
    ('modulos', 'Evaluar Taller 1 al cierre de todos los módulos', 'Equipo', 'Mandar encuesta de evaluación cuando estén dictados todos los módulos. Medir cada módulo, formato, ritmo, utilidad y mejoras para una segunda edición.', null, 90, false),
    ('expansion', 'Preparar reunión con Tania: plan empresas', 'Pablo / Mauricio', 'Llevar hipótesis de demanda B2B, brochure, lista de empresas/mineras y preguntas para validar el siguiente paso.', null, 91, false),
    ('operacion', 'Subir grabaciones y archivos de práctica faltantes', null, 'Slides de clases 1 a 4 ya quedan en el hub. Faltan grabaciones de clases 3 y 4, workflow/archivos de práctica y encuesta final.', '#admin-section', 110, false)
) as seed(section_key, title, owner, detail, link_url, sort_order, is_done)
where not exists (
  select 1
  from public.management_tasks
  where management_tasks.title = seed.title
);

update public.management_tasks
set
  title = 'Subir grabaciones y archivos de práctica faltantes',
  detail = 'Slides de clases 1 a 4 ya quedan en el hub. Faltan grabaciones de clases 3 y 4, workflow/archivos de práctica y encuesta final.'
where title = 'Empezar a subir contenido a la página';

update public.management_tasks
set
  title = 'Confirmar accesos de los 8 pagados',
  detail = 'Revisar que las 8 personas pagadas tengan invitación aceptada o acceso activo al hub.'
where title = 'Hacer seguimiento a quienes ya pagaron';

delete from public.management_tasks
where title in (
  'Actualizar emails y WhatsApp con estados reales',
  'Revisar WhatsApp real o exportar chat del taller'
);
