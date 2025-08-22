#!/bin/bash

# Language Indicator - One-Click Installer
# Builds, installs, and sets up auto-start for Language Indicator

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="$PROJECT_DIR/build"
EXECUTABLE_PATH="$BUILD_DIR/LanguageIndicator"
LAUNCH_AGENT_DIR="$HOME/Library/LaunchAgents"
LAUNCH_AGENT_FILE="$LAUNCH_AGENT_DIR/com.oneqit.languageindicator.plist"
LABEL="com.oneqit.languageindicator"

echo -e "${BLUE}🚀 Language Indicator - One-Click Installer${NC}"
echo "=================================================="

# Function to print status
print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Step 1: Check Swift installation
print_info "Checking Swift installation..."
if ! command -v swift &> /dev/null; then
    print_error "Swift is not installed. Please install Xcode or Swift toolchain."
    exit 1
fi
print_status "Swift is available"

# Step 2: Build the project
print_info "Building Language Indicator..."
swift build -c release

if [ ! -f ".build/release/LanguageIndicator" ]; then
    print_error "Build failed. Please check for compilation errors."
    exit 1
fi

# Create build directory and copy executable
mkdir -p "$BUILD_DIR"
cp ".build/release/LanguageIndicator" "$EXECUTABLE_PATH"
print_status "Build completed successfully"

# Step 3: Stop existing service if running
if launchctl list | grep -q "$LABEL" 2>/dev/null; then
    print_warning "Stopping existing Language Indicator service..."
    launchctl stop "$LABEL" 2>/dev/null || true
    launchctl unload "$LAUNCH_AGENT_FILE" 2>/dev/null || true
fi

# Step 4: Create LaunchAgent
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
        <string>$EXECUTABLE_PATH</string>
    </array>
    
    <key>RunAtLoad</key>
    <true/>
    
    <key>KeepAlive</key>
    <dict>
        <key>Crashed</key>
        <true/>
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
</dict>
</plist>
EOF

print_status "Auto-start configuration created"

# Step 5: Load and start service
print_info "Starting Language Indicator service..."
launchctl load "$LAUNCH_AGENT_FILE"
launchctl start "$LABEL"

# Step 6: Verify installation
sleep 2
if launchctl list | grep -q "$LABEL" 2>/dev/null; then
    print_status "Service is running successfully!"
else
    print_error "Service failed to start. Check logs at /tmp/languageindicator.err"
    exit 1
fi

# Step 7: Request accessibility permissions
print_info "Requesting accessibility permissions..."
echo ""
echo "⚠️  IMPORTANT: Language Indicator needs Accessibility permissions to work."
echo "   If a permission dialog appears, please grant access."
echo "   You can also manually enable it in:"
echo "   System Preferences > Security & Privacy > Privacy > Accessibility"
echo ""

echo "=================================================="
echo -e "${GREEN}🎉 Installation Complete!${NC}"
echo ""
echo "Language Indicator is now running and will start automatically on login."
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Grant Accessibility permissions if prompted"
echo "2. Test by switching between text fields"
echo "3. Look for language indicator (한/A) at your cursor"
echo ""
echo -e "${BLUE}Management commands:${NC}"
echo "  Status:    launchctl list | grep languageindicator"
echo "  Stop:      launchctl stop $LABEL"
echo "  Restart:   launchctl stop $LABEL && launchctl start $LABEL"
echo "  Uninstall: ./uninstall.sh"
echo ""
echo -e "${BLUE}Logs:${NC}"
echo "  Output: tail -f /tmp/languageindicator.out"
echo "  Errors: tail -f /tmp/languageindicator.err"