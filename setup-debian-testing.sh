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
if [[ "$CURRENT_SUITE" != "testing" ]]; then
    echo "🚀 You're currently on Debian $CURRENT_SUITE."
    echo "This script can upgrade you to Debian Testing for the latest packages."
    echo ""
    echo "⚠️  WARNING: This will change your system to a development branch!"
    echo "   • Testing is less stable than stable releases"
    echo "   • You'll get newer software but potentially more bugs"
    echo "   • This is recommended for developers/power users"
    echo ""
    read -p "Upgrade to testing? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Staying on $CURRENT_SUITE. Exiting."
        exit 0
    fi
    
    echo ""
    echo "🔄 Upgrading to testing..."
    
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
        # Modern format - update to testing while preserving security suffix
        echo "📝 Updating existing modern sources to testing..."
        
        # Update main repositories (not security)
        sed -i '/security/!s/^Suites: .*/Suites: testing/' /etc/apt/sources.list.d/debian.sources
        
        # Update security repositories specifically
        sed -i 's/^Suites: .*-security$/Suites: testing-security/' /etc/apt/sources.list.d/debian.sources
        
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

# Continue with testing best practices setup
echo "This wi