from fastapi import APIRouter, HTTPException, status
from typing import Optional

from app.models.schemas import (
    NodeVersion, ListResponse, InstallRequest, InstallResponse,
    UseRequest, UseResponse
)
from app.services.nvm_service import nvm_service

router = APIRouter()


@router.get("", response_model=ListResponse)
async def list_versions(lts: bool = False):
    """List installed or available Node.js versions."""
    if lts:
        versions = nvm_service.list_remote(lts_only=True)
    else:
        list_response = nvm_service.get_full_list()
        return list_response
    return ListResponse(versions=versions)


@router.get("/remote", response_model=ListResponse)
async def list_remote_versions(lts: bool = False):
    """List available remote Node.js versions."""
    versions = nvm_service.list_remote(lts_only=lts)
    return ListResponse(versions=versions)


@router.get("/current")
async def get_current_version():
    """Get currently active Node.js version."""
    version = nvm_service.current()
    if version is None:
        raise HTTPException(status_code=404, detail="No Node.js version currently active")
    return {"version": version}


@router.post("/install", response_model=InstallResponse)
async def install_version(request: InstallRequest):
    """Install a Node.js version."""
    success, message, output = nvm_service.install(request.version, request.force)
    if not success:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=message
        )
    return InstallResponse(success=True, version=request.version, message=message, output=output)


@router.post("/use", response_model=UseResponse)
async def use_version(request: UseRequest):
    """Switch to a Node.js version."""
    success, message, output = nvm_service.use(request.version)
    if not success:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=message
        )
    # Get the actual current version after switch
    current = nvm_service.current()
    return UseResponse(success=True, version=current, message=message, output=output)


@router.post("/alias/default/{version}")
async def set_default_version(version: str):
    """Set default Node.js version."""
    success, message = nvm_service.alias_default(version)
    if not success:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=message
        )
    return {"success": True, "message": message, "version": version}


@router.delete("/{version}")
async def uninstall_version(version: str):
    """Uninstall a Node.js version."""
    success, message = nvm_service.uninstall(version)
    if not success:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=message
        )
    return {"success": True, "message": message}