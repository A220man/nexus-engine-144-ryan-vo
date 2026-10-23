import pytest
import sys
import os

# Add backend to path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))


@pytest.fixture(autouse=True)
def mock_env(monkeypatch):
    """Mock environment variables for tests."""
    monkeypatch.setenv("NVM_DIR", "/tmp/test_nvm")
    monkeypatch.setenv("NVM_NODEJS_ORG_MIRROR", "https://nodejs.org/dist")
    monkeypatch.setenv("NVM_IOJS_ORG_MIRROR", "https://iojs.org/dist")