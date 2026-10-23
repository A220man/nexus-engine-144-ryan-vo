import pytest
import os
from pathlib import Path

from app.core.config import Settings


class TestSettings:
    def test_default_values(self):
        settings = Settings()
        assert settings.app_name == "Nexus Engine NVM API"
        assert settings.app_version == "1.0.0"
        assert settings.debug is False
        assert "localhost:5173" in str(settings.cors_origins)

    def test_nvm_dir_expansion(self):
        settings = Settings(nvm_dir="~/test_nvm")
        # Settings uses os.path.expanduser internally
        assert "test_nvm" in settings.nvm_dir

    def test_custom_cors_origins(self):
        settings = Settings(cors_origins=["http://custom:3000", "http://another:4000"])
        assert "http://custom:3000" in settings.cors_origins
        assert "http://another:4000" in settings.cors_origins

    def test_env_file_loading(self, tmp_path, monkeypatch):
        env_file = tmp_path / ".env"
        env_file.write_text("DEBUG=true\nAPP_VERSION=2.0.0\n")
        monkeypatch.chdir(tmp_path)
        
        settings = Settings(_env_file=str(env_file))
        assert settings.debug is True
        assert settings.app_version == "2.0.0"