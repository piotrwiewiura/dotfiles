#!/bin/bash
# Debian Testing Best Practices Setup
# This script configures APT sources and pinning for optimal Debian Testing experience

set -e

echo "=== Debian Testing Best Practices Setup ==="

# Check if we're actually on Debian
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

# Detect current Debian suite and format
CURRENT_SUITE=""
SOURCES_FORMAT=""

if [ -f /etc/apt/sources.list.d/debian.sources ]; then
    # Modern DEB822 format
    SOURCES_FORMAT="modern"
    CURRENT_SUITE=$(grep -m1 "^Suites:" /etc/apt/sources.list.d/debian.sources 2>/dev/null | awk '{print $2}' || echo "")
elif [ -f /etc/apt/sources.list ]; then
    # Legacy format
    SOURCES_FORMAT="legacy"
    CURRENT_SUITE=$(grep -m1 "^deb.*debian" /etc/apt/sources.list 2>/dev/null | awk '{print $3}' || echo "")
else
    echo "❌ Could not find APT sources configuration."
    exit 1
fi

echo "Detected:"
echo "• Debian suite: ${CURRENT_SUITE:-unknown}"
echo "• Sources format: $SOURCES_FORMAT"
echo ""

# Handle upgrade from stable to testing
if [[ "$CURRENT_SUITE" == "stable" || "$CURRENT_SUITE" == "trixie" || "$CURRENT_SUITE" == "bookworm" ]]; then
    echo "🚀 You're currently on Debian Stable ($CURRENT_SUITE)."
    echo "This script can upgrade you to Debian Testing for the latest packages."
    echo ""
    echo "⚠️  WARNING: This will change your system to a development branch!"
    echo "   • Testing is less stable than stable"
    echo "   • You'll get newer software but potentially more bugs"
    echo "   • This is recommended for developers/power users"
    echo ""
    read -p "Upgrade from stable to testing? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Staying on stable. Exiting."
        exit 0
    fi
    
    echo ""
    echo "🔄 Upgrading from stable to testing..."
    
    if [ "$SOURCES_FORMAT" = "legacy" ]; then
        echo "📝 Modernizing APT sources format..."
        # Backup original sources.list
        cp /etc/apt/sources.list /etc/apt/sources.list.backup
        
        # Create modern debian.sources file
        cat > /etc/apt/sources.list.d/debian.sources << 'EOF'
# Modernized from /etc/apt/sources.list
Types: deb deb-src
URIs: http://deb.debian.org/debian/
Suites: testing
Components: main contrib non-free non-free-firmware
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg

# Modernized from /etc/apt/sources.list
Types: deb deb-src
URIs: http://security.debian.org/debian-security/
Suites: testing-security
Components: main contrib non-free non-free-firmware
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg
EOF
        
        # Comment out original sources.list
        sed -i 's/^deb/#deb/g' /etc/apt/sources.list
        echo "✓ Modernized to DEB822 format and upgraded to testing"
        echo "✓ Original sources.list backed up and commented out"
        
    else
        # Modern format - just update existing file
        echo "📝 Updating existing modern sources to testing..."
        sed -i 's/stable/testing/g' /etc/apt/sources.list.d/debian.sources
        sed -i 's/trixie/testing/g' /etc/apt/sources.list.d/debian.sources
        sed -i 's/bookworm/testing/g' /etc/apt/sources.list.d/debian.sources
        sed -i 's/trixie-security/testing-security/g' /etc/apt/sources.list.d/debian.sources
        sed -i 's/bookworm-security/testing-security/g' /etc/apt/sources.list.d/debian.sources
        echo "✓ Updated existing sources to testing"
    fi
    
    echo ""
    echo "🔄 Updating package lists after upgrade to testing..."
    apt-get update
    
    echo ""
    echo "📦 Upgrading packages to testing versions..."
    echo "This may take a while and download a lot of data..."
    echo ""
    read -p "Continue with package upgrade? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        # Show what will be upgraded
        echo "Packages to be upgraded:"
        apt-get upgrade --dry-run | grep "^Inst" | head -10
        echo ""
        if [ $(apt-get upgrade --dry-run | grep "^Inst" | wc -l) -gt 10 ]; then
            echo "... and $(( $(apt-get upgrade --dry-run | grep "^Inst" | wc -l) - 10 )) more packages"
            echo ""
        fi
        
        read -p "Proceed with upgrade? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            apt-get upgrade -y
            apt-get full-upgrade -y
            echo "✅ Package upgrade complete!"
        else
            echo "⚠️  Sources updated but packages not upgraded."
            echo "   Run 'sudo apt-get upgrade && sudo apt-get full-upgrade' later to complete the upgrade."
        fi
    else
        echo "⚠️  Sources updated but packages not upgraded."
        echo "   Run 'sudo apt-get upgrade && sudo apt-get full-upgrade' later to complete the upgrade."
    fi
    
    echo ""
    echo "✅ Successfully upgraded to Debian Testing!"
    echo ""
    CURRENT_SUITE="testing"
fi

# Continue with testing best practices if we're on testing
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

# Create unstable sources file (only if it doesn't already exist)
if [ ! -f /etc/apt/sources.list.d/unstable.sources ]; then
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
else
    echo "✓ /etc/apt/sources.list.d/unstable.sources already exists"
fi

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
apt-get update

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