import pytest
from pydantic import ValidationError

from app.models.schemas import (
    NodeVersion, VersionStatus, InstallRequest, InstallResponse,
    UseRequest, UseResponse, ListResponse, ConfigFileResponse, HealthResponse
)


class TestNodeVersion:
    def test_valid_version(self):
        version = NodeVersion(version="v20.10.0", status=VersionStatus.INSTALLED)
        assert version.version == "v20.10.0"
        assert version.status == VersionStatus.INSTALLED
        assert version.is_default is False
        assert version.is_current is False

    def test_version_with_all_fields(self):
        version = NodeVersion(
            version="v20.10.0",
            status=VersionStatus.ACTIVE,
            lts_name="hydrogen",
            is_default=True,
            is_current=True,
        )
        assert version.lts_name == "hydrogen"
        assert version.is_default is True
        assert version.is_current is True

    def test_invalid_status(self):
        with pytest.raises(ValidationError):
            NodeVersion(version="v20.10.0", status="invalid")


class TestInstallRequest:
    def test_valid_request(self):
        req = InstallRequest(version="20.10.0")
        assert req.version == "20.10.0"
        assert req.force is False

    def test_request_with_force(self):
        req = InstallRequest(version="20.10.0", force=True)
        assert req.force is True

    def test_missing_version(self):
        with pytest.raises(ValidationError):
            InstallRequest()


class TestInstallResponse:
    def test_success_response(self):
        resp = InstallResponse(success=True, version="v20.10.0", message="OK", output="output")
        assert resp.success is True
        assert resp.version == "v20.10.0"

    def test_failure_response(self):
        resp = InstallResponse(success=False, message="Failed", output="error")
        assert resp.success is False
        assert resp.version is None


class TestUseRequest:
    def test_with_version(self):
        req = UseRequest(version="20.10.0")
        assert req.version == "20.10.0"

    def test_without_version(self):
        req = UseRequest()
        assert req.version is None


class TestUseResponse:
    def test_response(self):
        resp = UseResponse(success=True, version="v20.10.0", message="Switched", output="out")
        assert resp.success is True
        assert resp.version == "v20.10.0"


class TestListResponse:
    def test_empty_list(self):
        resp = ListResponse(versions=[], current=None, default=None)
        assert resp.versions == []
        assert resp.current is None
        assert resp.default is None

    def test_with_versions(self):
        versions = [
            NodeVersion(version="v20.10.0", status=VersionStatus.ACTIVE, is_current=True),
            NodeVersion(version="v18.17.0", status=VersionStatus.INSTALLED, is_default=True),
        ]
        resp = ListResponse(versions=versions, current="v20.10.0", default="v18.17.0")
        assert len(resp.versions) == 2
        assert resp.current == "v20.10.0"
        assert resp.default == "v18.17.0"


class TestConfigFileResponse:
    def test_empty(self):
        resp = ConfigFileResponse()
        assert resp.nvmrc is None
        assert resp.node_version is None
        assert resp.package_json is None
        assert resp.detected_version is None

    def test_with_nvmrc(self):
        resp = ConfigFileResponse(nvmrc="20.10.0", detected_version="20.10.0")
        assert resp.nvmrc == "20.10.0"
        assert resp.detected_version == "20.10.0"

    def test_precedence_order(self):
        """Test that all three config types can be present"""
        resp = ConfigFileResponse(
            nvmrc="18.17.0",
            node_version="20.10.0",
            package_json=">=16.0.0",
            detected_version="18.17.0",  # .nvmrc takes precedence
        )
        assert resp.nvmrc == "18.17.0"
        assert resp.node_version == "20.10.0"
        assert resp.package_json == ">=16.0.0"
        assert resp.detected_version == "18.17.0"


class TestHealthResponse:
    def test_healthy(self):
        resp = HealthResponse(
            status="healthy",
            service="nexus-engine-nvm-api",
            nvm_available=True,
            nvm_version="Nexus Engine NVM v1.0.0",
        )
        assert resp.status == "healthy"
        assert resp.nvm_available is True

    def test_degraded(self):
        resp = HealthResponse(
            status="degraded",
            service="nexus-engine-nvm-api",
            nvm_available=False,
            nvm_version=None,
        )
        assert resp.status == "degraded"
        assert resp.nvm_available is False