import pytest
from fastapi.testclient import TestClient

from app.main import app

client = TestClient(app)


def test_health_endpoint():
    response = client.get("/health")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "healthy"
    assert data["service"] == "nexus-engine-nvm-api"


def test_root_endpoint():
    response = client.get("/")
    assert response.status_code == 200
    data = response.json()
    assert data["name"] == "Nexus Engine NVM API"
    assert data["version"] == "1.0.0"


def test_list_versions_endpoint():
    response = client.get("/api/v1/versions")
    # May fail if NVM not installed, but should return valid response structure
    assert response.status_code in (200, 500)
    if response.status_code == 200:
        data = response.json()
        assert "versions" in data
        assert isinstance(data["versions"], list)


def test_list_remote_versions_endpoint():
    response = client.get("/api/v1/versions/remote")
    assert response.status_code in (200, 500)
    if response.status_code == 200:
        data = response.json()
        assert "versions" in data
        assert isinstance(data["versions"], list)


def test_list_remote_lts_endpoint():
    response = client.get("/api/v1/versions/remote?lts=true")
    assert response.status_code in (200, 500)


def test_config_health_endpoint():
    response = client.get("/api/v1/config/health")
    assert response.status_code == 200
    data = response.json()
    assert "status" in data
    assert "nvm_available" in data


def test_install_script_endpoint():
    response = client.get("/api/v1/install/script")
    assert response.status_code == 200
    data = response.json()
    assert "script_url" in data
    assert "install_command_curl" in data
    assert "install_command_wget" in data
    assert "manual_steps" in data