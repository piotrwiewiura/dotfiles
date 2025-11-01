#!/bin/bash
# Stop on error
set -e

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

echo "Setting up dotfiles..."

# Detect if running on Raspberry Pi OS
IS_RASPBERRY_PI=false
if [ -f /etc/rpi-issue ]; then
  IS_RASPBERRY_PI=true
  echo "🥧 Raspberry Pi OS detected!"
  echo ""
fi

# Handle Debian Testing upgrade FIRST (before installing packages)
# Skip this entirely for Raspberry Pi OS
if [ -f /etc/debian_version ] && [ "$IS_RASPBERRY_PI" = false ]; then
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
    read -p "Run Debian setup? (Y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
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

# For Raspberry Pi OS, check if sources need updating to latest stable
if [ "$IS_RASPBERRY_PI" = true ]; then
  echo "Checking Raspberry Pi OS version..."
  
  # Determine current codename
  CURRENT_CODENAME=""
  if [ -f /etc/os-release ]; then
    CURRENT_CODENAME=$(grep "^VERSION_CODENAME=" /etc/os-release 2>/dev/null | cut -d'=' -f2)
  fi
  
  # Determine what sources files exist (DEB822 or legacy)
  if [ -f /etc/apt/sources.list.d/debian.sources ] || [ -f /etc/apt/sources.list.d/raspbian.sources ]; then
    SOURCES_FORMAT="modern"
  else
    SOURCES_FORMAT="legacy"
  fi
  
  if [[ -n "$CURRENT_CODENAME" ]]; then
    echo "Current Raspberry Pi OS: $CURRENT_CODENAME ($SOURCES_FORMAT format)"
    
    # Check for latest stable and testing Raspberry Pi OS versions
    echo "Checking for latest stable Raspberry Pi OS version..."
    
    LATEST_STABLE=""
    LATEST_TESTING=""
    
    # Check what Raspberry Pi OS officially supports
    # For 64-bit (uses debian repos BUT through Raspberry Pi repos)
    if [ -f /etc/apt/sources.list.d/debian.sources ]; then
      # Check Raspberry Pi's debian-based repo, not upstream Debian
      LATEST_STABLE=$(curl -s http://archive.raspberrypi.com/debian/dists/stable/Release 2>/dev/null | grep "^Codename:" | awk '{print $2}' || echo "")
      LATEST_TESTING=$(curl -s http://archive.raspberrypi.com/debian/dists/testing/Release 2>/dev/null | grep "^Codename:" | awk '{print $2}' || echo "")
    # For 32-bit (uses raspbian repos)
    elif [ -f /etc/apt/sources.list.d/raspbian.sources ]; then
      LATEST_STABLE=$(curl -s http://raspbian.raspberrypi.com/raspbian/dists/stable/Release 2>/dev/null | grep "^Codename:" | awk '{print $2}' || echo "")
      LATEST_TESTING=$(curl -s http://raspbian.raspberrypi.com/raspbian/dists/testing/Release 2>/dev/null | grep "^Codename:" | awk '{print $2}' || echo "")
    # Legacy format
    elif grep -q "raspbian.raspberrypi" /etc/apt/sources.list 2>/dev/null; then
      LATEST_STABLE=$(curl -s http://raspbian.raspberrypi.com/raspbian/dists/stable/Release 2>/dev/null | grep "^Codename:" | awk '{print $2}' || echo "")
      LATEST_TESTING=$(curl -s http://raspbian.raspberrypi.com/raspbian/dists/testing/Release 2>/dev/null | grep "^Codename:" | awk '{print $2}' || echo "")
    else
      # Fallback to checking archive.raspberrypi.com
      LATEST_STABLE=$(curl -s http://archive.raspberrypi.com/debian/dists/stable/Release 2>/dev/null | grep "^Codename:" | awk '{print $2}' || echo "")
      LATEST_TESTING=$(curl -s http://archive.raspberrypi.com/debian/dists/testing/Release 2>/dev/null | grep "^Codename:" | awk '{print $2}' || echo "")
    fi
    
    # Check if user is on testing - if so, don't suggest downgrade
    if [[ "$CURRENT_CODENAME" == "$LATEST_TESTING" ]]; then
      echo "✓ Already on testing: $CURRENT_CODENAME"
    elif [[ -n "$LATEST_STABLE" ]] && [[ "$LATEST_STABLE" != "$CURRENT_CODENAME" ]]; then
      # User is on stable but there's a newer stable available
      # Verify the target suite actually exists before offering upgrade
      SUITE_EXISTS=false
      
      if [ -f /etc/apt/sources.list.d/raspbian.sources ] || grep -q "raspbian.raspberrypi" /etc/apt/sources.list 2>/dev/null; then
        # Check Raspbian repo
        if curl -s -f -I "http://raspbian.raspberrypi.com/raspbian/dists/$LATEST_STABLE/Release" >/dev/null 2>&1; then
          SUITE_EXISTS=true
        fi
      else
        # Check Raspberry Pi debian repo
        if curl -s -f -I "http://archive.raspberrypi.com/debian/dists/$LATEST_STABLE/Release" >/dev/null 2>&1; then
          SUITE_EXISTS=true
        fi
      fi
      
      if [ "$SUITE_EXISTS" = true ]; then
        echo "⚠️  Latest stable: $LATEST_STABLE (you have: $CURRENT_CODENAME)"
        echo ""
        echo "Would you like to update your sources to $LATEST_STABLE?"
        echo "Note: This only updates repository sources, not packages."
        echo "After updating sources, you can upgrade packages with 'sudo apt full-upgrade'"
        echo ""
        read -p "Update sources to $LATEST_STABLE? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
          echo "Updating sources to $LATEST_STABLE..."
          
          # Update based on format
          if [ "$SOURCES_FORMAT" = "modern" ]; then
            # Update DEB822 format files
            sudo find /etc/apt/sources.list.d -name "*.sources" -exec sed -i "s/Suites: $CURRENT_CODENAME/Suites: $LATEST_STABLE/g" {} \;
          else
            # Update legacy format
            sudo sed -i "s/$CURRENT_CODENAME/$LATEST_STABLE/g" /etc/apt/sources.list
            if [ -f /etc/apt/sources.list.d/raspi.list ]; then
              sudo sed -i "s/$CURRENT_CODENAME/$LATEST_STABLE/g" /etc/apt/sources.list.d/raspi.list
            fi
          fi
          
          echo "✓ Sources updated to $LATEST_STABLE"
          sudo apt-get update
        fi
      else
        echo "✓ Already on latest available: $CURRENT_CODENAME"
        echo "  (Newer release $LATEST_STABLE not yet available for Raspberry Pi OS)"
      fi
    else
      echo "✓ Already on latest stable: $CURRENT_CODENAME"
    fi
  fi
  echo ""
fi

# Update package list and install essential tools
echo "Installing packages..."
sudo apt-get update

# Essential packages
ESSENTIAL_PACKAGES="curl wget git htop vim nano tree unzip keychain"

# Modern CLI tools (optional but recommended)
MODERN_TOOLS="bat duf fd-find ripgrep"

echo "Installing essential packages and modern tools..."
sudo apt-get install -y $ESSENTIAL_PACKAGES $MODERN_TOOLS

# Set up symlinks for modern tools with common names
if command -v batcat >/dev/null 2>&1; then
  sudo ln -sf /usr/bin/batcat /usr/local/bin/bat 2>/dev/null || true
fi

if command -v fdfind >/dev/null 2>&1; then
  sudo ln -sf /usr/bin/fdfind /usr/local/bin/fd 2>/dev/null || true
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
link_file .bash_logout
link_file .vimrc
link_file .ls.awk
link_file .gitconfig

# Handle k3s configuration if available
if [ -f /etc/rancher/k3s/k3s.yaml ]; then
  echo "Setting up k3s kubectl configuration..."
  mkdir -p "$HOME/.kube"
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
if [ "$IS_RASPBERRY_PI" = true ]; then
  echo "Raspberry Pi OS configuration applied successfully!"
else
  echo "Debian configuration applied successfully!"
fi
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
