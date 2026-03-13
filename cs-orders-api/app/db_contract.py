from __future__ import annotations

from dataclasses import dataclass
from typing import Iterable

from sqlalchemy import text
from sqlalchemy.engine import Engine
from flask import current_app

@dataclass(frozen=True)
class RequiredColumn:
    table: str
    column: str

@dataclass(frozen=True)
class RequiredIndex:
    table: str
    index: str

def _table_exists(engine: Engine, table: str, schema: str) -> bool:
    sql = text("""
        SELECT 1
        FROM information_schema.tables
        WHERE table_schema = :schema
          AND table_name = :table
        LIMIT 1
    """)
    with engine.connect() as c:
        return c.execute(sql, {"schema": schema, "table": table}).first() is not None

def _column_exists(engine: Engine, table: str, column: str, schema: str) -> bool:
    sql = text("""
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = :schema
          AND table_name = :table
          AND column_name = :column
        LIMIT 1
    """)
    with engine.connect() as c:
        return c.execute(sql, {"schema": schema, "table": table, "column": column}).first() is not None

def _index_exists(engine: Engine, table: str, index: str, schema: str) -> bool:
    sql = text("""
        SELECT 1
        FROM information_schema.statistics
        WHERE table_schema = :schema
          AND table_name = :table
          AND index_name = :index
        LIMIT 1
    """)
    with engine.connect() as c:
        return c.execute(sql, {"schema": schema, "table": table, "index": index}).first() is not None

def validate_db_contract(
    engine: Engine,
    schema: str,
    required_tables: Iterable[str],
    required_columns: Iterable[RequiredColumn],
    required_indexes: Iterable[RequiredIndex],
) -> None:
    errors: list[str] = []

    for t in required_tables:
        if not _table_exists(engine, t, schema):
            errors.append(f"Missing table: {schema}.{t}")

    for rc in required_columns:
        if not _column_exists(engine, rc.table, rc.column, schema):
            errors.append(f"Missing column: {schema}.{rc.table}.{rc.column}")

    for ri in required_indexes:
        if not _index_exists(engine, ri.table, ri.index, schema):
            errors.append(f"Missing index: {schema}.{ri.table}.{ri.index}")

    if errors:
        # Log then hard fail — safer than running with partial schema
        current_app.logger.error("DB contract validation failed:\n%s", "\n".join(errors))
        raise RuntimeError("Database schema contract mismatch. See logs for details.")
