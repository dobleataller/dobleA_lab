# Cómo activar el hub de alumnas/os + chat

Tres pasos. ~5 minutos.

---

## 1) Correr la migración SQL en Supabase

1. Entra a supabase.com → **dobleataller's Project** → menú lateral izquierdo → **SQL Editor**
2. Click en **"New query"**
3. Abre el archivo `supabase/paid_emails_and_chat.sql` (en esta misma carpeta), copia todo el contenido
4. Pégalo en el editor SQL de Supabase → **Run** (abajo a la derecha)
5. Debería decir *"Success. No rows returned"*. Si da error, pásame el mensaje.

Qué hace:
- Crea la tabla `paid_emails` con los 6 correos pagados
- Crea la tabla `mensajes` (chat) con permisos (solo pagados + admins pueden leer/escribir; solo admins borran)
- Activa realtime en `mensajes`

---

## 2) Terminar de invitar a los 6 (cuando pase el rate limit)

Ya invitaste 2. Faltan 4. Cuando Supabase te deje de nuevo:
- **Authentication → Users → Add user → Send invitation**
- Uno por uno:
  - cristobal.castro2@mail.udp.cl
  - francisca.acevedo@uc.cl
  - melanieballesterospalma@gmail.com
  - macarena.zuazua@ekhos.cl
  - patricio.alarcon@mail.udp.cl
  - cristian.carreno@nyu.edu

(Los que ya invitaste pueden aceptar y entrar cuando quieran — el SQL del paso 1 ya los tiene en la whitelist.)

---

## 3) Probarlo

Abre `index.html` (la página pública) → click en **"Acceder"** → entra con tu correo admin (p.argotetironi@gmail.com). Como eres admin, te redirige a `dashboard.html` como antes.

Para probar la **vista de alumno**:
- Opción A: invita tu propio correo personal desde Supabase, añádelo manualmente a `paid_emails`:
  ```sql
  insert into public.paid_emails (email, nombre) values ('tu-otro-correo@gmail.com', 'Pablo test');
  ```
- Opción B: cuando alguna de las 2 que ya invitaste complete el registro, pídele que entre y cuéntenos qué ve.

**Lo que verá un alumno pagado al entrar:**
- Header "Hola, {nombre}" + intro
- Tab **"Material del taller"**: 4 clases con sus 3 módulos (50 min cada uno), fechas reales, placeholder *"Material próximamente"* (vamos a subir slides/videos/datos ahí después)
- Tab **"Chat"**: mensajes en tiempo real — puede escribir preguntas, sugerir temas, etc. Tú ves sus mensajes marcados como alumna/o y los tuyos como **"Equipo"**.

---

## Qué sigue (pendiente, lo hacemos después)

- Subir material real a cada módulo (slides, videos, bases de datos) — requiere crear el storage bucket y los botones de upload para admins
- Notificación por email cuando llega un mensaje nuevo al chat (si lo quieres)
- Personalizar el correo de invitación de Supabase (Authentication → Emails → Email Templates → "Invite user") para que diga "Taller Doble A" en vez de mensaje genérico en inglés
