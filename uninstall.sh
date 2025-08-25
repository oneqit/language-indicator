#!/bin/bash
# filepath: /Users/ethan.axz-pc/code/oneqit/language-indicator/uninstall.sh

set -e  # Exit on any error

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print() {
    echo -e "$1"
}

print_info() {
    print "${BLUE}$1${NC}"
}

print_ok() {
    print "${GREEN}✅ $1${NC}"
}

print_warning() {
    print "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    print "${RED}❌ $1${NC}"
}

# Configuration
INSTALL_DIR="$HOME/.language-indicator"
INSTALLED_EXECUTABLE="$INSTALL_DIR/LanguageIndicator"
LAUNCH_AGENT_DIR="$HOME/Library/LaunchAgents"
LAUNCH_AGENT_FILE="$LAUNCH_AGENT_DIR/com.oneqit.languageindicator.plist"
LABEL="com.oneqit.languageindicator"

print ""
print "=================================================="
print_info "🗑️  Language Indicator Uninstallation"
print "=================================================="
print ""

# Step 1: Check if service is running and stop it
if launchctl list | grep -q "$LABEL" 2>/dev/null; then
    print_info "Stopping Language Indicator service..."
    launchctl stop "$LABEL" 2>/dev/null || true
    sleep 1
    print_ok "Service stopped"
else
    print_info "Service is not currently running"
fi

# Step 2: Unload LaunchAgent
if [ -f "$LAUNCH_AGENT_FILE" ]; then
    print_info "Unloading LaunchAgent..."
    launchctl unload "$LAUNCH_AGENT_FILE" 2>/dev/null || true
    print_ok "LaunchAgent unloaded"
else
    print_info "LaunchAgent file not found"
fi

# Step 3: Remove LaunchAgent plist file
if [ -f "$LAUNCH_AGENT_FILE" ]; then
    print_info "Removing auto-start configuration..."
    rm -f "$LAUNCH_AGENT_FILE"
    print_ok "Auto-start configuration removed"
else
    print_info "Auto-start configuration not found"
fi

# Step 4: Remove installation directory
if [ -d "$INSTALL_DIR" ]; then
    print_info "Removing installation directory..."
    rm -rf "$INSTALL_DIR"
    print_ok "Installation directory removed: $INSTALL_DIR"
else
    print_info "Installation directory not found"
fi

# Step 5: Clean up log files
print_info "Cleaning up log files..."
if [ -f "/tmp/languageindicator.out" ]; then
    rm -f "/tmp/languageindicator.out"
    print_ok "Output log removed"
fi

if [ -f "/tmp/languageindicator.err" ]; then
    rm -f "/tmp/languageindicator.err"
    print_ok "Error log removed"
fi

# Step 6: Verify uninstallation
print_info "Verifying uninstallation..."
sleep 1

ISSUES_FOUND=false

if launchctl list | grep -q "$LABEL" 2>/dev/null; then
    print_warning "Service is still running"
    ISSUES_FOUND=true
fi

if [ -f "$LAUNCH_AGENT_FILE" ]; then
    print_warning "LaunchAgent file still exists"
    ISSUES_FOUND=true
fi

if [ -d "$INSTALL_DIR" ]; then
    print_warning "Installation directory still exists"
    ISSUES_FOUND=true
fi

if [ "$ISSUES_FOUND" = false ]; then
    print_ok "Uninstallation verified successfully"
else
    print_warning "Some components may still exist"
    print_info "You may need to manually remove remaining files"
fi

print ""
print "=================================================="
print_ok "🎉 Uninstallation Complete!"
print "=================================================="
print ""

if [ "$ISSUES_FOUND" = false ]; then
    print_info "Language Indicator has been completely removed from your system."
    print ""
    print_info "What was removed:"
    print "  • Service from launchctl"
    print "  • Auto-start configuration: $LAUNCH_AGENT_FILE"
    print "  • Installation directory: $INSTALL_DIR"
    print "  • Log files from /tmp"
    print ""
    print_info "Note: You may need to manually remove Language Indicator"
    print "      from Accessibility permissions in System Preferences"
    print "      if you no longer need those permissions."
else
    print_warning "Uninstallation completed with some issues."
    print ""
    print_info "If you encounter problems, try:"
    print "  • Restart your computer"
    print "  • Manually check System Preferences → Accessibility"
    print "  • Remove any remaining files manually"
fi

print ""
print_ok "Uninstall script completed!"