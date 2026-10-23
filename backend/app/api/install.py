from fastapi import APIRouter, HTTPException
from pydantic import BaseModel

router = APIRouter()


class InstallScriptResponse(BaseModel):
    script_url: str
    install_command_curl: str
    install_command_wget: str
    manual_steps: list[str]


@router.get("/script", response_model=InstallScriptResponse)
async def get_install_script():
    """Get NVM installation script information."""
    base_url = "https://raw.githubusercontent.com/A220man/nexus-engine-144-ryan-vo/main"
    return InstallScriptResponse(
        script_url=f"{base_url}/install.sh",
        install_command_curl=f"curl -o- {base_url}/install.sh | bash",
        install_command_wget=f"wget -qO- {base_url}/install.sh | bash",
        manual_steps=[
            "git clone https://github.com/A220man/nexus-engine-144-ryan-vo.git ~/.nvm",
            "Add shell profile entries (see API.md for details)",
            "Restart shell or source profile",
        ],
    )