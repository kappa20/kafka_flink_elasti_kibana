#!/bin/bash

# Sublime Text Installation Script for Ubuntu
# Installs the latest stable version of Sublime Text

set -e

# Color codes for better readability
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored messages
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

echo "============================================"
echo "Sublime Text Installation Script"
echo "Ubuntu/Debian Systems"
echo "============================================"
echo ""

# Check if running on Linux
if [ ! -f /etc/os-release ]; then
    print_error "Cannot detect OS. This script is for Linux systems."
    exit 1
fi

# Load OS information
. /etc/os-release

# Check if running as root or with sudo
if [ "$EUID" -ne 0 ]; then
    print_error "This script requires sudo privileges."
    print_info "Please run with: sudo ./install-sublime-text.sh"
    exit 1
fi

# Get the actual user (not root) for final message
ACTUAL_USER="${SUDO_USER:-$USER}"

print_info "Detected: $PRETTY_NAME"
echo ""

# Check if Sublime Text is already installed
if command -v subl &> /dev/null; then
    CURRENT_VERSION=$(subl --version 2>/dev/null | head -n1 || echo "Unknown version")
    print_warn "Sublime Text is already installed: $CURRENT_VERSION"
    echo ""
    read -p "Do you want to reinstall/update it? [y/N]: " REINSTALL
    REINSTALL=${REINSTALL:-N}

    if [[ ! "$REINSTALL" =~ ^[Yy]$ ]]; then
        print_info "Installation cancelled."
        exit 0
    fi
    echo ""
fi

print_step "Starting Sublime Text installation..."
echo ""

# Step 1: Install required packages
print_step "1/5: Installing prerequisites..."
apt-get update -qq
apt-get install -y wget gpg apt-transport-https
print_info "Prerequisites installed"
echo ""

# Step 2: Add Sublime Text GPG key
print_step "2/5: Adding Sublime Text GPG key..."
wget -qO - https://download.sublimetext.com/sublimehq-pub.gpg | gpg --dearmor -o /usr/share/keyrings/sublimehq-archive-keyring.gpg
print_info "GPG key added"
echo ""

# Step 3: Add Sublime Text repository
print_step "3/5: Adding Sublime Text repository..."
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/sublimehq-archive-keyring.gpg] https://download.sublimetext.com/ apt/stable/" | tee /etc/apt/sources.list.d/sublime-text.list > /dev/null
print_info "Repository added"
echo ""

# Step 4: Update package list
print_step "4/5: Updating package index..."
apt-get update -qq
print_info "Package index updated"
echo ""

# Step 5: Install Sublime Text
print_step "5/5: Installing Sublime Text..."
apt-get install -y sublime-text
print_info "Sublime Text installed successfully"
echo ""

# Verify installation
print_step "Verifying installation..."
if command -v subl &> /dev/null; then
    VERSION=$(subl --version 2>/dev/null | head -n1)
    print_info "✓ $VERSION"
else
    print_error "Installation verification failed!"
    exit 1
fi
echo ""

echo "============================================"
echo "Sublime Text Installation Complete!"
echo "============================================"
echo ""
print_info "Installed version:"
subl --version | head -n1
echo ""

print_info "How to use Sublime Text:"
echo "  • Launch GUI:           ${GREEN}subl${NC}"
echo "  • Open a file:          ${GREEN}subl filename.txt${NC}"
echo "  • Open a folder:        ${GREEN}subl /path/to/folder${NC}"
echo "  • Open from terminal:   ${GREEN}subl .${NC} (opens current directory)"
echo ""

print_info "Useful Sublime Text shortcuts:"
echo "  • Command Palette:      Ctrl+Shift+P"
echo "  • Quick Open:           Ctrl+P"
echo "  • Multi-cursor:         Ctrl+Click"
echo "  • Select All:           Ctrl+D (multiple times)"
echo "  • Comment line:         Ctrl+/"
echo "  • Duplicate line:       Ctrl+Shift+D"
echo ""

print_info "Additional features:"
echo "  • Package Control:      Install via Command Palette"
echo "  • Preferences:          Menu > Preferences > Settings"
echo "  • Themes:               Menu > Preferences > Color Scheme"
echo ""

echo "To launch Sublime Text, run: ${GREEN}subl${NC}"
echo "============================================"
