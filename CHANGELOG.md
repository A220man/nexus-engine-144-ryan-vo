# Changelog

## 1.0.0 — work-in-progress checkpoint

Partial code published for continued development. Known issues: STATUS.md.

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-10-23

### Added
- Core NVM installation script (`install.sh`) with POSIX-compliant shell detection
- Main NVM script (`nvm.sh`) with version management commands
- Support for bash, zsh, and fish shells
- Install command: `nvm install <version>` with support for LTS aliases
- Use command: `nvm use [version]` with auto-detection from config files
- List commands: `nvm ls`, `nvm ls-remote`, `nvm ls-remote --lts`
- Current version: `nvm current`
- Alias management: `nvm alias default <version>`
- Uninstall command: `nvm uninstall <version>`
- Self-update command: `nvm update`
- Config file support: `.nvmrc`, `.node-version`, `package.json` engines.node
- Fixed exit code 3 on sourcing (GitHub issue #1985)
- Test suite (`tests/test_install.sh`)
- FastAPI backend with REST API for NVM operations
- React + TypeScript + Vite frontend with dashboard UI
- Docker support with docker-compose for backend and frontend
- GitHub Actions CI workflow for testing and Docker builds

### Fixed
- Exit code 3 when sourcing nvm.sh with .nvmrc present (issue #1985)
- Download error handling with proper cleanup on failure
- Trap EXIT issues with set -e scripts

### Security
- Non-root installation
- Downloads only from configurable official mirrors
- No credentials or secrets in codebase