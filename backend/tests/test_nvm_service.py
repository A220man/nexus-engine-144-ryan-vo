import pytest
from unittest.mock import Mock, patch, MagicMock, AsyncMock
import subprocess

from app.services.nvm_service import NVMService
from app.models.schemas import NodeVersion, VersionStatus, ConfigFileResponse


class TestNVMService:
    @pytest.fixture
    def service(self):
        return NVMService(nvm_dir="/fake/nvm")

    def test_is_available_true(self, service):
        with patch.object(service, '_run_nvm', return_value=(0, "1.0.0", "")):
            assert service.is_available() is True

    def test_is_available_false(self, service):
        with patch.object(service, '_run_nvm', return_value=(1, "", "Not found")):
            assert service.is_available() is False

    def test_get_version(self, service):
        with patch.object(service, '_run_nvm', return_value=(0, "Nexus Engine NVM v1.0.0\n", "")):
            version = service.get_version()
            assert version == "Nexus Engine NVM v1.0.0"

    def test_list_installed(self, service):
        mock_output = "-> v20.10.0\n   v18.17.0\n"
        with patch.object(service, '_run_nvm', return_value=(0, mock_output, "")):
            versions = service.list_installed()
            assert len(versions) == 2
            assert versions[0].version == "v20.10.0"
            assert versions[0].is_current is True
            assert versions[1].version == "v18.17.0"
            assert versions[1].is_current is False

    def test_list_remote(self, service):
        mock_output = "v20.10.0\nv18.17.0\nv16.20.0\n"
        with patch.object(service, '_run_nvm', return_value=(0, mock_output, "")):
            versions = service.list_remote()
            assert len(versions) == 3
            assert all(v.status == VersionStatus.AVAILABLE for v in versions)

    def test_install_success(self, service):
        with patch.object(service, '_run_nvm', return_value=(0, "Installing Node v20.10.0...", "")):
            success, message, output = service.install("20.10.0")
            assert success is True
            assert "successful" in message.lower()

    def test_install_failure(self, service):
        with patch.object(service, '_run_nvm', return_value=(1, "", "Version not found")):
            success, message, output = service.install("99.99.99")
            assert success is False
            assert "failed" in message.lower()

    def test_use_success(self, service):
        with patch.object(service, '_run_nvm', return_value=(0, "Now using node v20.10.0", "")):
            success, message, output = service.use("20.10.0")
            assert success is True

    def test_current(self, service):
        with patch.object(service, '_run_nvm', return_value=(0, "v20.10.0", "")):
            current = service.current()
            assert current == "v20.10.0"

    def test_get_config_files_nvmrc(self, service, tmp_path):
        nvmrc = tmp_path / ".nvmrc"
        nvmrc.write_text("20.10.0")
        result = service.get_config_files(str(tmp_path))
        assert result.nvmrc == "20.10.0"
        assert result.detected_version == "20.10.0"

    def test_get_config_files_node_version(self, service, tmp_path):
        node_version = tmp_path / ".node-version"
        node_version.write_text("v18.17.0")
        result = service.get_config_files(str(tmp_path))
        assert result.node_version == "v18.17.0"
        assert result.detected_version == "v18.17.0"

    def test_get_config_files_package_json(self, service, tmp_path):
        package_json = tmp_path / "package.json"
        package_json.write_text('{"engines": {"node": ">=20.0.0"}}')
        result = service.get_config_files(str(tmp_path))
        assert result.package_json == ">=20.0.0"
        assert result.detected_version == ">=20.0.0"

    def test_get_config_files_precedence(self, service, tmp_path):
        """Test that .nvmrc takes precedence over .node-version and package.json"""
        nvmrc = tmp_path / ".nvmrc"
        nvmrc.write_text("18.17.0")
        node_version = tmp_path / ".node-version"
        node_version.write_text("20.10.0")
        package_json = tmp_path / "package.json"
        package_json.write_text('{"engines": {"node": "16.20.0"}}')
        result = service.get_config_files(str(tmp_path))
        assert result.detected_version == "18.17.0"
        assert result.nvmrc == "18.17.0"
        assert result.node_version == "20.10.0"
        assert result.package_json == "16.20.0"