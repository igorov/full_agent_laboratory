# Plan de implementación — US-01: Vista inicial con sesiones

> **Proyecto:** agent-app (Next.js 16, App Router, TypeScript, Tailwind v4)  
> **Contexto:** Aplicación nueva generada con `create-next-app`. Autenticación vía Google Cloud Identity Platform (email/contraseña). Todas las rutas requieren autenticación.

---

## Decisiones de arquitectura

### Next.js 16: `proxy.ts` en lugar de `middleware.ts`
En Next.js 16, `middleware` está deprecated y renombrado a `proxy`. El archivo de guardia de rutas se llama `proxy.ts` en la raíz del proyecto y exporta la función `proxy` (no `middleware`).

### Firebase JS SDK para Identity Platform
Google Cloud Identity Platform es compatible con el SDK de Firebase Authentication. Se usa `firebase/auth` en el cliente para el flujo de email/contraseña. El SDK genera un **ID token JWT** que se usa como Bearer token en todos los llamados al API.

### Estrategia de protección de rutas
- **`proxy.ts`** verifica la existencia de una cookie de sesión (`session-token`). Si no existe, redirige a `/login`.  
- Tras el login exitoso, el cliente escribe esa cookie con el ID token de Firebase.  
- El cliente también mantiene el token en memoria (React Context) para incluirlo en cada llamada al API backend.

### Usuario para el API
El identificador `user` que se envía al API backend es el **email** del usuario autenticado en Firebase (extraído del objeto `User.email`).

---

## Estructura de archivos resultante

```
agent-app/
├── proxy.ts                          ← guardia de rutas (nuevo)
├── .env.local                        ← variables de Firebase (nuevo)
├── app/
│   ├── layout.tsx                    ← modifica: envolver con AuthProvider
│   ├── page.tsx                      ← modifica: vista principal (US-01)
│   ├── login/
│   │   └── page.tsx                  ← nuevo: formulario de login
│   └── _lib/
│       ├── firebase.ts               ← nuevo: inicialización Firebase
│       ├── auth-context.tsx          ← nuevo: AuthContext + AuthProvider
│       └── api-client.ts             ← nuevo: fetch con Bearer token
```

---

## Paso 1 — Instalar dependencias

```bash
npm install firebase
```

Sin dependencias adicionales: el SDK de Firebase cubre Identity Platform y no se necesita ninguna librería de auth de terceros.

---

## Paso 2 — Variables de entorno (`.env.local`)

```env
NEXT_PUBLIC_FIREBASE_API_KEY=...
NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN=...
NEXT_PUBLIC_FIREBASE_PROJECT_ID=...
```

Solo se necesitan estas tres variables para el flujo de email/contraseña con Identity Platform. Todas llevan el prefijo `NEXT_PUBLIC_` porque se usan únicamente en el cliente.

---

## Paso 3 — Inicialización de Firebase (`app/_lib/firebase.ts`)

Inicializa la app Firebase y exporta la instancia de `Auth`. Este módulo se importa desde el contexto de autenticación.

**Puntos clave:**
- Usar `getApps().length === 0` para evitar doble inicialización en desarrollo con hot-reload.
- Exportar `auth` (instancia de `Auth`) como singleton.

---

## Paso 4 — Contexto de autenticación (`app/_lib/auth-context.tsx`)

`'use client'` — Client Component.

**Estado que expone el contexto:**
```ts
interface AuthContextValue {
  user: User | null        // objeto User de Firebase, null si no está autenticado
  token: string | null     // ID token JWT actual, null si no está autenticado
  loading: boolean         // true mientras Firebase verifica la sesión al iniciar
  signIn: (email: string, password: string) => Promise<void>
  signOut: () => Promise<void>
}
```

**Comportamiento:**
1. Suscripción a `onAuthStateChanged` al montar. Mientras resuelve, `loading = true`.
2. Cuando el usuario está autenticado: llamar `user.getIdToken()` para obtener el token fresco y guardarlo en estado.
3. Tras login exitoso: escribir cookie `session-token=<token>; path=/; SameSite=Strict` para que `proxy.ts` pueda detectar la sesión.
4. Tras logout: borrar la cookie y limpiar el estado.
5. El token en la cookie solo sirve para que `proxy.ts` redirija al usuario no autenticado — la verificación real ocurre en el cliente con Firebase SDK.

---

## Paso 5 — Guardia de rutas (`proxy.ts`)

Archivo en la raíz del proyecto (mismo nivel que `package.json`).

```ts
import { NextResponse } from 'next/server'
import type { NextRequest } from 'next/server'

export function proxy(request: NextRequest) {
  const session = request.cookies.get('session-token')
  const { pathname } = request.nextUrl

  if (!session && pathname !== '/login') {
    return NextResponse.redirect(new URL('/login', request.url))
  }

  if (session && pathname === '/login') {
    return NextResponse.redirect(new URL('/', request.url))
  }

  return NextResponse.next()
}

export const config = {
  matcher: ['/((?!_next/static|_next/image|favicon.ico).*)'],
}
```

**Reglas:**
- Sin cookie → redirige a `/login` (excepto si ya está en `/login`).
- Con cookie y en `/login` → redirige a `/` (evita ver el login si ya está autenticado).
- Excluye archivos estáticos del matcher.

---

## Paso 6 — Layout raíz (`app/layout.tsx`)

Envolver `{children}` con `<AuthProvider>` para que el contexto esté disponible en toda la app.

```tsx
// app/layout.tsx
import { AuthProvider } from './_lib/auth-context'

export default function RootLayout({ children }) {
  return (
    <html lang="es" ...>
      <body ...>
        <AuthProvider>{children}</AuthProvider>
      </body>
    </html>
  )
}
```

---

## Paso 7 — Página de login (`app/login/page.tsx`)

`'use client'` — Client Component.

**Elementos:**
- Campo `email` (type="email")
- Campo `password` (type="password")
- Botón "Ingresar"
- Mensaje de error si `signIn` falla (credenciales incorrectas, usuario no existe, etc.)
- Estado de carga mientras el login procesa (botón deshabilitado)

**Flujo:**
1. El usuario llena el formulario y hace submit.
2. Se llama a `signIn(email, password)` del contexto.
3. Si falla, se muestra el error.
4. Si tiene éxito, `onAuthStateChanged` en el contexto detecta el nuevo usuario, escribe la cookie y el componente se redirige a `/` (via `router.push('/')` o el `proxy.ts` lo redirige en el siguiente request).

---

## Paso 8 — Cliente de API (`app/_lib/api-client.ts`)

Módulo utilitario que centraliza todos los llamados al backend.

```ts
const API_BASE = 'http://localhost:8080'

async function apiFetch(path: string, token: string, options?: RequestInit) {
  const res = await fetch(`${API_BASE}${path}`, {
    ...options,
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${token}`,
      ...options?.headers,
    },
  })
  if (!res.ok) throw new Error(`API error ${res.status}`)
  return res.json()
}

export function getSessions(user: string, token: string) {
  return apiFetch(`/api/sessions/${user}`, token)
}
```

Este módulo se expandirá en US-02, US-03 y US-04 con los demás endpoints. El token se pasa como parámetro (viene del contexto en el componente que lo llama).

---

## Paso 9 — Vista principal (`app/page.tsx`)

`'use client'` — Client Component.

**Layout:**
```
┌──────────────┬──────────────────────────────────┐
│  Panel       │                                  │
│  lateral     │      Área de chat                │
│              │      (vacía al cargar)            │
│  [session1]  │                                  │
│  [session2]  │                                  │
│  ...         │                                  │
│              │                                  │
│  [Cerrar     │                                  │
│   sesión]    │                                  │
└──────────────┴──────────────────────────────────┘
```

**Comportamiento al montar:**
1. Leer `user` y `token` del `AuthContext`.
2. Llamar `getSessions(user.email, token)`.
3. Mientras carga: mostrar indicador en el panel lateral.
4. Si la respuesta trae `sessions: []`: panel vacío, chat habilitado.
5. Si trae sesiones: listar los `session_id` en el panel.
6. El área de chat se muestra siempre vacía al cargar (la sesión activa es `null`).

**Estado local del componente:**
```ts
const [sessions, setSessions] = useState<string[]>([])
const [loadingSessions, setLoadingSessions] = useState(true)
const [activeSession, setActiveSession] = useState<string | null>(null)
```

**Componentes internos (pueden colocarse en el mismo archivo o en `_components/`):**
- `SessionPanel`: recibe la lista de `session_id` y el callback `onSelectSession`.
- `ChatArea`: recibe la `activeSession` (para US-02 y US-03, en US-01 siempre está vacía).

El clic en una sesión del panel llama a `setActiveSession(sessionId)` — la lógica de cargar el historial (US-02) se implementará después.

---

## Orden de implementación recomendado

| # | Tarea | Archivo(s) |
|---|-------|-----------|
| 1 | Instalar Firebase SDK | `package.json` |
| 2 | Crear `.env.local` con credenciales de Identity Platform | `.env.local` |
| 3 | Inicializar Firebase | `app/_lib/firebase.ts` |
| 4 | Crear AuthContext y AuthProvider | `app/_lib/auth-context.tsx` |
| 5 | Crear proxy.ts | `proxy.ts` |
| 6 | Actualizar layout raíz con AuthProvider | `app/layout.tsx` |
| 7 | Crear página de login | `app/login/page.tsx` |
| 8 | Crear api-client con `getSessions` | `app/_lib/api-client.ts` |
| 9 | Implementar vista principal (page.tsx) | `app/page.tsx` |

---

## Verificación de esta historia

Usar `VERIFICACION-frontend.md` → Escenario 1 y Escenario 2.

Pasos mínimos de verificación manual:
1. Abrir la app sin cookie → debe redirigir a `/login`.
2. Ingresar con credenciales válidas → redirige a `/`.
3. DevTools → Network: se llama `GET /api/sessions/igorov` con header `Authorization: Bearer <token>`.
4. El panel lateral muestra las sesiones (o está vacío si no hay ninguna).
5. El área de chat está vacía.
6. Cerrar sesión → cookie eliminada → `proxy.ts` redirige a `/login`.
