#!/usr/bin/env sh
#
# Nexus Engine NVM - Installation Script
# POSIX-compliant installer for Node Version Manager
#
# Usage: curl -o- https://raw.githubusercontent.com/A220man/nexus-engine-144-ryan-vo/main/install.sh | bash
#        or: wget -qO- https://raw.githubusercontent.com/A220man/nexus-engine-144-ryan-vo/main/install.sh | bash

set -e

NVM_REPO_URL="${NVM_REPO_URL:-https://github.com/nvm-sh/nvm.git}"
NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
NVM_VERSION="${NVM_VERSION:-main}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print functions
info() {
    printf "${BLUE}%s${NC}\n" "$*"
}

success() {
    printf "${GREEN}%s${NC}\n" "$*"
}

warn() {
    printf "${YELLOW}%s${NC}\n" "$*"
}

error() {
    printf "${RED}%s${NC}\n" "$*" >&2
}

# Detect shell
detect_shell() {
    case "$SHELL" in
        */bash)
            echo "bash"
            ;;
        */zsh)
            echo "zsh"
            ;;
        */fish)
            echo "fish"
            ;;
        *)
            # Fallback: check parent process or default to bash
            if [ -n "$BASH_VERSION" ]; then
                echo "bash"
            elif [ -n "$ZSH_VERSION" ]; then
                echo "zsh"
            else
                echo "bash"
            fi
            ;;
    esac
}

# Get shell profile file
get_profile() {
    shell="$1"
    case "$shell" in
        bash)
            if [ -f "$HOME/.bashrc" ]; then
                echo "$HOME/.bashrc"
            elif [ -f "$HOME/.bash_profile" ]; then
                echo "$HOME/.bash_profile"
            else
                echo "$HOME/.bashrc"
            fi
            ;;
        zsh)
            echo "$HOME/.zshrc"
            ;;
        fish)
            echo "$HOME/.config/fish/config.fish"
            ;;
        *)
            echo "$HOME/.bashrc"
            ;;
    esac
}

# Check if nvm is already installed
check_existing_install() {
    if [ -d "$NVM_DIR" ]; then
        warn "NVM directory already exists at $NVM_DIR"
        if [ -f "$NVM_DIR/nvm.sh" ]; then
            info "Existing installation detected. Updating..."
            return 1
        fi
    fi
    return 0
}

# Download and extract release
clone_repo() {
    info "Installing Nexus Engine NVM into $NVM_DIR..."
    
    # Create directory
    mkdir -p "$NVM_DIR"
    
    # Download URL for release tarball
    # For local development, copy from current directory
    if [ -f "./nvm.sh" ] && [ -f "./install.sh" ]; then
        info "Installing from local source..."
        cp ./nvm.sh "$NVM_DIR/nvm.sh"
        cp ./install.sh "$NVM_DIR/install.sh"
        # Create bash_completion stub
        echo "# Nexus Engine NVM bash completion" > "$NVM_DIR/bash_completion"
        return 0
    fi
    
    # For remote installation, download from release
    download_url="https://github.com/A220man/nexus-engine-144-ryan-vo/releases/download/$NVM_VERSION/nexus-engine-nvm.tar.gz"
    nvm_info "Downloading from $download_url..."
    
    tmpdir=$(mktemp -d)
    if command -v curl >/dev/null 2>&1; then
        if ! curl -fL "$download_url" -o "$tmpdir/nvm.tar.gz"; then
            nvm_err "Failed to download release"
            rm -rf "$tmpdir"
            return 1
        fi
    elif command -v wget >/dev/null 2>&1; then
        if ! wget -q "$download_url" -O "$tmpdir/nvm.tar.gz"; then
            nvm_err "Failed to download release"
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
    if ! tar -xzf "$tmpdir/nvm.tar.gz" -C "$NVM_DIR" --strip-components=1; then
        nvm_err "Failed to extract"
        rm -rf "$tmpdir"
        return 1
    fi
    
    rm -rf "$tmpdir"
    nvm_success "Installation complete"
}

# Add source line to shell profile
add_source_to_profile() {
    shell="$1"
    profile="$2"
    source_line="$3"
    
    # Create profile if it doesn't exist
    touch "$profile"
    
    # Check if already present
    if grep -q "nexus-engine-nvm" "$profile" 2>/dev/null; then
        info "NVM source already present in $profile"
        return 0
    fi
    
    info "Adding NVM source to $profile..."
    
    # Add newline if file doesn't end with one
    [ -s "$profile" ] && [ "$(tail -c1 "$profile")" != "" ] && echo "" >> "$profile"
    
    cat >> "$profile" <<EOF

# Nexus Engine NVM
export NVM_DIR="$NVM_DIR"
[ -s "\$NVM_DIR/nvm.sh" ] && . "\$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "\$NVM_DIR/bash_completion" ] && . "\$NVM_DIR/bash_completion"  # This loads nvm bash_completion
EOF
    
    success "Added NVM to $profile"
}

# Add fish configuration
add_fish_config() {
    config_dir="$HOME/.config/fish"
    config_file="$config_dir/config.fish"
    
    mkdir -p "$config_dir"
    touch "$config_file"
    
    if grep -q "nexus-engine-nvm" "$config_file" 2>/dev/null; then
        info "NVM source already present in $config_file"
        return 0
    fi
    
    info "Adding NVM to fish config..."
    
    [ -s "$config_file" ] && [ "$(tail -c1 "$config_file")" != "" ] && echo "" >> "$config_file"
    
    cat >> "$config_file" <<EOF

# Nexus Engine NVM
set -gx NVM_DIR "$NVM_DIR"
if test -f \$NVM_DIR/nvm.fish
    source \$NVM_DIR/nvm.fish
end
EOF
    
    success "Added NVM to fish config"
}

# Create nvm.fish for fish shell support
create_fish_wrapper() {
    info "Creating fish shell wrapper..."
    cat > "$NVM_DIR/nvm.fish" <<'EOF'
# Nexus Engine NVM - Fish shell wrapper
function nvm
    set -l nvm_sh $NVM_DIR/nvm.sh
    if test -f $nvm_sh
        bass source $nvm_sh ';' nvm $argv
    else
        echo "NVM not found at $nvm_sh"
        return 1
    end
end
EOF
}

# Main installation
main() {
    info "Installing Nexus Engine NVM..."
    info "NVM_DIR: $NVM_DIR"
    info "NVM_VERSION: $NVM_VERSION"
    
    # Check prerequisites
    if ! command -v curl >/dev/null 2>&1 && ! command -v wget >/dev/null 2>&1; then
        error "curl or wget is required for installation"
        exit 1
    fi
    
    check_existing_install
    clone_repo
    
    # Detect shell and configure
    shell=$(detect_shell)
    info "Detected shell: $shell"
    
    case "$shell" in
        fish)
            add_fish_config
            create_fish_wrapper
            ;;
        *)
            profile=$(get_profile "$shell")
            info "Using profile: $profile"
            add_source_to_profile "$shell" "$profile"
            ;;
    esac
    
    success "Installation complete!"
    info ""
    info "To start using NVM, either:"
    info "  1. Restart your terminal"
    info "  2. Run: source $profile"
    info ""
    info "Then try: nvm --version"
    info "          nvm install --latest"
    info "          nvm use node"
}

main "$@"

# Exit successfully - this is critical for 'set -e' scripts sourcing this
exit 0