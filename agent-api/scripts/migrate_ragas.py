"""
Script de migración: crea la tabla ragas_evaluations en la base de datos.

Uso:
    python -m scripts.migrate_ragas
    # o desde la raíz del proyecto:
    python scripts/migrate_ragas.py
"""
import sys
import os

# Asegura que el módulo src sea importable desde la raíz del proyecto
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from src.repositories import engine
from src.repositories.models.history import Base  # Base compartida
from src.repositories.models.ragas_evaluation import RagasEvaluation  # noqa: F401 — necesario para registrar el modelo


def run_migration():
    print("Creando tabla 'ragas_evaluations'...")
    Base.metadata.create_all(bind=engine, tables=[RagasEvaluation.__table__])
    print("✅ Tabla 'ragas_evaluations' creada (o ya existía).")


if __name__ == "__main__":
    run_migration()
