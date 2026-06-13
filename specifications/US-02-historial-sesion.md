# US-02 — Visualización del historial de una sesión

**Como** usuario autenticado,  
**quiero** ver los mensajes de una conversación previa al seleccionarla,  
**para** tener contexto de lo que se habló en esa sesión.

## Criterios de aceptación

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

## APIs involucradas

| Método | Endpoint | Descripción |
|--------|----------|-------------|
| `GET` | `/api/history/{session_id}` | Retorna los mensajes de la sesión ordenados cronológicamente |

## Notas de implementación

- El `trace_id` de cada mensaje debe conservarse en el estado del componente para habilitarlo en el feedback (US-04).
- El área de chat debe hacer scroll al último mensaje luego de cargar el historial.
- Precondición: US-01 ya debe estar implementada (panel lateral con lista de sesiones).
