# US-03 — Envío de mensajes al agente

**Como** usuario autenticado,  
**quiero** enviar preguntas al agente conversacional,  
**para** obtener respuestas en tiempo real.

## Criterios de aceptación

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

## APIs involucradas

| Método | Endpoint | Descripción |
|--------|----------|-------------|
| `POST` | `/api/chat` | Envía la pregunta y recibe la respuesta del agente |

## Notas de implementación

- El campo `session_id` en el request es **opcional**; omitirlo equivale a iniciar una nueva conversación.
- El `session_id` retornado en la primera respuesta de una sesión nueva debe almacenarse en el estado del componente y usarse en todos los mensajes subsiguientes de esa sesión.
- El `trace_id` es por respuesta individual y es necesario para el feedback (US-04).
- Precondición: US-01 ya debe estar implementada (panel lateral).
