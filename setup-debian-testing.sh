#!/bin/bash
# Debian Testing Best Practices Setup
# This script configures APT sources and pinning for optimal Debian Testing experience

set -e

echo "=== Debian Testing Best Practices Setup ==="

# Check if we're actually on Debian Testing
if [ ! -f /etc/debian_version ]; then
    echo "❌ This script is for Debian systems only."
    exit 1
fi

# Check if running as root or with sudo
if [ "$EUID" -ne 0 ]; then
    echo "❌ This script needs to be run with sudo privileges for APT configuration."
    echo "Usage: sudo ./setup-debian-testing.sh"
    exit 1
fi

# Detect current Debian suite
CURRENT_SUITE=""
if [ -f /etc/apt/sources.list.d/debian.sources ]; then
    CURRENT_SUITE=$(grep -m1 "^Suites:" /etc/apt/sources.list.d/debian.sources | awk '{print $2}' || echo "")
elif [ -f /etc/apt/sources.list ]; then
    CURRENT_SUITE=$(grep -m1 "deb.*debian" /etc/apt/sources.list | awk '{print $3}' || echo "")
fi

echo "Detected Debian suite: ${CURRENT_SUITE:-unknown}"

# Warn if not on testing
  if [[ "$CURRENT_SUITE" != "testing" && "$CURRENT_SUITE" != "forky" ]]; then
    echo "⚠️  Warning: You don't appear to be running Debian Testing."
    echo "   Current suite detected: $CURRENT_SUITE"
    echo "   This setup is specifically for Debian Testing users."
    read -p "   Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Setup cancelled."
        exit 0
    fi
fi

echo "This will configure your system with Debian Testing best practices:"
echo "• Add unstable and experimental repositories (with lower priority)"
echo "• Configure APT pinning to prefer testing by default"
echo "• Set up automatic security updates from unstable for critical packages"
echo ""
read -p "Continue? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Setup cancelled."
    exit 0
fi

echo ""
echo "📦 Adding unstable and experimental sources..."

# Create unstable sources file
cat > /etc/apt/sources.list.d/unstable.sources << 'EOF'
# Unstable repository for newer packages when needed
Types: deb
URIs: http://deb.debian.org/debian/
Suites: unstable
Components: main
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg

# Experimental repository for bleeding-edge packages
Types: deb
URIs: http://deb.debian.org/debian/
Suites: experimental
Components: main
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg
EOF

echo "✓ Created /etc/apt/sources.list.d/unstable.sources"

echo ""
echo "📌 Configuring APT pinning preferences..."

# Create testing pinning preferences
cat > /etc/apt/preferences.d/testing << 'EOF'
# Prefer testing packages by default
Package: *
Pin: release a=testing
Pin-Priority: 900

# Make unstable available but with lower priority
Package: *
Pin: release a=unstable
Pin-Priority: 300

# Make experimental available but with lowest priority
Package: *
Pin: release a=experimental
Pin-Priority: 200
EOF

echo "✓ Created /etc/apt/preferences.d/testing"

# Create security pinning for critical packages
cat > /etc/apt/preferences.d/security << 'EOF'
# Security-critical packages that should get updates from unstable first
# These packages almost always have security updates in unstable before testing
Package: src:chromium src:firefox src:firefox-esr src:linux src:linux-signed-amd64
Explanation: these packages are always security updates updated in unstable first
Pin: release a=/^(unstable|unstable-debug|buildd-unstable|buildd-unstable-debug)$/
Pin-Priority: 980
EOF

echo "✓ Created /etc/apt/preferences.d/security"

echo ""
echo "🔄 Updating package lists..."
apt update

echo ""
echo "🎉 Debian Testing best practices setup complete!"
echo ""
echo "What this gives you:"
echo "• Testing packages by default (priority 900)"
echo "• Access to unstable packages when needed: apt install package/unstable"
echo "• Access to experimental packages: apt install package/experimental" 
echo "• Automatic security updates for browsers and kernel from unstable"
echo "• Faster security updates overall"
echo ""
echo "Usage examples:"
echo "• Regular update: apt upgrade (stays on testing)"
echo "• Install from unstable: apt install package-name/unstable"
echo "• Install from experimental: apt install package-name/experimental"
echo "• Check package versions: apt policy package-name"
echo ""
echo "Note: You can check which repository a package comes from with:"
echo "  apt policy package-name"