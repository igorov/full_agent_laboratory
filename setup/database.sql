DROP TABLE IF EXISTS error_types;
CREATE TABLE error_types (
    id          SERIAL,
    description VARCHAR(40) NOT NULL,
    CONSTRAINT pk_error_types PRIMARY KEY (id)
);

INSERT INTO error_types(description)
VALUES('Sin respuesta a la pregunta'),
('Se inventó la respuesta'),
('Respuesta incompleta');

DROP TABLE IF EXISTS history;
CREATE TABLE history (
    trace_id    UUID      NOT NULL,
    session_id  UUID      NOT NULL,
    question    TEXT      NOT NULL,
    answer      TEXT      NOT NULL,
    "user"            VARCHAR(255),
    input_tokens    INTEGER,
    output_tokens   INTEGER,
    created_at      TIMESTAMP    NOT NULL DEFAULT NOW(),
    is_ok           BOOLEAN,
    error_type_id   INTEGER,
    observations    TEXT,
    retrieved_contexts JSONB,
    CONSTRAINT pk_history PRIMARY KEY (trace_id),
    CONSTRAINT fk_history_error_type
        FOREIGN KEY (error_type_id) REFERENCES error_types(id)
);
CREATE INDEX ix_history_session_id ON history (session_id);

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

