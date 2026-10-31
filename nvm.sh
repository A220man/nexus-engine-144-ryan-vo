#!/usr/bin/env sh
#
# Nexus Engine NVM - Node Version Manager
# POSIX-compliant bash script to manage multiple active node.js versions
#
# Source this file to use nvm:
#   . "$HOME/.nvm/nvm.sh"
#
# This script must be sourced, not executed.

# Prevent multiple sourcing
if [ -n "${NVM_LOADED:-}" ]; then
    return 0
fi
export NVM_LOADED=1

# NVM Directory
export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"

# Version
NVM_VERSION="1.0.0"

# Node.js download mirrors
NVM_NODEJS_ORG_MIRROR="${NVM_NODEJS_ORG_MIRROR:-https://nodejs.org/dist}"
NVM_IOJS_ORG_MIRROR="${NVM_IOJS_ORG_MIRROR:-https://iojs.org/dist}"

# Colors
NVM_COLOR_RED='\033[0;31m'
NVM_COLOR_GREEN='\033[0;32m'
NVM_COLOR_YELLOW='\033[1;33m'
NVM_COLOR_BLUE='\033[0;34m'
NVM_COLOR_NC='\033[0m'

# Print functions
nvm_err() {
    printf "${NVM_COLOR_RED}%s${NVM_COLOR_NC}\n" "$*" >&2
}

nvm_info() {
    printf "${NVM_COLOR_BLUE}%s${NVM_COLOR_NC}\n" "$*"
}

nvm_success() {
    printf "${NVM_COLOR_GREEN}%s${NVM_COLOR_NC}\n" "$*"
}

nvm_warn() {
    printf "${NVM_COLOR_YELLOW}%s${NVM_COLOR_NC}\n" "$*"
}

# Utility: normalize version string
nvm_normalize_version() {
    version="$1"
    case "$version" in
        v*)
            echo "$version"
            ;;
        *)
            echo "v$version"
            ;;
    esac
}

# Utility: get version without 'v' prefix
nvm_strip_v() {
    version="$1"
    echo "${version#v}"
}

# Utility: compare versions
nvm_version_compare() {
    v1="$1"
    v2="$2"
    
    # Strip 'v' prefix
    v1=$(nvm_strip_v "$v1")
    v2=$(nvm_strip_v "$v2")
    
    # Use sort -V for version comparison
    if [ "$v1" = "$v2" ]; then
        echo 0
    elif printf '%s\n%s\n' "$v1" "$v2" | sort -V | head -1 | grep -q "^$v1$"; then
        echo -1
    else
        echo 1
    fi
}

# Get installed versions
nvm_ls_installed() {
    versions_dir="$NVM_DIR/versions/node"
    if [ -d "$versions_dir" ]; then
        find "$versions_dir" -maxdepth 1 -type d -name 'v*' | sed 's|.*/||' | sort -V
    fi
}

# Get current version
nvm_current() {
    if [ -n "${NVM_BIN:-}" ]; then
        version=$(basename "$(dirname "$NVM_BIN")")
        echo "$version"
    elif [ -L "$NVM_DIR/versions/node/current" ]; then
        basename "$(readlink "$NVM_DIR/versions/node/current")"
    else
        echo "system"
    fi
}

# List available remote versions
nvm_ls_remote() {
    # Fetch from nodejs.org
    curl -sL "$NVM_NODEJS_ORG_MIRROR/" | grep -oP 'v\d+\.\d+\.\d+' | sort -Vu
}

# List LTS versions
nvm_ls_remote_lts() {
    curl -sL "$NVM_NODEJS_ORG_MIRROR/" | grep -oP 'v\d+\.\d+\.\d+' | grep -E 'v(4|6|8|10|12|14|16|18|20|22)\.' | sort -Vu
}
# Utility: resolve LTS alias to version
# Supports: lts/*, lts/hydrogen, lts/iron, lts/jod, etc.
nvm_resolve_lts_alias() {
    alias="$1"
    case "$alias" in
        lts/*)
            # Extract LTS name
            lts_name="${alias#lts/}"
            if [ "$lts_name" = "*" ]; then
                # Get latest LTS
                nvm_ls_remote_lts | head -1
                return
            fi
            # Map LTS names to version patterns
            case "$lts_name" in
                hydrogen) pattern="v18\." ;;
                iron) pattern="v20\." ;;
                jod) pattern="v22\." ;;
                gallium) pattern="v16\." ;;
                fermium) pattern="v14\." ;;
                erbium) pattern="v12\." ;;
                dubnium) pattern="v10\." ;;
                carbon) pattern="v8\." ;;
                boron) pattern="v6\." ;;
                argon) pattern="v4\." ;;
                *) pattern="v${lts_name}\." ;;
            esac
            nvm_ls_remote_lts | grep -E "^$pattern" | head -1
            ;;
        *)
            echo "$alias"
            ;;
    esac
}

# Install Node.js version
nvm_install() {
    version="$1"
    
    if [ -z "$version" ]; then
        nvm_err "Version required. Usage: nvm install <version>"
        return 1
    fi
    
    # Resolve LTS aliases (e.g., lts/hydrogen, lts/*, lts/iron)
    version=$(nvm_resolve_lts_alias "$version")
    
    version=$(nvm_normalize_version "$version")
    
    # Check if already installed
    if [ -d "$NVM_DIR/versions/node/$version" ]; then
        nvm_warn "Version $version is already installed"
        return 0
    fi
    
    nvm_info "Installing Node.js $version..."
    
    # Determine architecture
    arch=$(uname -m)
    case "$arch" in
        x86_64) arch="x64" ;;
        aarch64|arm64) arch="arm64" ;;
        *) nvm_err "Unsupported architecture: $arch"; return 1 ;;
    esac
    
    # Determine OS
    os=$(uname -s | tr '[:upper:]' '[:lower:]')
    case "$os" in
        linux) os="linux" ;;
        darwin) os="darwin" ;;
        *) nvm_err "Unsupported OS: $os"; return 1 ;;
    esac
    
    # Download URL
    url="$NVM_NODEJS_ORG_MIRROR/$version/node-$version-$os-$arch.tar.gz"
    if [ "$version" = "v0.10.0" ] || [ "$version" = "v0.10.1" ]; then
        # Old versions use different naming
        url="$NVM_NODEJS_ORG_MIRROR/$version/node-$version-$os-$arch.tar.gz"
    fi
    
    nvm_info "Downloading from $url..."
    
    # Create temp directory
    tmpdir=$(mktemp -d)
    
    # Download
    if command -v curl >/dev/null 2>&1; then
        if ! curl -fL "$url" -o "$tmpdir/node.tar.gz"; then
            nvm_err "Failed to download $version"
            rm -rf "$tmpdir"
            return 1
        fi
    elif command -v wget >/dev/null 2>&1; then
        if ! wget -q "$url" -O "$tmpdir/node.tar.gz"; then
            nvm_err "Failed to download $version"
            rm -rf "$tmpdir"
            return 1
        fi
    else
        nvm_err "curl or wget required"
        rm -rf "$tmpdir"
        return 1
    fi
    
    # Extract
    nvm_info "Extracting..."
    mkdir -p "$NVM_DIR/versions/node/$version"
    if ! tar -xzf "$tmpdir/node.tar.gz" -C "$NVM_DIR/versions/node/$version" --strip-components=1; then
        nvm_err "Failed to extract"
        rm -rf "$NVM_DIR/versions/node/$version"
        rm -rf "$tmpdir"
        return 1
    fi
    
    # Cleanup on success
    rm -rf "$tmpdir"
    
    nvm_success "Node.js $version installed successfully"
}

# Use a specific version
nvm_use() {
    version="$1"
    
    if [ -z "$version" ]; then
        # Try to find version from config files
        version=$(nvm_find_version_from_config)
        if [ -z "$version" ]; then
            nvm_err "Version required. Usage: nvm use <version>"
            nvm_err "Or create a .nvmrc, .node-version, or package.json with engines.node"
            return 1
        fi
        nvm_info "Found version $version from config file"
    fi
    
    # Resolve LTS aliases (e.g., lts/hydrogen, lts/*, lts/iron)
    version=$(nvm_resolve_lts_alias "$version")
    
    version=$(nvm_normalize_version "$version")
    
    # Check if installed
    if [ ! -d "$NVM_DIR/versions/node/$version" ]; then
        nvm_err "Version $version is not installed. Run: nvm install $version"
        return 3  # Exit code 3 for version not installed (matches nvm behavior)
    fi
    
    # Update PATH
    export PATH="$NVM_DIR/versions/node/$version/bin:$PATH"
    export NVM_BIN="$NVM_DIR/versions/node/$version/bin"
    export NODE_PATH="$NVM_DIR/versions/node/$version/lib/node_modules"
    
    # Update current symlink
    ln -sfn "$NVM_DIR/versions/node/$version" "$NVM_DIR/versions/node/current"
    
    nvm_success "Now using Node.js $version"
}

# Find version from config files
nvm_find_version_from_config() {
    dir="$PWD"
    while [ "$dir" != "/" ]; do
        # Check .nvmrc
        if [ -f "$dir/.nvmrc" ]; then
            version=$(cat "$dir/.nvmrc" 2>/dev/null | tr -d '[:space:]')
            if [ -n "$version" ]; then
                version=$(nvm_resolve_lts_alias "$version")
                echo "$version"
                return 0
            fi
        fi
        
        # Check .node-version
        if [ -f "$dir/.node-version" ]; then
            version=$(cat "$dir/.node-version" 2>/dev/null | tr -d '[:space:]')
            if [ -n "$version" ]; then
                version=$(nvm_resolve_lts_alias "$version")
                echo "$version"
                return 0
            fi
        fi
        
        # Check package.json engines.node
        if [ -f "$dir/package.json" ]; then
            version=$(grep -o '"node"[[:space:]]*:[[:space:]]*"[^"]*"' "$dir/package.json" 2>/dev/null | head -1 | sed 's/.*"node"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')
            if [ -n "$version" ]; then
                version=$(nvm_resolve_lts_alias "$version")
                echo "$version"
                return 0
            fi
        fi
        
        dir=$(dirname "$dir")
    done
    return 1
}

# Auto-switch version based on directory
nvm_auto_use() {
    version=$(nvm_find_version_from_config)
    if [ -n "$version" ]; then
        nvm_use "$version" >/dev/null 2>&1
    fi
}

# Uninstall version
nvm_uninstall() {
    version="$1"
    if [ -z "$version" ]; then
        nvm_err "Version required. Usage: nvm uninstall <version>"
        return 1
    fi
    version=$(nvm_normalize_version "$version")
    
    if [ ! -d "$NVM_DIR/versions/node/$version" ]; then
        nvm_err "Version $version is not installed"
        return 1
    fi
    
    rm -rf "$NVM_DIR/versions/node/$version"
    nvm_success "Uninstalled $version"
}

# Set default version
nvm_alias_default() {
    version="$1"
    if [ -z "$version" ]; then
        nvm_err "Version required. Usage: nvm alias default <version>"
        return 1
    fi
    version=$(nvm_normalize_version "$version")
    
    if [ ! -d "$NVM_DIR/versions/node/$version" ]; then
        nvm_err "Version $version is not installed"
        return 1
    fi
    
    mkdir -p "$NVM_DIR/alias"
    echo "$version" > "$NVM_DIR/alias/default"
    nvm_success "Default set to $version"
}

# Get default version
nvm_get_default() {
    if [ -f "$NVM_DIR/alias/default" ]; then
        cat "$NVM_DIR/alias/default"
    fi
}

# Show version
nvm_version() {
    echo "Nexus Engine NVM v$NVM_VERSION"
}

# Self-update
nvm_update() {
    nvm_info "Updating Nexus Engine NVM..."
    cd "$NVM_DIR"
    if git pull origin main; then
        nvm_success "NVM updated successfully"
        nvm_info "Please restart your terminal or run: source $NVM_DIR/nvm.sh"
    else
        nvm_err "Failed to update NVM"
        return 1
    fi
}

# Help
nvm_help() {
    cat <<EOF
Nexus Engine NVM v$NVM_VERSION - Node Version Manager

Usage:
  nvm --version                    Show NVM version
  nvm --help                       Show this help
  nvm install <version>            Install Node.js version
  nvm uninstall <version>          Uninstall Node.js version
  nvm use [version]                Switch to Node.js version (reads .nvmrc/.node-version/package.json if no version given)
  nvm current                      Show current Node.js version
  nvm ls                           List installed versions
  nvm ls-remote                    List available remote versions
  nvm ls-remote --lts              List LTS versions
  nvm alias default <version>      Set default Node.js version
  nvm update                       Update NVM to latest version

Config Files (auto-detected by 'nvm use' without arguments):
  .nvmrc              Node version (e.g., "18.17.0" or "lts/hydrogen")
  .node-version       Node version (same format as .nvmrc)
  package.json        engines.node field (e.g., ">=18.0.0")

Environment Variables:
  NVM_DIR             NVM installation directory (default: ~/.nvm)
  NVM_NODEJS_ORG_MIRROR  Node.js download mirror
  NVM_IOJS_ORG_MIRROR    io.js download mirror

Examples:
  nvm install 20.10.0
  nvm install lts/hydrogen
  nvm use 20
  nvm use              # Auto-detect from config files
  nvm alias default 20
EOF
}

# Main nvm function
nvm() {
    case "${1:-}" in
        --version|-v)
            nvm_version
            ;;
        --help|-h|help)
            nvm_help
            ;;
        install|i)
            nvm_install "${2:-}"
            ;;
        uninstall|un|remove|rm)
            nvm_uninstall "${2:-}"
            ;;
        use|u)
            nvm_use "${2:-}"
            ;;
        current|c)
            nvm_current
            ;;
        ls|list)
            nvm_ls_installed
            ;;
        ls-remote|list-remote)
            if [ "${2:-}" = "--lts" ] || [ "${2:-}" = "-l" ]; then
                nvm_ls_remote_lts
            else
                nvm_ls_remote
            fi
            ;;
        alias)
            if [ "${2:-}" = "default" ]; then
                nvm_alias_default "${3:-}"
            else
                nvm_err "Unknown alias command: ${2:-}"
                return 1
            fi
            ;;
        update|upgrade)
            nvm_update
            ;;
        *)
            if [ -z "${1:-}" ]; then
                nvm_help
            else
                nvm_err "Unknown command: $1"
                nvm_err "Run 'nvm --help' for usage"
                return 1
            fi
            ;;
    esac
}

# Auto-load default version on shell startup
if [ -z "${NVM_SKIP_AUTO_USE:-}" ]; then
    default_version=$(nvm_get_default)
    if [ -n "$default_version" ] && [ -d "$NVM_DIR/versions/node/$default_version" ]; then
        export PATH="$NVM_DIR/versions/node/$default_version/bin:$PATH"
        export NVM_BIN="$NVM_DIR/versions/node/$default_version/bin"
        export NODE_PATH="$NVM_DIR/versions/node/$default_version/lib/node_modules"
        ln -sfn "$NVM_DIR/versions/node/$default_version" "$NVM_DIR/versions/node/current"
    fi
fi

# IMPORTANT: Exit with 0 to avoid breaking 'set -e' scripts that source this
# This addresses GitHub issue #1985 where sourcing nvm.sh exited with code 3
return 0