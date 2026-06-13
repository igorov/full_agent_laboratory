-- DDL: tabla ragas_evaluations
-- Ejecutar en la base de datos PostgreSQL del proyecto

CREATE TABLE IF NOT EXISTS ragas_evaluations (
    id                VARCHAR         PRIMARY KEY,
    trace_ids         JSONB           NOT NULL,
    metrics           JSONB           NOT NULL,
    llm_judge         VARCHAR         NOT NULL DEFAULT 'gpt-4o-mini',
    langsmith_run_url VARCHAR,
    evaluated_at      TIMESTAMP       NOT NULL DEFAULT NOW()
);

-- Índice para consultas por fecha
CREATE INDEX IF NOT EXISTS ix_ragas_evaluations_evaluated_at
    ON ragas_evaluations (evaluated_at DESC);
