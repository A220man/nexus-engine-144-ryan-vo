from pydantic import BaseModel, Field
from typing import Optional, List
from enum import Enum


class VersionStatus(str, Enum):
    INSTALLED = "installed"
    ACTIVE = "active"
    AVAILABLE = "available"
    LTS = "lts"


class NodeVersion(BaseModel):
    version: str
    status: VersionStatus = VersionStatus.AVAILABLE
    lts_name: Optional[str] = None
    is_default: bool = False
    is_current: bool = False


class InstallRequest(BaseModel):
    version: str = Field(..., description="Node.js version to install (e.g., '20.10.0', 'lts/hydrogen', '--lts')")
    force: bool = False


class InstallResponse(BaseModel):
    success: bool
    version: Optional[str] = None
    message: str
    output: Optional[str] = None


class UseRequest(BaseModel):
    version: Optional[str] = Field(None, description="Version to switch to. If omitted, auto-detect from config files.")


class UseResponse(BaseModel):
    success: bool
    version: Optional[str] = None
    message: str
    output: Optional[str] = None


class ListResponse(BaseModel):
    versions: List[NodeVersion]
    current: Optional[str] = None
    default: Optional[str] = None


class ConfigFileResponse(BaseModel):
    nvmrc: Optional[str] = None
    node_version: Optional[str] = None
    package_json: Optional[str] = None
    detected_version: Optional[str] = None


class HealthResponse(BaseModel):
    status: str
    service: str
    nvm_available: bool
    nvm_version: Optional[str] = None