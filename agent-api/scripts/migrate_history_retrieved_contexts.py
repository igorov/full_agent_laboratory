"""
Script de migración: agrega la columna retrieved_contexts a la tabla history.

Uso:
    python -m scripts.migrate_history_retrieved_contexts
    # o desde la raíz del proyecto:
    python scripts/migrate_history_retrieved_contexts.py
"""
import os
import sys

from sqlalchemy import text

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from src.repositories import engine


def run_migration() -> None:
    statement = "ALTER TABLE history ADD COLUMN IF NOT EXISTS retrieved_contexts JSONB"
    print("Agregando columna 'retrieved_contexts' en 'history'...")
    with engine.begin() as connection:
        connection.execute(text(statement))
    print("✅ Columna 'retrieved_contexts' creada (o ya existía).")


if __name__ == "__main__":
    run_migration()
