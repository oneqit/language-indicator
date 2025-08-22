#!/bin/bash

# Language Indicator 빌드 스크립트

echo "🔨 Swift 컴파일러로 Language Indicator 빌드 중..."

# 빌드 디렉토리 생성
mkdir -p build

# CPU 아키텍처 자동 감지
ARCH=$(uname -m)
if [ "$ARCH" = "arm64" ]; then
    TARGET="arm64-apple-macos14.0"
else
    TARGET="x86_64-apple-macos14.0"
fi

echo "🔧 타겟 아키텍처: $TARGET"

# swiftc로 컴파일
swiftc main.swift \
    -framework Cocoa \
    -framework Carbon \
    -o build/LanguageIndicator \
    -target $TARGET

if [ $? -eq 0 ]; then
    echo "✅ 빌드 성공!"
    echo "📍 실행 파일 위치: ./build/LanguageIndicator"
    echo ""
    echo "실행하려면:"
    echo "  ./build/LanguageIndicator"
    echo ""
    echo "또는 백그라운드 실행:"
    echo "  nohup ./build/LanguageIndicator > /dev/null 2>&1 &"
else
    echo "❌ 빌드 실패!"
    exit 1
fi
