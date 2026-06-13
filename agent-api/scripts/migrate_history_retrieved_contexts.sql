-- DDL: agrega columna retrieved_contexts a history
-- Ejecutar en la base de datos PostgreSQL del proyecto

ALTER TABLE history
ADD COLUMN IF NOT EXISTS retrieved_contexts JSONB;
