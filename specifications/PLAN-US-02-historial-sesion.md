# Plan de implementación — US-02: Visualización del historial de una sesión

> **Precondición:** US-01 implementada. `activeSession`, `token` y `useAuth()` ya existen.  
> **Token:** disponible en `useAuth().token` — se pasa como parámetro a `apiFetch`, igual que en `getSessions`.

---

## Qué ya existe y se reutiliza

| Elemento existente | Dónde vive | Rol en US-02 |
|--------------------|-----------|--------------|
| `activeSession: string \| null` | `app/page.tsx` | Dispara la carga del historial cuando cambia |
| `token: string \| null` | `useAuth()` | Bearer token para `GET /api/history/{session_id}` |
| `apiFetch<T>()` | `app/_lib/api-client.ts` | Base para la nueva función `getHistory()` |
| Panel lateral con `setActiveSession` | `app/page.tsx` | El clic en sesión ya cambia `activeSession` — no hay que modificarlo |

---

## Decisiones de diseño

### Cuándo mostrar los botones de feedback
La US-02 dice: *"solo para la última respuesta de la sesión activa, o bien para respuestas que aún no hayan sido calificadas"*. El campo `is_ok` del historial es `null` cuando no fue calificada (`HistoryItem` no incluye `is_ok` en el schema del `GET /api/history`).  

**Criterio adoptado:** mostrar los botones de calificación **únicamente en el último ítem** del historial. La lógica real (envío, deshabilitar al calificar) la implementa US-04. En esta US los botones se renderizan como UI shell con `onClick` vacío — así US-04 solo necesita conectar los handlers.

### Scroll automático
Al terminar de cargar el historial, se hace scroll al último mensaje usando `useRef` sobre un elemento centinela al final del listado. Se ejecuta en un `useEffect` que depende de `history`.

### Separación de componentes
`page.tsx` crece con US-02, US-03 y US-04. Conviene extraer el área de chat a un componente dedicado desde ahora para que cada historia trabaje sobre su propio archivo.

---

## Estructura de archivos resultante

```
app/
├── page.tsx                          ← modifica: añade estado y lógica de historial
├── _lib/
│   └── api-client.ts                 ← modifica: añade HistoryItem + getHistory()
└── _components/
    ├── ChatArea.tsx                  ← nuevo: contenedor del historial + scroll
    └── ChatMessage.tsx               ← nuevo: burbuja de pregunta o respuesta
```

---

## Paso 1 — Agregar `HistoryItem` y `getHistory` a `api-client.ts`

Añadir al final del archivo existente, sin tocar `apiFetch` ni `getSessions`.

```ts
export interface HistoryItem {
  question: string
  answer: string
  trace_id: string
  session_id: string
  user: string | null
  created_at: string
}

export function getHistory(sessionId: string, token: string): Promise<HistoryItem[]> {
  return apiFetch<HistoryItem[]>(`/api/history/${sessionId}`, token)
}
```

`HistoryItem` es la fuente de verdad del tipo — `ChatArea` y `ChatMessage` lo importan desde aquí para no duplicar la definición.

---

## Paso 2 — Nuevo componente `ChatMessage.tsx`

`app/_components/ChatMessage.tsx` — `'use client'`

Renderiza **un par** pregunta/respuesta. Recibe:

```ts
interface ChatMessageProps {
  item: HistoryItem
  showFeedback: boolean       // true solo si es el último item
  // US-04 agregará: onLike, onDislike
}
```

**Layout de cada par:**
```
┌─────────────────────────────────────────────┐
│  [Usuario]  ¿Cuál es la fecha de hoy?        │  ← alineado a la derecha, fondo zinc-100
└─────────────────────────────────────────────┘
┌─────────────────────────────────────────────┐
│  [Agente]   Hoy es 25 de mayo de 2026.       │  ← alineado a la izquierda, fondo white
│                                             │
│             [👍]  [👎]   ← solo si showFeedback │
└─────────────────────────────────────────────┘
```

Los botones 👍 y 👎 solo se renderizan cuando `showFeedback === true`. En esta US no tienen handler — US-04 extenderá las props para conectarlos.

---

## Paso 3 — Nuevo componente `ChatArea.tsx`

`app/_components/ChatArea.tsx` — `'use client'`

Recibe:

```ts
interface ChatAreaProps {
  history: HistoryItem[]
  loading: boolean
  activeSession: string | null
}
```

**Responsabilidades:**
1. Si `loading === true`: mostrar un esqueleto o spinner centrado.
2. Si `loading === false` y `history.length === 0` y `activeSession !== null`: mostrar "Esta sesión no tiene mensajes".
3. Si `loading === false` y `activeSession === null`: mostrar el mensaje de bienvenida ("Seleccioná una conversación o escribí tu primera pregunta.").
4. Mapear `history` a `<ChatMessage>`, pasando `showFeedback={index === history.length - 1}`.
5. Elemento `<div ref={bottomRef} />` al final del listado. `useEffect` sobre `history` llama `bottomRef.current?.scrollIntoView({ behavior: 'smooth' })`.

---

## Paso 4 — Modificar `page.tsx`

### Estado nuevo

```ts
const [history, setHistory] = useState<HistoryItem[]>([])
const [loadingHistory, setLoadingHistory] = useState(false)
```

### `useEffect` para cargar historial

Se dispara cuando `activeSession` cambia. Cuando el usuario elige una sesión diferente, primero limpia el historial anterior (UX: no se ve el historial viejo mientras carga el nuevo).

```ts
useEffect(() => {
  if (!activeSession || !token) {
    setHistory([])
    return
  }

  setLoadingHistory(true)
  setHistory([])

  getHistory(activeSession, token)
    .then((data) => setHistory(data))
    .catch(() => setHistory([]))
    .finally(() => setLoadingHistory(false))
}, [activeSession, token])
```

### Reemplazar el placeholder del área de chat

El bloque `<main>` actualmente tiene un placeholder con `{activeSession ? ... : ...}`. Se reemplaza por:

```tsx
<ChatArea
  history={history}
  loading={loadingHistory}
  activeSession={activeSession}
/>
```

El campo de entrada y el botón "Enviar" se mantienen como están (US-03 los conectará).

---

## Orden de implementación

| # | Tarea | Archivo |
|---|-------|---------|
| 1 | Agregar `HistoryItem` + `getHistory()` | `app/_lib/api-client.ts` |
| 2 | Crear `ChatMessage` | `app/_components/ChatMessage.tsx` |
| 3 | Crear `ChatArea` | `app/_components/ChatArea.tsx` |
| 4 | Agregar estado `history` + `useEffect` + reemplazar placeholder | `app/page.tsx` |

---

## Verificación de esta historia

Usar `VERIFICACION-frontend.md` → Escenario 3.

Pasos mínimos de verificación manual:
1. Ingresar con credenciales válidas.
2. Hacer clic en una sesión del panel lateral.
3. DevTools → Network: se llama `GET /api/history/{session_id}` con `Authorization: Bearer <token>`.
4. El área de chat muestra los pares pregunta/respuesta en orden cronológico.
5. Solo el último par tiene los botones 👍/👎 visibles.
6. El scroll queda posicionado en el último mensaje.
7. Hacer clic en otra sesión: el historial anterior desaparece y se carga el nuevo.
