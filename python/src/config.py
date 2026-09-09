"""
Configuration management for Olist Analytics NLP Pipeline.
Reads settings strictly from environment variables with safe fallbacks.
"""

import os
from dataclasses import dataclass
from urllib.parse import quote_plus


@dataclass(frozen=True)
class DatabaseConfig:
    user: str = os.getenv("OLIST_DB_USER", "root")
    password: str = os.getenv("OLIST_DB_PASSWORD", "")
    host: str = os.getenv("OLIST_DB_HOST", "127.0.0.1")
    port: int = int(os.getenv("OLIST_DB_PORT", "3306"))
    database: str = os.getenv("OLIST_DB_NAME", "olist")

    @property
    def connection_uri(self) -> str:
        safe_pass = quote_plus(self.password)
        return f"mysql+pymysql://{self.user}:{safe_pass}@{self.host}:{self.port}/{self.database}?charset=utf8mb4"


@dataclass(frozen=True)
class ModelConfig:
    model_name: str = "pysentimiento/bertweet-pt-sentiment"
    batch_size: int = 64
    max_length: int = 128
    device: str = "cpu"
