# API Reference

## Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `NVM_DIR` | NVM installation directory | `~/.nvm` |
| `NVM_NODEJS_ORG_MIRROR` | Node.js download mirror | `https://nodejs.org/dist` |
| `NVM_IOJS_ORG_MIRROR` | io.js download mirror | `https://iojs.org/dist` |
| `NVM_SKIP_AUTO_USE` | Skip auto-loading default version | unset |

## Commands

### `nvm --version`, `nvm -v`
Show NVM version.

**Output**: `Nexus Engine NVM v1.0.0`

### `nvm --help`, `nvm -h`, `nvm help`
Show help message.

### `nvm install <version>`, `nvm i <version>`
Install Node.js version.

**Arguments**:
- `version`: Version string (e.g., `20.10.0`, `v20.10.0`, `lts/hydrogen`, `node`, `--lts`)

**Examples**:
```bash
nvm install 20.10.0
nvm install v20.10.0
nvm install lts/hydrogen
nvm install --lts
nvm install node  # latest stable
```

### `nvm uninstall <version>`, `nvm un <version>`, `nvm remove <version>`, `nvm rm <version>`
Uninstall Node.js version.

**Arguments**:
- `version`: Version string to uninstall

### `nvm use [version]`, `nvm u [version]`
Switch to Node.js version.

**Arguments**:
- `version` (optional): Version string. If omitted, auto-detects from config files.

**Config file detection order**:
1. `.nvmrc` in current or parent directory
2. `.node-version` in current or parent directory
3. `package.json` `engines.node` field

**Examples**:
```bash
nvm use 20.10.0
nvm use              # Auto-detect from config files
nvm use lts/hydrogen
```

### `nvm current`, `nvm c`
Show currently active Node.js version.

**Output**: Version string (e.g., `v20.10.0`) or `system` if no NVM version active.

### `nvm ls`, `nvm list`
List installed Node.js versions.

**Output**: One version per line, current version marked with `->`.

### `nvm ls-remote`, `nvm list-remote`
List available remote Node.js versions.

**Output**: All available versions from nodejs.org, one per line.

### `nvm ls-remote --lts`, `nvm ls-remote -l`
List LTS Node.js versions.

### `nvm alias default <version>`
Set default Node.js version.

**Arguments**:
- `version`: Version string to set as default.

**Example**:
```bash
nvm alias default 20.10.0
```

### `nvm update`, `nvm upgrade`
Update NVM to latest version.

Performs `git pull` in the NVM directory. Preserves installed Node versions.

## Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Success |
| 1 | General error (invalid arguments, download failed, etc.) |
| 3 | Version not installed (for `nvm use`) |

Note: Sourcing `nvm.sh` always returns 0 (fixes GitHub issue #1985).

## Config Files

### `.nvmrc`
Single line with version string.
```
20.10.0
lts/hydrogen
```

### `.node-version`
Same format as `.nvmrc`.
```
v20.10.0
```

### `package.json`
```json
{
  "engines": {
    "node": ">=20.0.0"
  }
}
```

## Shell Integration

### Bash/Zsh
Add to `~/.bashrc` or `~/.zshrc`:
```bash
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion"
```

### Fish
Add to `~/.config/fish/config.fish`:
```fish
set -gx NVM_DIR "$HOME/.nvm"
if test -f $NVM_DIR/nvm.fish
    source $NVM_DIR/nvm.fish
end
```

The fish wrapper uses `bass` to source the bash script.