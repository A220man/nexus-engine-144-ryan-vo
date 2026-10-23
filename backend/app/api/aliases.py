from fastapi import APIRouter, HTTPException

from app.services.nvm_service import nvm_service
from app.models.schemas import ListResponse, NodeVersion, VersionStatus

router = APIRouter()


@router.get("", response_model=ListResponse)
async def list_aliases():
    """List all version aliases."""
    exit_code, stdout, stderr = nvm_service._run_nvm(["alias"])
    if exit_code != 0:
        raise HTTPException(status_code=400, detail=f"Failed to list aliases: {stderr}")
    
    aliases = []
    for line in stdout.strip().split('\n'):
        if '->' in line:
            parts = line.split('->')
            if len(parts) == 2:
                alias = parts[0].strip()
                target = parts[1].strip()
                aliases.append(NodeVersion(
                    version=alias,
                    status=VersionStatus.INSTALLED,
                    lts_name=target,
                ))
    
    return ListResponse(versions=aliases)


@router.post("/default/{version}")
async def set_default_alias(version: str):
    """Set default version alias."""
    success, message = nvm_service.alias_default(version)
    if not success:
        raise HTTPException(status_code=400, detail=message)
    return {"success": True, "message": message, "version": version}


@router.get("/default")
async def get_default_alias():
    """Get default version alias."""
    exit_code, stdout, stderr = nvm_service._run_nvm(["alias", "default"])
    if exit_code != 0:
        raise HTTPException(status_code=404, detail="No default alias set")
    
    if '->' in stdout:
        target = stdout.split('->')[1].strip()
        return {"alias": "default", "version": target}
    
    return {"alias": "default", "version": stdout.strip()}


@router.delete("/default")
async def remove_default_alias():
    """Remove default version alias."""
    # nvm alias default with no args doesn't remove; need to remove the alias file
    import os
    alias_path = os.path.join(nvm_service.nvm_dir, "alias", "default")
    if os.path.exists(alias_path):
        os.remove(alias_path)
        return {"success": True, "message": "Default alias removed"}
    raise HTTPException(status_code=404, detail="No default alias to remove")