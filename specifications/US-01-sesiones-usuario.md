# US-01 — Vista inicial: sesiones de conversación del usuario

**Como** usuario autenticado,  
**quiero** ver mis sesiones de conversación previas al ingresar a la aplicación,  
**para** retomar una conversación anterior o comenzar una nueva.

## Criterios de aceptación

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

## APIs involucradas

| Método | Endpoint | Descripción |
|--------|----------|-------------|
| `GET` | `/api/sessions/{user}` | Obtiene la lista de `session_id` del usuario autenticado |

## Notas de implementación

- El identificador de usuario (`user`) proviene de la sesión de autenticación del frontend; no es ingresado manualmente.
- Para esta historia, usar `"igorov"` como valor fijo del usuario (hardcodeado en el cliente hasta que exista un sistema de autenticación real).
- El `session_id` es un UUID gestionado por el backend; el frontend solo lo muestra.
