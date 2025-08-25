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

print_info "🔍 Checking if the required compiler is installed..."
if ! command -v swiftc &> /dev/null; then
    print_error "Swift is not installed. Please install Xcode or Swift toolchain."
    print_info "To install:"
    print_info "  xcode-select --install"
    exit 1
fi

print_info "📂 Creating build directory..."
mkdir -p build

ARCH=$(uname -m)
if [ "$ARCH" = "arm64" ]; then
    TARGET="arm64-apple-macos14.0"
else
    TARGET="x86_64-apple-macos14.0"
fi

print_info "🔧 Target architecture: $TARGET"

print_info "🔨 Building..."
swiftc main.swift \
    -framework Cocoa \
    -framework Carbon \
    -o build/LanguageIndicator \
    -target $TARGET

if [ $? -eq 0 ]; then
    print_ok "Build succeeded!"
    print_info "📍 Executable location: ./build/LanguageIndicator"
else
    print_error "Build failed!"
    exit 1
fi
