#!/bin/bash

# Language Indicator - Uninstaller
# Completely removes Language Indicator from the system

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
LAUNCH_AGENT_FILE="$HOME/Library/LaunchAgents/com.oneqit.languageindicator.plist"
LABEL="com.oneqit.languageindicator"

echo -e "${BLUE}🗑️  Language Indicator - Uninstaller${NC}"
echo "=================================================="

# Function to print status
print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# Step 1: Stop and unload service
if launchctl list | grep -q "$LABEL" 2>/dev/null; then
    print_warning "Stopping Language Indicator service..."
    launchctl stop "$LABEL" 2>/dev/null || true
    print_status "Service stopped"
fi

if [ -f "$LAUNCH_AGENT_FILE" ]; then
    print_warning "Removing auto-start configuration..."
    launchctl unload "$LAUNCH_AGENT_FILE" 2>/dev/null || true
    rm "$LAUNCH_AGENT_FILE"
    print_status "Auto-start configuration removed"
fi

# Step 2: Clean up log files
for log_file in "/tmp/languageindicator.out" "/tmp/languageindicator.err"; do
    if [ -f "$log_file" ]; then
        rm "$log_file"
        print_status "Removed log file: $(basename "$log_file")"
    fi
done

echo ""
echo "=================================================="
echo -e "${GREEN}🎉 Uninstall Complete!${NC}"
echo ""
echo "Language Indicator has been completely removed from your system."
echo "You can safely delete this directory: ~/.language-indicator"
echo ""
echo "To reinstall, run:"
echo "  git clone <repo-url> ~/.language-indicator"
echo "  cd ~/.language-indicator && ./install.sh"