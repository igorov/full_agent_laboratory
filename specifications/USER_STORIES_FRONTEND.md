# Historias de Usuario — Frontend del Agente Conversacional

> **Contexto:** El frontend consume una API REST documentada en `openapi.yaml`. El usuario ya está autenticado y su identificador (`user`) está disponible en la sesión del cliente. La URL base del API es `http://localhost:8080`.

---

## US-01 — Vista inicial: sesiones de conversación del usuario

**Como** usuario autenticado,  
**quiero** ver mis sesiones de conversación previas al ingresar a la aplicación,  
**para** retomar una conversación anterior o comenzar una nueva.

### Criterios de aceptación

1. Al cargar la vista principal, el frontend realiza una llamada al API para obtener las sesiones del usuario:
   ```
   GET /api/sessions/{user}
   ```
   Respuesta esperada:
   ```json
   {
     "user": "igorov",
     "sessions": ["550e8400-...", "123e4567-..."]
   }
   ```

2. Si el usuario **no tiene sesiones**, no se muestra ninguna lista, pero el área de chat está habilitada y lista para recibir la primera pregunta.

3. Si el usuario **tiene sesiones**, se muestra la lista de `session_id` en un panel lateral (o equivalente), ordenadas del más reciente al más antiguo (el API ya las entrega en ese orden).

4. Al cargar la vista (con o sin sesiones previas), el área de chat se muestra con el historial **vacío**, como si se fuera a iniciar una nueva conversación.

5. Al hacer **clic en una sesión** de la lista, se carga el historial de esa sesión (ver US-02).

### APIs involucradas

| Método | Endpoint | Descripción |
|--------|----------|-------------|
| `GET` | `/api/sessions/{user}` | Obtiene la lista de `session_id` del usuario autenticado |

---

## US-02 — Visualización del historial de una sesión

**Como** usuario autenticado,  
**quiero** ver los mensajes de una conversación previa al seleccionarla,  
**para** tener contexto de lo que se habló en esa sesión.

### Criterios de aceptación

1. Al hacer clic en un `session_id` del panel lateral, el frontend llama:
   ```
   GET /api/history/{session_id}
   ```
   Respuesta esperada (array):
   ```json
   [
     {
       "question": "¿Cuál es la fecha de hoy?",
       "answer": "Hoy es 25 de mayo de 2026.",
       "trace_id": "123e4567-...",
       "session_id": "550e8400-...",
       "user": "igorov",
       "created_at": "2026-05-25T10:00:00"
     }
   ]
   ```

2. Los mensajes se muestran en el área de chat en orden cronológico (pregunta del usuario / respuesta del agente).

3. Cada par pregunta-respuesta muestra las acciones de calificación (ver US-04), pero **solo para la última respuesta** de la sesión activa, o bien para respuestas que aún no hayan sido calificadas (según criterio de diseño).

4. Al cambiar de sesión, el historial del área de chat se reemplaza con el de la sesión seleccionada.

### APIs involucradas

| Método | Endpoint | Descripción |
|--------|----------|-------------|
| `GET` | `/api/history/{session_id}` | Retorna los mensajes de la sesión ordenados cronológicamente |

---

## US-03 — Envío de mensajes al agente

**Como** usuario autenticado,  
**quiero** enviar preguntas al agente conversacional,  
**para** obtener respuestas en tiempo real.

### Criterios de aceptación

1. El área de chat tiene un campo de texto y un botón de envío.

2. **Nueva conversación** (sin sesión activa): el frontend envía la pregunta **sin `session_id`**; el API generará uno y lo retornará en la respuesta. El frontend debe guardar ese `session_id` para usarlo en los siguientes mensajes de la misma sesión.
   ```
   POST /api/chat
   ```
   Request:
   ```json
   {
     "question": "¿Cuál es la fecha de hoy?",
     "user": "igorov"
   }
   ```

3. **Sesión existente activa** (conversación en curso): el frontend envía la pregunta incluyendo el `session_id` activo.
   ```json
   {
     "question": "¿Y qué hora es?",
     "user": "igorov",
     "session_id": "550e8400-e29b-41d4-a716-446655440000"
   }
   ```

4. La respuesta del API incluye `answer`, `session_id` y `trace_id`:
   ```json
   {
     "user": "igorov",
     "answer": "Hoy es 25 de mayo de 2026.",
     "session_id": "550e8400-e29b-41d4-a716-446655440000",
     "trace_id": "123e4567-e89b-12d3-a456-426614174000"
   }
   ```

5. La respuesta se agrega al área de chat inmediatamente. El `trace_id` debe conservarse en memoria para usarlo en la calificación (US-04).

6. Tras recibir la primera respuesta de una sesión nueva, el panel lateral debe actualizarse para incluir el nuevo `session_id`.

7. Mientras se espera la respuesta, el botón de envío debe estar deshabilitado o mostrar un indicador de carga.

8. Si el API retorna error `422` o `500`, mostrar un mensaje de error al usuario.

### APIs involucradas

| Método | Endpoint | Descripción |
|--------|----------|-------------|
| `POST` | `/api/chat` | Envía la pregunta y recibe la respuesta del agente |

---

## US-04 — Calificación de una respuesta (Feedback)

**Como** usuario autenticado,  
**quiero** calificar las respuestas del agente como correctas o incorrectas,  
**para** contribuir a la mejora del sistema.

### Criterios de aceptación

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

### APIs involucradas

| Método | Endpoint | Descripción |
|--------|----------|-------------|
| `GET` | `/api/errors` | Obtiene el catálogo de tipos de error |
| `POST` | `/api/feedback` | Envía la calificación de una respuesta |

---

## Resumen de APIs y sus contratos

| # | Método | Endpoint | Cuándo se usa |
|---|--------|----------|---------------|
| 1 | `GET` | `/api/sessions/{user}` | Al cargar la vista inicial |
| 2 | `GET` | `/api/history/{session_id}` | Al seleccionar una sesión del panel lateral |
| 3 | `POST` | `/api/chat` | Al enviar una pregunta |
| 4 | `GET` | `/api/errors` | Al abrir el popup de feedback negativo (o al iniciar la app) |
| 5 | `POST` | `/api/feedback` | Al calificar una respuesta |

> Para el detalle completo de schemas de request/response consultar `openapi.yaml`.

---

## Notas de implementación

- El identificador de usuario (`user`) proviene de la sesión de autenticación del frontend; no es ingresado manualmente.
- El `session_id` es un UUID gestionado por el backend. El frontend solo lo almacena y lo reenvía.
- El `trace_id` es por respuesta individual y es el identificador necesario para el feedback.
- El campo `session_id` en `POST /api/chat` es **opcional**; omitirlo es equivalente a iniciar una nueva conversación.
