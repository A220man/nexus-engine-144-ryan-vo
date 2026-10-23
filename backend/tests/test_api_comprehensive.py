import pytest
from fastapi.testclient import TestClient
from unittest.mock import patch, Mock

from app.main import app
from app.services.nvm_service import nvm_service
from app.models.schemas import NodeVersion, VersionStatus, ListResponse, ConfigFileResponse

client = TestClient(app)


def create_mock_version(version: str, status: VersionStatus, **kwargs) -> Mock:
    """Create a mock that behaves like a NodeVersion."""
    mock = Mock(spec=NodeVersion)
    mock.version = version
    mock.status = status
    mock.is_current = kwargs.get("is_current", False)
    mock.is_default = kwargs.get("is_default", False)
    mock.lts_name = kwargs.get("lts_name")
    return mock


class TestVersionsAPI:
    @patch("app.api.versions.nvm_service.list_installed")
    @patch("app.api.versions.nvm_service.current")
    @patch("app.api.versions.nvm_service._run_nvm")
    def test_list_versions_success(self, mock_run, mock_current, mock_list):
        mock_list.return_value = [
            create_mock_version("v20.10.0", VersionStatus.INSTALLED, is_current=True),
            create_mock_version("v18.17.0", VersionStatus.INSTALLED, is_current=False),
        ]
        mock_current.return_value = "v20.10.0"
        mock_run.return_value = (0, "default -> v18.17.0", "")
        
        response = client.get("/api/v1/versions")
        assert response.status_code == 200
        data = response.json()
        assert "versions" in data
        assert len(data["versions"]) == 2

    @patch("app.api.versions.nvm_service.list_remote")
    def test_list_remote_versions(self, mock_list):
        mock_list.return_value = [
            create_mock_version("v20.10.0", VersionStatus.AVAILABLE),
            create_mock_version("v18.17.0", VersionStatus.AVAILABLE),
        ]
        
        response = client.get("/api/v1/versions/remote")
        assert response.status_code == 200
        data = response.json()
        assert "versions" in data

    @patch("app.api.versions.nvm_service.list_remote")
    def test_list_remote_lts_versions(self, mock_list):
        mock_list.return_value = [
            create_mock_version("v20.10.0", VersionStatus.LTS, lts_name="hydrogen"),
        ]
        
        response = client.get("/api/v1/versions/remote?lts=true")
        assert response.status_code == 200
        data = response.json()
        assert "versions" in data

    @patch("app.api.versions.nvm_service.current")
    def test_get_current_version_success(self, mock_current):
        mock_current.return_value = "v20.10.0"
        
        response = client.get("/api/v1/versions/current")
        assert response.status_code == 200
        data = response.json()
        assert data["version"] == "v20.10.0"

    @patch("app.api.versions.nvm_service.current")
    def test_get_current_version_not_found(self, mock_current):
        mock_current.return_value = None
        
        response = client.get("/api/v1/versions/current")
        assert response.status_code == 404

    @patch("app.api.versions.nvm_service.install")
    def test_install_version_success(self, mock_install):
        mock_install.return_value = (True, "Installation successful", "output")
        
        response = client.post("/api/v1/versions/install", json={"version": "20.10.0"})
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert data["version"] == "20.10.0"

    @patch("app.api.versions.nvm_service.install")
    def test_install_version_failure(self, mock_install):
        mock_install.return_value = (False, "Version not found", "error")
        
        response = client.post("/api/v1/versions/install", json={"version": "99.99.99"})
        assert response.status_code == 400

    @patch("app.api.versions.nvm_service.use")
    @patch("app.api.versions.nvm_service.current")
    def test_use_version_success(self, mock_current, mock_use):
        mock_use.return_value = (True, "Switched", "output")
        mock_current.return_value = "v20.10.0"
        
        response = client.post("/api/v1/versions/use", json={"version": "20.10.0"})
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert data["version"] == "v20.10.0"

    @patch("app.api.versions.nvm_service.use")
    def test_use_version_failure(self, mock_use):
        mock_use.return_value = (False, "Not installed", "error")
        
        response = client.post("/api/v1/versions/use", json={"version": "99.99.99"})
        assert response.status_code == 400

    @patch("app.api.versions.nvm_service.alias_default")
    def test_set_default_version_success(self, mock_alias):
        mock_alias.return_value = (True, "Default version set")
        
        response = client.post("/api/v1/versions/alias/default/20.10.0")
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True

    @patch("app.api.versions.nvm_service.alias_default")
    def test_set_default_version_failure(self, mock_alias):
        mock_alias.return_value = (False, "Failed")
        
        response = client.post("/api/v1/versions/alias/default/99.99.99")
        assert response.status_code == 400

    @patch("app.api.versions.nvm_service.uninstall")
    def test_uninstall_version_success(self, mock_uninstall):
        mock_uninstall.return_value = (True, "Uninstall successful")
        
        response = client.delete("/api/v1/versions/18.17.0")
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True

    @patch("app.api.versions.nvm_service.uninstall")
    def test_uninstall_version_failure(self, mock_uninstall):
        mock_uninstall.return_value = (False, "Failed")
        
        response = client.delete("/api/v1/versions/99.99.99")
        assert response.status_code == 400


class TestConfigAPI:
    @patch("app.api.config.nvm_service.get_config_files")
    def test_detect_config(self, mock_config):
        mock_config.return_value = ConfigFileResponse(
            nvmrc="20.10.0",
            detected_version="20.10.0"
        )
        
        response = client.get("/api/v1/config")
        assert response.status_code == 200
        data = response.json()
        assert data["nvmrc"] == "20.10.0"
        assert data["detected_version"] == "20.10.0"

    @patch("app.api.config.nvm_service.is_available")
    @patch("app.api.config.nvm_service.get_version")
    def test_health_check_available(self, mock_version, mock_available):
        mock_available.return_value = True
        mock_version.return_value = "Nexus Engine NVM v1.0.0"
        
        response = client.get("/api/v1/config/health")
        assert response.status_code == 200
        data = response.json()
        assert data["nvm_available"] is True
        assert data["nvm_version"] == "Nexus Engine NVM v1.0.0"

    @patch("app.api.config.nvm_service.is_available")
    def test_health_check_unavailable(self, mock_available):
        mock_available.return_value = False
        
        response = client.get("/api/v1/config/health")
        assert response.status_code == 200
        data = response.json()
        assert data["nvm_available"] is False


class TestInstallAPI:
    def test_get_install_script(self):
        response = client.get("/api/v1/install/script")
        assert response.status_code == 200
        data = response.json()
        assert "script_url" in data
        assert "install_command_curl" in data
        assert "install_command_wget" in data
        assert "manual_steps" in data