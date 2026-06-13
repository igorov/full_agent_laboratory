# Verificación integral — Frontend del Agente Conversacional

Este documento define los criterios de verificación end-to-end para confirmar que las cuatro historias de usuario (US-01 a US-04) están correctamente integradas y funcionan como un flujo completo.

## Prerequisitos

- El backend (`agent-api`) está corriendo en `http://localhost:8080`.
- Existe al menos un usuario (`igorov`) con sesiones previas en el backend.
- El frontend está corriendo y accesible en el navegador.

---

## Escenario 1 — Carga inicial con sesiones existentes

**Cubre:** US-01

| # | Paso | Resultado esperado |
|---|------|--------------------|
| 1 | Abrir la aplicación en el navegador | Se realiza `GET /api/sessions/igorov` |
| 2 | Verificar el panel lateral | Se muestra la lista de `session_id` del usuario |
| 3 | Verificar el área de chat | Está vacía, lista para una nueva conversación |
| 4 | Verificar la red (DevTools) | Solo una llamada a `/api/sessions/igorov` y una a `/api/errors` al inicio |

---

## Escenario 2 — Carga inicial sin sesiones

**Cubre:** US-01 (caso borde)

| # | Paso | Resultado esperado |
|---|------|--------------------|
| 1 | Abrir la aplicación con un usuario sin sesiones | Se realiza `GET /api/sessions/{user}` y retorna `sessions: []` |
| 2 | Verificar el panel lateral | No se muestra ninguna lista (o se muestra un estado vacío) |
| 3 | Verificar el área de chat | Está habilitada y lista para recibir la primera pregunta |

---

## Escenario 3 — Visualización del historial de una sesión

**Cubre:** US-02

| # | Paso | Resultado esperado |
|---|------|--------------------|
| 1 | Hacer clic en un `session_id` del panel lateral | Se realiza `GET /api/history/{session_id}` |
| 2 | Verificar el área de chat | Se muestran los pares pregunta/respuesta en orden cronológico |
| 3 | Hacer clic en otra sesión | El historial anterior se reemplaza por el de la nueva sesión |
| 4 | Verificar los botones de calificación | Cada respuesta muestra 👍 y 👎 |

---

## Escenario 4 — Envío de mensaje en nueva conversación

**Cubre:** US-03 (flujo nuevo)

| # | Paso | Resultado esperado |
|---|------|--------------------|
| 1 | Sin sesión activa, escribir una pregunta y enviar | Se realiza `POST /api/chat` sin `session_id` |
| 2 | Verificar el botón de envío durante la espera | Está deshabilitado o muestra un indicador de carga |
| 3 | Recibir la respuesta | El mensaje aparece en el área de chat con la respuesta del agente |
| 4 | Verificar el panel lateral | El nuevo `session_id` aparece en la lista |
| 5 | Enviar un segundo mensaje en la misma sesión | El request incluye el `session_id` generado en el paso 1 |

---

## Escenario 5 — Envío de mensaje en sesión existente

**Cubre:** US-03 (flujo sesión activa)

| # | Paso | Resultado esperado |
|---|------|--------------------|
| 1 | Seleccionar una sesión del panel lateral | Se carga el historial de esa sesión |
| 2 | Escribir una pregunta y enviar | `POST /api/chat` incluye el `session_id` de la sesión activa |
| 3 | Recibir la respuesta | Se agrega al final del historial en el área de chat |

---

## Escenario 6 — Manejo de errores del API de chat

**Cubre:** US-03 (errores)

| # | Paso | Resultado esperado |
|---|------|--------------------|
| 1 | Simular respuesta `422` o `500` del backend | Se muestra un mensaje de error visible al usuario |
| 2 | Verificar el botón de envío | Vuelve a estar habilitado tras el error |

---

## Escenario 7 — Calificación positiva (👍)

**Cubre:** US-04 (like)

| # | Paso | Resultado esperado |
|---|------|--------------------|
| 1 | Recibir una respuesta del agente | La respuesta muestra los botones 👍 y 👎 |
| 2 | Hacer clic en 👍 | Se realiza `POST /api/feedback` con `is_ok: true` y el `trace_id` correcto |
| 3 | Verificar los botones tras la respuesta `200` | Los botones se deshabilitan u ocultan para esa respuesta |
| 4 | Verificar que no se abre ningún popup | No debe aparecer ningún modal |

---

## Escenario 8 — Calificación negativa (👎) con envío exitoso

**Cubre:** US-04 (dislike)

| # | Paso | Resultado esperado |
|---|------|--------------------|
| 1 | Hacer clic en 👎 | Se abre el popup/modal de feedback |
| 2 | Verificar el combobox "Tipo de error" | Muestra las opciones de `GET /api/errors` (solo se llamó una vez al inicio) |
| 3 | Seleccionar un tipo de error y escribir observaciones | Los campos aceptan la entrada |
| 4 | Hacer clic en "Enviar calificación" | `POST /api/feedback` con `is_ok: false`, `error_type_id` y `observations` |
| 5 | Recibir respuesta `200` | El popup se cierra y los botones se deshabilitan u ocultan |

---

## Escenario 9 — Calificación negativa (👎) cancelada

**Cubre:** US-04 (cancelar)

| # | Paso | Resultado esperado |
|---|------|--------------------|
| 1 | Hacer clic en 👎 | Se abre el popup/modal |
| 2 | Hacer clic en "Cancelar" | El popup se cierra sin realizar ninguna llamada al API |
| 3 | Verificar los botones de calificación | Siguen habilitados (no se envió feedback) |

---

## Escenario 10 — Calificación con respuesta `404`

**Cubre:** US-04 (error 404)

| # | Paso | Resultado esperado |
|---|------|--------------------|
| 1 | Abrir el modal de feedback negativo y enviar | El backend retorna `404` |
| 2 | Verificar el popup | Se muestra un mensaje indicando que la respuesta ya no está disponible |

---

## Checklist de llamadas al API

Al finalizar la implementación completa, verificar en DevTools que:

- [ ] `GET /api/sessions/{user}` — se llama una vez al cargar la app
- [ ] `GET /api/errors` — se llama una vez al cargar la app (no por cada modal)
- [ ] `GET /api/history/{session_id}` — se llama al seleccionar cada sesión
- [ ] `POST /api/chat` — se llama al enviar cada mensaje
- [ ] `POST /api/feedback` — se llama solo al confirmar la calificación (no al cancelar)
