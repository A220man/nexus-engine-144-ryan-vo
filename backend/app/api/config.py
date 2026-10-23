from fastapi import APIRouter, HTTPException
from typing import Optional

from app.models.schemas import ConfigFileResponse
from app.services.nvm_service import nvm_service

router = APIRouter()


@router.get("", response_model=ConfigFileResponse)
async def detect_config(cwd: Optional[str] = None):
    """Detect Node.js version from config files in directory."""
    import os
    target_dir = cwd or os.getcwd()
    return nvm_service.get_config_files(target_dir)


@router.get("/health")
async def health_check():
    """Check NVM availability and version."""
    available = nvm_service.is_available()
    version = nvm_service.get_version() if available else None
    return {
        "status": "healthy" if available else "degraded",
        "service": "nexus-engine-nvm-api",
        "nvm_available": available,
        "nvm_version": version,
    }