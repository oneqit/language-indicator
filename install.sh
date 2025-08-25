#!/bin/bash

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
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="$PROJECT_DIR/build"
EXECUTABLE_PATH="$BUILD_DIR/LanguageIndicator"
INSTALL_DIR="$HOME/.language-indicator"
INSTALLED_EXECUTABLE="$INSTALL_DIR/LanguageIndicator"
LAUNCH_AGENT_DIR="$HOME/Library/LaunchAgents"
LAUNCH_AGENT_FILE="$LAUNCH_AGENT_DIR/com.oneqit.languageindicator.plist"
LABEL="com.oneqit.languageindicator"

cd "$PROJECT_DIR"
source build.sh

if [ ! -f "build/LanguageIndicator" ]; then
    print_error "Build failed. Please check for compilation errors."
    exit 1
fi

if launchctl list | grep -q "$LABEL" 2>/dev/null; then
    print_warning "Service already exists. Stopping existing service..."
    launchctl stop "$LABEL" 2>/dev/null || true
    launchctl unload "$LAUNCH_AGENT_FILE" 2>/dev/null || true
    sleep 1
fi

print_info "Installing to ~/.language-indicator..."
mkdir -p "$INSTALL_DIR"
cp "$EXECUTABLE_PATH" "$INSTALLED_EXECUTABLE"
chmod +x "$INSTALLED_EXECUTABLE"
print_ok "Executable installed to $INSTALLED_EXECUTABLE"

print_info "Setting up auto-start service..."
mkdir -p "$LAUNCH_AGENT_DIR"

cat > "$LAUNCH_AGENT_FILE" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>$LABEL</string>
    
    <key>ProgramArguments</key>
    <array>
        <string>$INSTALLED_EXECUTABLE</string>
    </array>
    
    <key>RunAtLoad</key>
    <true/>
    
    <key>KeepAlive</key>
    <dict>
        <key>Crashed</key>
        <true/>
        <key>SuccessfulExit</key>
        <false/>
    </dict>
    
    <key>ProcessType</key>
    <string>Interactive</string>
    
    <key>StandardOutPath</key>
    <string>/tmp/languageindicator.out</string>
    
    <key>StandardErrorPath</key>
    <string>/tmp/languageindicator.err</string>
    
    <key>EnvironmentVariables</key>
    <dict>
        <key>PATH</key>
        <string>/usr/local/bin:/usr/bin:/bin</string>
    </dict>
    
    <key>LSUIElement</key>
    <true/>
</dict>
</plist>
EOF

print_ok "Auto-start configuration created"

# Step 8: Load and start service
print_info "Loading and starting Language Indicator service..."
launchctl load "$LAUNCH_AGENT_FILE"
sleep 1
launchctl start "$LABEL"

# Step 9: Verify installation
sleep 2
if launchctl list | grep -q "$LABEL" 2>/dev/null; then
    print_ok "Service is running successfully!"
else
    print_warning "Service may not have started properly. Checking logs..."
    if [ -f "/tmp/languageindicator.err" ]; then
        print_info "Error log contents:"
        tail -n 5 /tmp/languageindicator.err
    fi
fi

# Step 10: Check for accessibility permissions
print_info "Checking accessibility permissions..."
print ""
print_warning "IMPORTANT: Language Indicator needs Accessibility permissions to work."
print ""
print "If the app doesn't work immediately, please:"
print "1. Open System Preferences/Settings"
print "2. Go to Security & Privacy → Privacy → Accessibility"
print "3. Add or enable the Language Indicator app"
print ""
print ""
print "=================================================="
print_ok "🎉 Installation Complete!"
print "=================================================="
print ""
print_info "Language Indicator is now running and will start automatically on login."
print ""
print_info "Installation location:"
print "  Executable: $INSTALLED_EXECUTABLE"
print "  Config: $LAUNCH_AGENT_FILE"
print ""
print_info "Management commands:"
print "  Check status: launchctl list | grep languageindicator"
print "  Stop service: launchctl stop $LABEL"
print "  Start service: launchctl start $LABEL"
print "  Restart: launchctl stop $LABEL && sleep 1 && launchctl start $LABEL"
print "  Uninstall: ./uninstall.sh"
print ""
# print_info "Logs:"
# print "  Output: tail -f /tmp/languageindicator.out"
# print "  Errors: tail -f /tmp/languageindicator.err"
# print "  Live monitoring: tail -f /tmp/languageindicator.out /tmp/languageindicator.err"
# print ""
# print_info "Debug mode:"
# print "  Enable debug: launchctl stop $LABEL && $INSTALLED_EXECUTABLE -d"
# print "  (Press Ctrl+C to stop debug mode)"
# print ""

print_ok "Installation script completed!"
