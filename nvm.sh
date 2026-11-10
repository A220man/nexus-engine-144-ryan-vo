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

# Utility: resolve version range to latest matching version
# Supports: >=X.Y.Z, >X.Y.Z, <=X.Y.Z, <X.Y.Z, ^X.Y.Z, ~X.Y.Z, X.Y.x, X.x, *
# Filters out pre-release versions (alpha, beta, rc, etc.)
nvm_resolve_version_range() {
    range="$1"
    
    # If it is already a concrete version (no range operators), return as-is
    # Range operators: < >= ^ ~ * or patterns ending in .x
    case "$range" in
        *['<>=^~*']*) ;;
        *.x) ;;
        *) echo "$range"; return 0 ;;
    esac
    
    # Parse operator to determine whether to get min or max matching version
    # >= and > want minimum (first match), others want maximum (last match)
    op=""
    case "$range" in
        \>=*) op=">=" ;;
        \>*) op=">" ;;
        \<=*) op="<=" ;;
        \<*) op="<" ;;
        \^*) op="^" ;;
        \~*) op="~" ;;
        *) op="other" ;;
    esac
    
    # Fetch all versions from API
    versions=$(curl -sL "$NVM_NODEJS_ORG_MIRROR/index.json" | \
        grep -o '"version":"[^"]*"' | \
        sed 's/"version":"//;s/"//' | \
        sort -Vu)
    
    if [ -z "$versions" ]; then
        nvm_err "Failed to fetch versions from API"
        return 1
    fi
    
    # Parse range and find matching versions
    # Use awk for version comparison
    # Filter out pre-release versions (those containing -)
    echo "$versions" | grep -v -- '-' | awk -v range="$range" '
    BEGIN {
        # Parse range
        op = ""
        ver = range
        if (match(range, /^([<>=^~]+)(.*)/, arr)) {
            op = arr[1]
            ver = arr[2]
        }
        
        # Normalize version (strip v prefix)
        gsub(/^v/, "", ver)
        split(ver, vparts, ".")
        vmajor = (vparts[1] != "" ? vparts[1] : 0)
        vminor = (vparts[2] != "" ? vparts[2] : 0)
        vpatch = (vparts[3] != "" ? vparts[3] : 0)
    }
    {
        version = $0
        gsub(/^v/, "", version)
        split(version, parts, ".")
        major = (parts[1] != "" ? parts[1] : 0)
        minor = (parts[2] != "" ? parts[2] : 0)
        patch = (parts[3] != "" ? parts[3] : 0)
        
        is_match = 0
        if (op == ">=") {
            if (major > vmajor) is_match = 1
            else if (major == vmajor && minor > vminor) is_match = 1
            else if (major == vmajor && minor == vminor && patch >= vpatch) is_match = 1
        } else if (op == ">") {
            if (major > vmajor) is_match = 1
            else if (major == vmajor && minor > vminor) is_match = 1
            else if (major == vmajor && minor == vminor && patch > vpatch) is_match = 1
        } else if (op == "<=") {
            if (major < vmajor) is_match = 1
            else if (major == vmajor && minor < vminor) is_match = 1
            else if (major == vmajor && minor == vminor && patch <= vpatch) is_match = 1
        } else if (op == "<") {
            if (major < vmajor) is_match = 1
            else if (major == vmajor && minor < vminor) is_match = 1
            else if (major == vmajor && minor == vminor && patch < vpatch) is_match = 1
        } else if (op == "^") {
            # ^X.Y.Z means >=X.Y.Z <X+1.0.0 (or >=0.Y.Z <0.Y+1.0 if X=0)
            if (vmajor == 0) {
                if (major == vmajor && minor == vminor && patch >= vpatch) is_match = 1
            } else {
                if (major == vmajor && (minor > vminor || (minor == vminor && patch >= vpatch))) is_match = 1
            }
        } else if (op == "~") {
            # ~X.Y.Z means >=X.Y.Z <X.Y+1.0
            if (major == vmajor && minor == vminor && patch >= vpatch) is_match = 1
        } else if (op == "*" || range == "*") {
            is_match = 1
        } else if (match(ver, /^([0-9]+)\.x$/)) {
            # X.x - any version with major X
            if (major == vmajor) is_match = 1
        } else if (match(ver, /^([0-9]+)\.([0-9]+)\.x$/)) {
            # X.Y.x - any version with major X and minor Y
            if (major == vmajor && minor == vminor) is_match = 1
        }
        
        if (is_match) {
            print version
        }
    }
    ' | sort -V > /tmp/nvm_versions_$$.txt
    
    # For >= and > operators, return minimum (first) matching version
    # For all others (<=, <, ^, ~, *, X.x, X.Y.x), return maximum (last)
    if [ "$op" = ">=" ] || [ "$op" = ">" ]; then
        head -1 /tmp/nvm_versions_$$.txt
    else
        tail -1 /tmp/nvm_versions_$$.txt
    fi
    rm -f /tmp/nvm_versions_$$.txt
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
    # Fetch from Node.js releases API (JSON)
    curl -sL "$NVM_NODEJS_ORG_MIRROR/index.json" | \
        grep -o '"version":"[^"]*"' | \
        sed 's/"version":"//;s/"//' | \
        sort -Vu
}

# List LTS versions
nvm_ls_remote_lts() {
    # Fetch from Node.js releases API (JSON) and filter for LTS versions
    curl -sL "$NVM_NODEJS_ORG_MIRROR/index.json" | \
        grep -o '"version":"[^"]*","date":"[^"]*","files":\[[^]]*\],"npm":"[^"]*","v8":"[^"]*","uv":"[^"]*","zlib":"[^"]*","openssl":"[^"]*","modules":"[^"]*","lts":"[^"]*","security":[^}]*' | \
        grep '"lts":"[^"]*"' | \
        grep -v '"lts":false' | \
        grep -v '"lts":""' | \
        sed 's/.*"version":"\([^"]*\)".*/\1/' | \
        sort -Vu
}
# Utility: resolve LTS alias to version
# Supports: lts/*, lts/lithium, lts/krypton, lts/jod, lts/iron, lts/hydrogen, lts/gallium, lts/fermium, lts/erbium, lts/dubnium, lts/carbon, lts/boron, lts/argon
# Case-insensitive matching for LTS names
nvm_resolve_lts_alias() {
    alias="$1"
    case "$alias" in
        lts/*) ;;
        *) echo "$alias"; return 0 ;;
    esac
    
    lts_name=$(echo "$alias" | sed 's/^lts\///')
    
    # Fetch LTS data from Node.js releases API
    lts_data=$(curl -sL "$NVM_NODEJS_ORG_MIRROR/index.json" | \
        grep -o '"version":"[^"]*","date":"[^"]*","files":\[[^]]*\],"npm":"[^"]*","v8":"[^"]*","uv":"[^"]*","zlib":"[^"]*","openssl":"[^"]*","modules":"[^"]*","lts":"[^"]*","security":[^}]*' | \
        grep '"lts":"[^"]*"' | \
        grep -v '"lts":false' | \
        grep -v '"lts":""')
    
    if [ -z "$lts_data" ]; then
        nvm_err "Failed to fetch LTS data from API"
        return 1
    fi
    
    if [ "$lts_name" = "*" ]; then
        # Latest LTS - get the highest version
        echo "$lts_data" | sed 's/.*"version":"\([^"]*\)".*/\1/' | sort -V | tail -1
    else
        # Named LTS - find matching version (case-insensitive)
        echo "$lts_data" | awk -v lts_name="$lts_name" '
            BEGIN { IGNORECASE = 1 }
            $0 ~ "\"lts\":\"" lts_name "\"" {
                match($0, /"version":"([^"]*)"/, arr)
                print arr[1]
            }
        ' | sort -V | tail -1
    fi
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
    
    # Resolve version ranges (e.g., >=20.0.0, ^20.0.0, 20.x)
    version=$(nvm_resolve_version_range "$version")
    
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
    
    # Resolve version ranges (e.g., >=20.0.0, ^20.0.0, 20.x)
    version=$(nvm_resolve_version_range "$version")
    
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
                version=$(nvm_resolve_version_range "$version")
                echo "$version"
                return 0
            fi
        fi
        
        # Check .node-version
        if [ -f "$dir/.node-version" ]; then
            version=$(cat "$dir/.node-version" 2>/dev/null | tr -d '[:space:]')
            if [ -n "$version" ]; then
                version=$(nvm_resolve_lts_alias "$version")
                version=$(nvm_resolve_version_range "$version")
                echo "$version"
                return 0
            fi
        fi
        
        # Check package.json engines.node
        if [ -f "$dir/package.json" ]; then
            version=$(grep -o '"node"[[:space:]]*:[[:space:]]*"[^"]*"' "$dir/package.json" 2>/dev/null | head -1 | sed 's/.*"node"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')
            if [ -n "$version" ]; then
                version=$(nvm_resolve_lts_alias "$version")
                version=$(nvm_resolve_version_range "$version")
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
  .nvmrc              Node version (e.g., "18.17.0" or "lts/hydrogen", "lts/iron", "lts/jod", "lts/krypton", "lts/lithium", "lts/*")
  .node-version       Node version (same format as .nvmrc)
  package.json        engines.node field (e.g., ">=18.0.0", "^20.0.0", "20.x")

Environment Variables:
  NVM_DIR             NVM installation directory (default: ~/.nvm)
  NVM_NODEJS_ORG_MIRROR  Node.js download mirror
  NVM_IOJS_ORG_MIRROR    io.js download mirror

Examples:
  nvm install 20.10.0
  nvm install lts/hydrogen
  nvm install lts/iron
  nvm install lts/lithium
  nvm install ">=20.0.0"
  nvm install "^20.0.0"
  nvm install "20.x"
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
