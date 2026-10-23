# Product development plan

Each round completes one feature or repair. Future items are planned, not implemented claims.

## Current round

core-install

## Roadmap

### core-install — Core NVM Installation Script

Status: done

Acceptance:
- Install script downloads and sets up nvm in ~/.nvm
- Supports bash, zsh, and fish shells
- Creates proper shell profile entries
- Does not exit with non-zero code on successful sourcing

Implementation: `install.sh`, `nvm.sh`

Tests: `tests/test_install.sh`

### version-management — Node Version Management

Status: done

Acceptance:
- List available Node.js versions
- Install specific Node.js version
- Switch between installed versions
- Show current version

Implementation: `nvm.sh`

Tests: `tests/test_install.sh`

### config-files — Config File Support (.nvmrc, .node-version, package.json)

Status: done

Acceptance:
- Read .nvmrc for version
- Read .node-version for version
- Read package.json engines.node for version
- Auto-switch version on directory change

Implementation: `nvm.sh`

Tests: `tests/test_install.sh`

### self-update — Self-Update Command

Status: done

Acceptance:
- nvm update command fetches latest version
- Preserves installed Node versions
- Updates shell profile if needed

Implementation: `nvm.sh`

Tests: `tests/test_install.sh`

