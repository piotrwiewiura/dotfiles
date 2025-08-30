#!/bin/bash
# Stop on error
set -e

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

echo "Setting up dotfiles..."

# Check if user has sudo privileges
HAS_SUDO=false
if groups | grep -q sudo; then
  HAS_SUDO=true
fi

# Handle Debian Testing upgrade FIRST (before installing packages)
if [ -f /etc/debian_version ] && [ "$HAS_SUDO" = true ]; then
  echo "🐧 Debian system detected!"
  echo ""
  
  # Check current suite and format
  DEBIAN_SUITE=""
  SOURCES_FORMAT=""
  
  if [ -f /etc/apt/sources.list.d/debian.sources ]; then
    SOURCES_FORMAT="modern"
    DEBIAN_SUITE=$(grep -m1 "^Suites:" /etc/apt/sources.list.d/debian.sources 2>/dev/null | awk '{print $2}' || echo "")
  elif [ -f /etc/apt/sources.list ]; then
    SOURCES_FORMAT="legacy"
    DEBIAN_SUITE=$(grep -m1 "^deb.*debian" /etc/apt/sources.list 2>/dev/null | awk '{print $3}' || echo "")
  fi
  
  echo "Detected: $DEBIAN_SUITE ($SOURCES_FORMAT format)"
  
  # Offer setup for any Debian system (stable or testing)
  if [[ -n "$DEBIAN_SUITE" ]]; then
    if [[ "$DEBIAN_SUITE" == "testing" ]]; then
      echo "Debian Testing detected!"
      echo "Would you like to set up Debian Testing best practices?"
      echo "This adds unstable/experimental repos with proper pinning for better security updates."
    else
      echo "Debian Stable detected!"
      echo "Would you like to upgrade to Debian Testing and set up best practices?"
      echo "This will:"
      echo "• Upgrade your system from stable to testing"
      echo "• Add unstable/experimental repos with proper pinning"
      echo "• Modernize APT sources format if needed"
    fi
    echo ""
    read -p "Run Debian setup? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
      if [ -f "$SCRIPT_DIR/setup-debian-testing.sh" ]; then
        echo ""
        sudo "$SCRIPT_DIR/setup-debian-testing.sh"
        echo ""
        echo "🔄 Updating package lists after Debian setup..."
        sudo apt-get update
      else
        echo "❌ setup-debian-testing.sh not found in $SCRIPT_DIR"
        echo "Please ensure setup-debian-testing.sh is in the same directory as setup.sh"
      fi
    fi
  else
    echo "Could not determine Debian suite. Manual setup may be required."
  fi
  echo ""
fi

# Update package list and install essential tools
if [ "$HAS_SUDO" = true ]; then
  echo "Installing packages..."
  sudo apt-get update
  
  # Essential packages
  ESSENTIAL_PACKAGES="curl git htop vim nano tree unzip"
  
  # Modern CLI tools (optional but recommended)
  MODERN_TOOLS="bat fd-find ripgrep"
  
  # Development tools
  DEV_TOOLS="build-essential wget"
  
  echo "Installing essential packages..."
  sudo apt-get install -y $ESSENTIAL_PACKAGES
  
  echo "Installing modern CLI tools..."
  # These might not be available on all systems, so install individually
  for tool in $MODERN_TOOLS; do
    if sudo apt-get install -y "$tool" 2>/dev/null; then
      echo "✓ Installed $tool"
    else
      echo "⚠ Could not install $tool (not available or failed)"
    fi
  done
  
  echo "Installing development tools..."
  sudo apt-get install -y $DEV_TOOLS
  
  # Set up symlinks for modern tools with common names
  if command -v batcat >/dev/null 2>&1; then
    sudo ln -sf /usr/bin/batcat /usr/local/bin/bat 2>/dev/null || true
  fi
  
  if command -v fdfind >/dev/null 2>&1; then
    sudo ln -sf /usr/bin/fdfind /usr/local/bin/fd 2>/dev/null || true
  fi
else
  echo "⚠ No sudo privileges detected. Skipping package installation."
fi

# Create backup directory for original configs
CONFIGS_ORIG="$HOME/.configs-orig/"
mkdir -p "$CONFIGS_ORIG"

# Function to safely link configuration files
link_file() {
  local SOURCE_FILE="$SCRIPT_DIR/$1"
  local DEST_FILE="$HOME/$1"
  
  if [ ! -f "$SOURCE_FILE" ]; then
    echo "⚠ Warning: $SOURCE_FILE does not exist, skipping..."
    return
  fi
  
  if [ ! -L "$DEST_FILE" ]; then
    # Backup existing file if it exists and isn't already a symlink
    if [ -f "$DEST_FILE" ]; then
      echo "Backing up existing $1 to $CONFIGS_ORIG"
      mv "$DEST_FILE" "$CONFIGS_ORIG"
    fi
    
    echo "Linking $1"
    ln -s "$SOURCE_FILE" "$DEST_FILE"
  else
    echo "✓ $1 already linked"
  fi
}

# Link configuration files
echo "Linking configuration files..."
link_file .bashrc
link_file .bash_aliases
link_file .vimrc
link_file .ls.awk
link_file .gitconfig

# Create .kube directory if it doesn't exist
mkdir -p "$HOME/.kube"

# Handle k3s configuration if available
if [ -f /etc/rancher/k3s/k3s.yaml ] && [ "$HAS_SUDO" = true ]; then
  echo "Setting up k3s kubectl configuration..."
  sudo cp /etc/rancher/k3s/k3s.yaml "$HOME/.kube/k3s-config"
  sudo chown "$USER:" "$HOME/.kube/k3s-config"
  echo "✓ k3s config copied to ~/.kube/k3s-config"
fi

# Create useful directories
echo "Creating useful directories..."
mkdir -p "$HOME/.local/bin"
mkdir -p "$HOME/bin"

# Add ~/.local/bin to PATH if not already there (for current session)
if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
  export PATH="$HOME/.local/bin:$PATH"
fi

echo ""
echo "🎉 Setup complete!"
echo ""
echo "Next steps:"
echo "1. Restart your terminal or run: source ~/.bashrc"
echo "2. Optional modern tools installed:"
if command -v bat >/dev/null 2>&1; then
  echo "   - bat (better cat): try 'bat filename'"
fi
if command -v fd >/dev/null 2>&1; then
  echo "   - fd (better find): try 'fd searchterm'"
fi
if command -v rg >/dev/null 2>&1; then
  echo "   - ripgrep (better grep): try 'rg searchterm'"
fi
echo ""
echo "Your original configs are backed up in: $CONFIGS_ORIG"