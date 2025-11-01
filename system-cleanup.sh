#!/bin/bash
# system-cleanup.sh - Find and remove orphaned/unused packages
# Based on cleanup methodology developed through hands-on analysis
# Now with Raspberry Pi OS support

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Detect if running on Raspberry Pi OS
IS_RASPBERRY_PI=false
if [ -f /etc/rpi-issue ]; then
  IS_RASPBERRY_PI=true
fi

echo -e "${BLUE}=== System Cleanup Analysis ===${NC}"
if [ "$IS_RASPBERRY_PI" = true ]; then
  echo -e "${GREEN}Running on Raspberry Pi OS${NC}"
fi
echo ""

# Function to print colored headers
print_header() {
    echo -e "${BLUE}=== $1 ===${NC}"
}

# Function to print warnings
print_warning() {
    echo -e "${YELLOW}⚠ WARNING: $1${NC}"
}

# Function to print info
print_info() {
    echo -e "${GREEN}ℹ INFO: $1${NC}"
}

# 1. Analyze largest packages
print_header "Largest Packages (Top 20)"
dpkg-query -Wf '${Installed-Size}\t${Package}\n' | sort -n | tail -20
echo ""

# 2. Check for DKMS modules (affects kernel header safety)
print_header "DKMS Module Check"
if command -v dkms >/dev/null 2>&1; then
    DKMS_MODULES=$(dkms status 2>/dev/null || echo "No modules")
    if [[ "$DKMS_MODULES" != "No modules" ]] && [[ -n "$DKMS_MODULES" ]]; then
        print_warning "DKMS modules found - be careful removing kernel headers!"
        echo "$DKMS_MODULES"
        KEEP_HEADERS=true
    else
        print_info "No DKMS modules found - kernel headers can be safely removed"
        KEEP_HEADERS=false
    fi
elif [ -d /var/lib/dkms ]; then
    print_warning "DKMS directory exists but command not found - check manually"
    KEEP_HEADERS=true
else
    print_info "No DKMS installation detected"
    KEEP_HEADERS=false
fi
echo ""

# 3. Kernel analysis
print_header "Kernel Analysis"
CURRENT_KERNEL=$(uname -r)
echo "Current kernel: $CURRENT_KERNEL"
echo ""
echo "Installed kernels:"
dpkg -l | grep linux-image | while read line; do
    status=$(echo "$line" | awk '{print $1}')
    package=$(echo "$line" | awk '{print $2}')
    case $status in
        ii) echo -e "${GREEN}[INSTALLED]${NC} $package" ;;
        rc) echo -e "${YELLOW}[REMOVED-CONFIG]${NC} $package" ;;
        *) echo -e "${RED}[OTHER]${NC} $package ($status)" ;;
    esac
done
echo ""

# 4. Development tools analysis
print_header "Development Tools Analysis"
echo "GCC versions installed:"
dpkg -l | grep -E "^ii.*gcc" | awk '{print $2, $3}'
echo ""
if command -v gcc >/dev/null 2>&1; then
    echo "Default GCC version:"
    gcc --version | head -1
else
    echo "No GCC installed"
fi
echo ""

echo "Manually installed development packages:"
apt-mark showmanual | grep -E "(gcc|dev|build)" | head -10
echo ""

# 5. Check for GUI packages on potentially headless systems
print_header "GUI Package Check"
GUI_PACKAGES=$(apt list --installed 2>/dev/null | grep -E "(x11|gtk|desktop)" | head -5)
if [[ -n "$GUI_PACKAGES" ]]; then
    echo "GUI packages found:"
    echo "$GUI_PACKAGES"
    
    # Check if we're in a GUI session
    if [[ -z "$DISPLAY" ]] && [[ -z "$WAYLAND_DISPLAY" ]]; then
        print_warning "GUI packages found but no display detected - might be removable on headless system"
    fi
else
    print_info "No major GUI packages detected"
fi
echo ""

# 6. Suggest cleanup commands
print_header "Suggested Cleanup Commands"

# For Raspberry Pi, be more conservative with kernel removal
if [ "$IS_RASPBERRY_PI" = true ]; then
    echo "1. Raspberry Pi kernel cleanup (keep current + 1 backup):"
    echo "   Note: Raspberry Pi uses custom kernels, be cautious"
    dpkg -l | grep linux-image | grep "^ii" | grep -v "$CURRENT_KERNEL" | grep -v "linux-image-" | head -n -1 | awk '{print $2}' | while read kernel; do
        echo "   sudo apt remove $kernel"
    done
else
    echo "1. Remove old kernels (keep current + 1 backup):"
    dpkg -l | grep linux-image | grep "^ii" | grep -v "$CURRENT_KERNEL" | grep -v "linux-image-amd64" | head -n -1 | awk '{print $2}' | while read kernel; do
        echo "   sudo apt remove $kernel"
    done
fi

echo ""
echo "2. Clean up removed package configs:"
CONFIG_PACKAGES=$(dpkg -l | grep "^rc" | awk '{print $2}' | head -5)
if [[ -n "$CONFIG_PACKAGES" ]]; then
    echo "   sudo apt purge \$(dpkg -l | grep '^rc' | awk '{print \$2}')"
else
    echo "   No config files to clean"
fi

echo ""
echo "3. Remove unused packages:"
echo "   sudo apt autoremove --purge"

echo ""
echo "4. GCC cleanup (if multiple versions):"
GCC_COUNT=$(dpkg -l | grep -c "^ii.*gcc-[0-9]" || echo "0")
if [[ "$GCC_COUNT" -gt 1 ]]; then
    echo "   # Check which GCC is default, then remove older versions"
    echo "   # Example: sudo apt remove gcc-14-base (if using GCC 15)"
else
    echo "   No multiple GCC versions detected"
fi

echo ""
if [[ "$KEEP_HEADERS" == "false" ]]; then
    if [ "$IS_RASPBERRY_PI" = true ]; then
        echo "5. Remove Raspberry Pi kernel headers (safe - no DKMS):"
        echo "   sudo apt remove raspberrypi-kernel-headers"
    else
        echo "5. Remove kernel headers (safe - no DKMS):"
        echo "   sudo apt remove linux-headers-*"
    fi
else
    print_warning "5. Keep kernel headers (DKMS modules present)"
fi

echo ""
print_header "Prevention Tips"
echo "• Use 'sudo apt full-upgrade' instead of 'sudo apt upgrade'"
echo "• Run 'sudo apt autoremove --purge' after updates"
if [ "$IS_RASPBERRY_PI" = false ]; then
    echo "• Configure automatic kernel cleanup:"
    echo "  echo 'APT::AutoRemove::KernelsKeep \"2\";' | sudo tee /etc/apt/apt.conf.d/01autoremove-kernels"
fi
echo ""
echo "• Monthly check with this script to catch accumulation early"

echo ""
print_header "Interactive Cleanup"
read -p "Do you want to run automatic cleanup now? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Running safe automatic cleanup..."
    
    # Always safe operations
    echo "Cleaning package cache..."
    sudo apt autoclean
    
    echo "Removing unused packages..."
    sudo apt autoremove --purge
    
    # Clean up config files from removed packages
    CONFIG_PKGS=$(dpkg -l | grep "^rc" | awk '{print $2}')
    if [[ -n "$CONFIG_PKGS" ]]; then
        echo "Cleaning up leftover config files..."
        echo "$CONFIG_PKGS" | xargs sudo apt purge -y
    fi
    
    echo ""
    print_info "Safe cleanup completed. Review suggested manual cleanups above."
else
    echo "Skipping automatic cleanup. Review suggestions above."
fi

echo ""
print_header "Cleanup Complete"
echo "For more aggressive cleanup, review the suggested commands above."
echo "Always verify what will be removed before proceeding with manual removals."
if [ "$IS_RASPBERRY_PI" = true ]; then
    echo ""
    echo "Note: Raspberry Pi uses custom kernels - be especially careful with kernel packages."
fi
