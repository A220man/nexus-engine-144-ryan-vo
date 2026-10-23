from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.api import versions, config, install, aliases
from app.core.config import settings

app = FastAPI(
    title="Nexus Engine NVM API",
    description="Node Version Manager API",
    version="1.0.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(versions.router, prefix="/api/v1/versions", tags=["versions"])
app.include_router(config.router, prefix="/api/v1/config", tags=["config"])
app.include_router(install.router, prefix="/api/v1/install", tags=["install"])
app.include_router(aliases.router, prefix="/api/v1/aliases", tags=["aliases"])

@app.get("/health")
async def health_check():
    return {"status": "healthy", "service": "nexus-engine-nvm-api"}

@app.get("/")
async def root():
    return {
        "name": "Nexus Engine NVM API",
        "version": "1.0.0",
        "description": "Node Version Manager REST API",
    }