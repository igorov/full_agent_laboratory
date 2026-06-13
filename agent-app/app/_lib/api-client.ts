const API_BASE = process.env.NEXT_PUBLIC_API_BASE ?? 'http://localhost:8080'

async function apiFetch<T>(path: string, token: string, options?: RequestInit): Promise<T> {
  const res = await fetch(`${API_BASE}${path}`, {
    ...options,
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${token}`,
      ...options?.headers,
    },
  })

  if (!res.ok) {
    throw Object.assign(new Error(`API error ${res.status}`), { status: res.status })
  }

  return res.json() as Promise<T>
}

export interface UserSessionsResponse {
  user: string
  sessions: string[]
}

export function getSessions(user: string, token: string): Promise<UserSessionsResponse> {
  return apiFetch<UserSessionsResponse>(`/api/sessions/${user}`, token)
}

export interface HistoryItem {
  question: string
  answer: string
  trace_id: string
  session_id: string
  user: string | null
  created_at: string
  is_ok: boolean | null
}

export function getHistory(sessionId: string, token: string): Promise<HistoryItem[]> {
  return apiFetch<HistoryItem[]>(`/api/history/${sessionId}`, token)
}

export interface ChatRequest {
  question: string
  user: string
  session_id?: string
}

export interface ChatResponse {
  user: string
  answer: string
  session_id: string
  trace_id: string
}

export function sendMessage(request: ChatRequest, token: string): Promise<ChatResponse> {
  return apiFetch<ChatResponse>('/api/chat', token, {
    method: 'POST',
    body: JSON.stringify(request),
  })
}

export interface ErrorType {
  id: number
  description: string
}

export function getErrorTypes(token: string): Promise<ErrorType[]> {
  return apiFetch<ErrorType[]>('/api/errors', token)
}

export interface FeedbackRequest {
  trace_id: string
  is_ok: boolean
  error_type_id?: number
  observations?: string
}

export interface FeedbackResponse {
  trace_id: string
  session_id: string
  question: string
  answer: string
  user: string | null
  created_at: string
  is_ok: boolean | null
  error_type_id: number | null
  observations: string | null
}

export function postFeedback(request: FeedbackRequest, token: string): Promise<FeedbackResponse> {
  return apiFetch<FeedbackResponse>('/api/feedback', token, {
    method: 'POST',
    body: JSON.stringify(request),
  })
}
