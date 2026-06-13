# US-04 — Calificación de una respuesta (Feedback)

**Como** usuario autenticado,  
**quiero** calificar las respuestas del agente como correctas o incorrectas,  
**para** contribuir a la mejora del sistema.

## Criterios de aceptación

1. Cada respuesta del agente muestra dos acciones de calificación: **👍 (like / correcto)** y **👎 (dislike / incorrecto)**.

2. **Caso: calificación correcta (👍)**
   - El frontend llama al API con `is_ok: true`:
     ```
     POST /api/feedback
     ```
     ```json
     {
       "trace_id": "123e4567-e89b-12d3-a456-426614174000",
       "is_ok": true
     }
     ```
   - Si el API responde `200`, los botones de calificación se deshabilitan o se ocultan para esa respuesta. **No se muestra ningún popup.**

3. **Caso: calificación incorrecta (👎)**
   - Al hacer clic en 👎, se abre un **popup/modal** con los siguientes elementos:
     - **Combobox "Tipo de error"**: se puebla con los valores obtenidos de:
       ```
       GET /api/errors
       ```
       Respuesta esperada:
       ```json
       [
         { "id": 1, "description": "Respuesta incorrecta" },
         { "id": 2, "description": "Respuesta irrelevante" }
       ]
       ```
       El combobox muestra el campo `description` y su valor asociado es `id`.
     - **Campo de texto "Observaciones"**: campo libre para que el usuario describa el problema.
     - **Botón "Enviar calificación"**: al hacer clic, envía:
       ```json
       {
         "trace_id": "123e4567-e89b-12d3-a456-426614174000",
         "is_ok": false,
         "error_type_id": 1,
         "observations": "La respuesta no fue relevante para mi consulta."
       }
       ```
     - **Botón "Cancelar"**: cierra el popup sin enviar nada.
   - Si el API responde `200`, el popup se cierra y los botones de calificación se deshabilitan o se ocultan.
   - Si el API responde `404`, mostrar un mensaje indicando que la respuesta ya no está disponible.

4. Los errores de tipo (`/api/errors`) pueden cargarse una sola vez al iniciar la aplicación y mantenerse en memoria/estado global para no repetir la llamada.

## APIs involucradas

| Método | Endpoint | Descripción |
|--------|----------|-------------|
| `GET` | `/api/errors` | Obtiene el catálogo de tipos de error |
| `POST` | `/api/feedback` | Envía la calificación de una respuesta |

## Notas de implementación

- El `trace_id` proviene de la respuesta del `POST /api/chat` (US-03) y debe estar disponible en el estado del mensaje correspondiente.
- El catálogo `/api/errors` se recomienda cargar al iniciar la app (no en cada apertura del modal) para minimizar llamadas al API.
- Precondición: US-03 ya debe estar implementada (los mensajes deben tener `trace_id` disponible).
