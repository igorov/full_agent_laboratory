'use client'

import { useState } from 'react'
import ReactMarkdown from 'react-markdown'
import remarkGfm from 'remark-gfm'
import type { HistoryItem, ErrorType } from '../_lib/api-client'
import FeedbackModal from './FeedbackModal'

interface ChatMessageProps {
  item: HistoryItem
  showFeedback: boolean
  rating: boolean | null
  errorTypes: ErrorType[]
  onFeedback: (traceId: string, isOk: boolean, errorTypeId?: number, observations?: string) => Promise<void>
}

export default function ChatMessage({ item, showFeedback, rating, errorTypes, onFeedback }: ChatMessageProps) {
  const [modalOpen, setModalOpen] = useState(false)
  const [submitting, setSubmitting] = useState(false)
  const isRated = rating !== null

  async function handleLike() {
    if (isRated || submitting) return
    setSubmitting(true)
    try {
      await onFeedback(item.trace_id, true)
    } finally {
      setSubmitting(false)
    }
  }

  return (
    <div className="flex flex-col gap-2">
      {/* Pregunta del usuario */}
      <div className="flex justify-end">
        <div className="max-w-[75%] rounded-2xl rounded-tr-sm bg-zinc-100 px-4 py-2.5 text-sm text-zinc-900">
          {item.question}
        </div>
      </div>

      {/* Respuesta del agente */}
      <div className="flex justify-start">
        <div className="max-w-[75%] rounded-2xl rounded-tl-sm border border-zinc-200 bg-white px-4 py-2.5 text-sm text-zinc-800">
          {item.answer
            ? <div className="prose prose-sm prose-zinc max-w-none">
                <ReactMarkdown remarkPlugins={[remarkGfm]}>{item.answer}</ReactMarkdown>
              </div>
            : <p className="text-zinc-400">Pensando…</p>
          }

          {showFeedback && (
            <div className="mt-2 flex gap-1 border-t border-zinc-100 pt-2">
              <button
                aria-label="Respuesta correcta"
                onClick={handleLike}
                disabled={isRated || submitting}
                className={`rounded-lg p-1.5 transition-colors disabled:cursor-not-allowed ${
                  rating === true
                    ? 'text-green-500'
                    : rating === false
                      ? 'text-zinc-200'
                      : 'text-zinc-400 hover:bg-zinc-100 hover:text-zinc-600'
                }`}
              >
                <svg xmlns="http://www.w3.org/2000/svg" width="15" height="15" viewBox="0 0 24 24" fill={rating === true ? 'currentColor' : 'none'} stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                  <path d="M7 10v12" />
                  <path d="M15 5.88 14 10h5.83a2 2 0 0 1 1.92 2.56l-2.33 8A2 2 0 0 1 17.5 22H4a2 2 0 0 1-2-2v-8a2 2 0 0 1 2-2h2.76a2 2 0 0 0 1.79-1.11L12 2a3.13 3.13 0 0 1 3 3.88Z" />
                </svg>
              </button>
              <button
                aria-label="Respuesta incorrecta"
                onClick={() => !isRated && !submitting && setModalOpen(true)}
                disabled={isRated || submitting}
                className={`rounded-lg p-1.5 transition-colors disabled:cursor-not-allowed ${
                  rating === false
                    ? 'text-red-500'
                    : rating === true
                      ? 'text-zinc-200'
                      : 'text-zinc-400 hover:bg-zinc-100 hover:text-zinc-600'
                }`}
              >
                <svg xmlns="http://www.w3.org/2000/svg" width="15" height="15" viewBox="0 0 24 24" fill={rating === false ? 'currentColor' : 'none'} stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                  <path d="M17 14V2" />
                  <path d="M9 18.12 10 14H4.17a2 2 0 0 1-1.92-2.56l2.33-8A2 2 0 0 1 6.5 2H20a2 2 0 0 1 2 2v8a2 2 0 0 1-2 2h-2.76a2 2 0 0 0-1.79 1.11L12 22a3.13 3.13 0 0 1-3-3.88Z" />
                </svg>
              </button>
            </div>
          )}
        </div>
      </div>

      {modalOpen && (
        <FeedbackModal
          traceId={item.trace_id}
          errorTypes={errorTypes}
          onSubmit={(errorTypeId, observations) =>
            onFeedback(item.trace_id, false, errorTypeId, observations)
          }
          onClose={() => setModalOpen(false)}
        />
      )}
    </div>
  )
}
