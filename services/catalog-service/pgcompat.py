"""
Lightweight sqlite3-compatible wrapper around psycopg2. Lets the rest of
app.py keep using `conn.execute("... ? ...", params)` and `row["column"]`
exactly as it did with sqlite3 — only this file and the CREATE TABLE
statements needed to change for the Postgres migration.

Connection info comes from DATABASE_URL if set, otherwise from the
individual DB_HOST / DB_PORT / DB_NAME / DB_USER / DB_PASSWORD env vars.
Never hardcode the RDS endpoint or credentials here.
"""
import os
import psycopg2
import psycopg2.extras


def _build_dsn():
    database_url = os.environ.get("DATABASE_URL")
    if database_url:
        return database_url
    host = os.environ.get("DB_HOST", "localhost")
    port = os.environ.get("DB_PORT", "5432")
    name = os.environ.get("DB_NAME", "capstone")
    user = os.environ.get("DB_USER", "capstone_admin")
    password = os.environ.get("DB_PASSWORD", "")
    return f"host={host} port={port} dbname={name} user={user} password={password}"


class _Cursor:
    """Wraps a psycopg2 cursor so callers can still do .fetchone()/.fetchall()
    the same way they did with sqlite3."""

    def __init__(self, cursor):
        self._cursor = cursor

    def fetchone(self):
        return self._cursor.fetchone()

    def fetchall(self):
        return self._cursor.fetchall()


class PGConnection:
    """Wraps a psycopg2 connection so `conn.execute(...)` works directly,
    matching sqlite3.Connection's convenience shortcut, and rows come back
    dict-like (row["column"]) via RealDictCursor."""

    def __init__(self):
        self._conn = psycopg2.connect(_build_dsn())

    def execute(self, query, params=None):
        cur = self._conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)
        cur.execute(query.replace("?", "%s"), params or ())
        return _Cursor(cur)

    def executemany(self, query, seq_of_params):
        cur = self._conn.cursor()
        cur.executemany(query.replace("?", "%s"), seq_of_params)
        return _Cursor(cur)

    def commit(self):
        self._conn.commit()

    def close(self):
        self._conn.close()
