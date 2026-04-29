"""Database utility library for Robot Framework tests.

Provides a single keyword interface over SQLite, PostgreSQL, MySQL, and MongoDB.
The default mode uses SQLite — no server required.
"""

import json
import os
from typing import Any, Optional, Union

import pymongo
from robot.api.deco import keyword
from robot.libraries.BuiltIn import BuiltIn


class DatabaseUtils:
    """Custom multi-database library for Robot Framework."""

    ROBOT_LIBRARY_SCOPE = "GLOBAL"

    def __init__(self) -> None:
        self.builtin = BuiltIn()
        self.connections: dict[str, dict[str, Any]] = {}

    # ──────────────────────────────────────────────────────────────────────────
    # Connection management
    # ──────────────────────────────────────────────────────────────────────────

    @keyword
    def connect_to_sqlite(
        self, database: str = "results/test.db", alias: str = "default"
    ) -> str:
        """Open a SQLite connection — works anywhere with zero infrastructure.

        The parent directory of *database* is created automatically.
        Uses ``isolation_level=None`` so every write is immediately visible.
        """
        db_dir = os.path.dirname(database)
        if db_dir:
            os.makedirs(db_dir, exist_ok=True)
        try:
            # isolation_level=None → autocommit; required so Query sees writes.
            database_library = self.builtin.get_library_instance("DatabaseLibrary")
            database_library.connect_to_database(
                "sqlite3",
                db_name=database,
                isolation_level=None,
            )
            self.connections[alias] = {"type": "sqlite"}
            return f"Connected to SQLite: {database}"
        except Exception as exc:
            raise RuntimeError(f"Failed to connect to SQLite: {exc}") from exc

    @keyword
    def connect_to_postgresql(
        self,
        host: str,
        port: Union[int, str],
        database: str,
        user: str,
        password: str,
        alias: str = "default",
    ) -> str:
        """Open a PostgreSQL connection via DatabaseLibrary."""
        try:
            self.builtin.run_keyword(
                "Connect To Database", "psycopg2", database, user, password, host, port
            )
            self.connections[alias] = {"type": "postgresql"}
            return f"Connected to PostgreSQL: {database}"
        except Exception as exc:
            raise RuntimeError(f"Failed to connect to PostgreSQL: {exc}") from exc

    @keyword
    def connect_to_mysql(
        self,
        host: str,
        port: Union[int, str],
        database: str,
        user: str,
        password: str,
        alias: str = "default",
    ) -> str:
        """Open a MySQL connection via DatabaseLibrary."""
        try:
            self.builtin.run_keyword(
                "Connect To Database", "pymysql", database, user, password, host, port
            )
            self.connections[alias] = {"type": "mysql"}
            return f"Connected to MySQL: {database}"
        except Exception as exc:
            raise RuntimeError(f"Failed to connect to MySQL: {exc}") from exc

    @keyword
    def connect_to_mongodb(
        self,
        host: str,
        port: Union[int, str],
        database: str,
        user: Optional[str] = None,
        password: Optional[str] = None,
        alias: str = "default",
    ) -> str:
        """Open a MongoDB connection."""
        try:
            uri = (
                f"mongodb://{user}:{password}@{host}:{port}/{database}"
                if user and password
                else f"mongodb://{host}:{port}"
            )
            client: pymongo.MongoClient = pymongo.MongoClient(uri)
            self.connections[alias] = {
                "type": "mongodb",
                "client": client,
                "database": client[database],
            }
            return f"Connected to MongoDB: {database}"
        except Exception as exc:
            raise RuntimeError(f"Failed to connect to MongoDB: {exc}") from exc

    # ──────────────────────────────────────────────────────────────────────────
    # Query execution
    # ──────────────────────────────────────────────────────────────────────────

    @keyword
    def execute_sql_query(self, query: str, alias: str = "default") -> Any:
        """Execute a SQL *query* on the registered connection."""
        self._require_connection(alias)
        if not self._is_sql_connection(alias):
            raise RuntimeError("execute_sql_query requires a SQL connection (sqlite/postgresql/mysql)")
        try:
            keyword_name = "Query" if self._returns_rows(query) else "Execute Sql String"
            return self.builtin.run_keyword(keyword_name, query)
        except Exception as exc:
            raise RuntimeError(f"Query failed: {exc}") from exc

    @keyword
    def execute_mongodb_query(
        self,
        collection_name: str,
        query: Union[dict, str],
        alias: str = "default",
    ) -> list[Any]:
        """Execute a MongoDB *query* against *collection_name*."""
        self._require_connection(alias)
        if self.connections[alias]["type"] != "mongodb":
            raise RuntimeError("execute_mongodb_query requires a MongoDB connection")
        try:
            if isinstance(query, str):
                query = json.loads(query)
            return list(self.connections[alias]["database"][collection_name].find(query))
        except Exception as exc:
            raise RuntimeError(f"MongoDB query failed: {exc}") from exc

    # ──────────────────────────────────────────────────────────────────────────
    # Data management
    # ──────────────────────────────────────────────────────────────────────────

    @keyword
    def insert_test_data(
        self,
        table_name: str,
        data: Union[dict, list],
        alias: str = "default",
    ) -> str:
        """Insert *data* (dict or list of dicts) into *table_name*."""
        self._require_connection(alias)
        conn_type = self._connection_type(alias)
        try:
            if conn_type == "mongodb":
                col = self.connections[alias]["database"][table_name]
                if isinstance(data, list):
                    result = col.insert_many(data)
                    return f"Inserted {len(result.inserted_ids)} documents"
                result = col.insert_one(data)
                return f"Inserted document: {result.inserted_id}"

            if not isinstance(data, dict):
                raise TypeError("SQL insert requires a dict")
            self.builtin.run_keyword(
                "Execute Sql String",
                self._build_insert_statement(table_name, data),
            )
            return f"Inserted 1 row into {table_name}"
        except Exception as exc:
            raise RuntimeError(f"Insert failed: {exc}") from exc

    @keyword
    def cleanup_test_data(
        self,
        table_name: str,
        condition: Union[dict, str],
        alias: str = "default",
    ) -> str:
        """Delete records matching *condition* from *table_name*."""
        self._require_connection(alias)
        conn_type = self._connection_type(alias)
        try:
            if conn_type == "mongodb":
                if isinstance(condition, str):
                    condition = json.loads(condition)
                result = self.connections[alias]["database"][table_name].delete_many(condition)
                return f"Deleted {result.deleted_count} documents"

            self.builtin.run_keyword(
                "Execute Sql String",
                f"DELETE FROM {table_name} WHERE {condition}",
            )
            return f"Deleted rows from {table_name}"
        except Exception as exc:
            raise RuntimeError(f"Cleanup failed: {exc}") from exc

    @keyword
    def verify_database_state(
        self,
        table_name: str,
        expected_count: int,
        condition: Union[dict, str] = "",
        alias: str = "default",
    ) -> str:
        """Assert the number of records in *table_name*, optionally filtered by *condition*."""
        self._require_connection(alias)
        conn_type = self._connection_type(alias)
        try:
            if conn_type == "mongodb":
                query = self._parse_mongodb_condition(condition)
                actual = self.connections[alias]["database"][table_name].count_documents(query)
            else:
                where = f" WHERE {condition}" if condition else ""
                result = self.builtin.run_keyword("Query", f"SELECT COUNT(*) FROM {table_name}{where}")
                actual = result[0][0]

            if actual != int(expected_count):
                raise AssertionError(
                    f"Expected {expected_count} records in '{table_name}', found {actual}"
                )
            return f"Verified {actual} records in '{table_name}'"
        except AssertionError:
            raise
        except Exception as exc:
            raise RuntimeError(f"Verify state failed: {exc}") from exc

    # ──────────────────────────────────────────────────────────────────────────
    # Disconnection
    # ──────────────────────────────────────────────────────────────────────────

    @keyword
    def disconnect_from_database(self, alias: str = "default") -> str:
        """Close the connection registered under *alias*."""
        if alias not in self.connections:
            return f"No connection registered under alias '{alias}'"
        conn_type = self._connection_type(alias)
        try:
            if conn_type == "mongodb":
                self.connections[alias]["client"].close()
            else:
                self.builtin.run_keyword("DatabaseLibrary.Disconnect From Database")
            del self.connections[alias]
            return f"Disconnected from {conn_type}"
        except Exception as exc:
            raise RuntimeError(f"Disconnect failed: {exc}") from exc

    @keyword
    def disconnect_from_all_databases(self) -> str:
        """Close all registered database connections."""
        for alias in list(self.connections):
            self.disconnect_from_database(alias)
        return "Disconnected from all databases"

    # ──────────────────────────────────────────────────────────────────────────
    # Helpers
    # ──────────────────────────────────────────────────────────────────────────

    def _require_connection(self, alias: str) -> None:
        if alias not in self.connections:
            raise RuntimeError(f"No database connection registered under alias '{alias}'")

    def _connection_type(self, alias: str) -> str:
        return str(self.connections[alias]["type"])

    def _is_sql_connection(self, alias: str) -> bool:
        return self._connection_type(alias) in ("sqlite", "postgresql", "mysql")

    def _build_insert_statement(self, table_name: str, data: dict[str, Any]) -> str:
        columns = ", ".join(data.keys())
        values = ", ".join(self._sql_literal(value) for value in data.values())
        return f"INSERT INTO {table_name} ({columns}) VALUES ({values})"

    def _sql_literal(self, value: Any) -> str:
        if value is None:
            return "NULL"
        if isinstance(value, str):
            escaped = value.replace("'", "''")
            return f"'{escaped}'"
        return str(value)

    def _parse_mongodb_condition(self, condition: Union[dict, str]) -> dict[str, Any]:
        if isinstance(condition, str):
            return json.loads(condition) if condition else {}
        return condition or {}

    def _returns_rows(self, query: str) -> bool:
        return query.lstrip().lower().startswith(("select", "show", "pragma", "with"))
