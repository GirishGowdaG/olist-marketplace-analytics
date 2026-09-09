"""
Database connection manager and helper utilities.
"""

from contextlib import contextmanager
from sqlalchemy import create_engine
from sqlalchemy.engine import Engine
from python.src.config import DatabaseConfig


class DatabaseManager:
    def __init__(self, config: DatabaseConfig = None):
        self.config = config or DatabaseConfig()
        self._engine: Engine = create_engine(
            self.config.connection_uri,
            pool_pre_ping=True,
            pool_recycle=3600,
        )

    @property
    def engine(self) -> Engine:
        return self._engine

    @contextmanager
    def connect(self):
        connection = self._engine.connect()
        try:
            yield connection
        finally:
            connection.close()
