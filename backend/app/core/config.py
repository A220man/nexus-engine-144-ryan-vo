from pydantic_settings import BaseSettings
from typing import List
import os


class Settings(BaseSettings):
    app_name: str = "Nexus Engine NVM API"
    app_version: str = "1.0.0"
    debug: bool = False
    
    nvm_dir: str = os.path.expanduser("~/.nvm")
    nvm_script_path: str = ""
    
    cors_origins: List[str] = ["http://localhost:5173", "http://127.0.0.1:5173"]
    
    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"
        extra = "ignore"


settings = Settings()

if not settings.nvm_script_path:
    settings.nvm_script_path = os.path.join(settings.nvm_dir, "nvm.sh")