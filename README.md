# Language Indicator for macOS

macOS에서 현재 입력 언어를 시각적으로 표시해주는 앱입니다. Swift로 작성되었으며 Xcode 없이 `swiftc`로 빌드할 수 있습니다.

## ✨ 주요 기능

- 🎯 마우스 커서 근처에 언어 표시기 표시 ("한" / "A")
- ⚡ 앱 포커싱 변경 이벤트 기반 모니터링
- 💻 백그라운드 실행
- ⏱️ 1.5초 후 자동 숨김

## 🚀 빌드 및 실행

### 1. 빌드
```bash
./build.sh
```

### 2. 실행
```bash
# 포그라운드 실행 (터미널에서 Ctrl+C로 종료)
./build/LanguageIndicator

# 백그라운드 실행
nohup ./build/LanguageIndicator > /dev/null 2>&1 &
```

### 3. 프로세스 관리
```bash
# 실행 중인 프로세스 확인
ps aux | grep LanguageIndicator

# 프로세스 종료
pkill -f LanguageIndicator
```

## ⚙️ 설정

### 접근성 권한 설정
처음 실행 시 접근성 권한이 필요합니다:

1. **시스템 환경설정** > **보안 및 개인정보보호** > **개인정보보호**
2. **접근성** 섹션에서 **LanguageIndicator** (또는 **Terminal**) 허용
3. 앱 재시작

## 📱 사용법

1. 앱 실행 후 백그라운드에서 대기
2. 포커스 전환 시 자동 표시
3. 1.5초 후 자동으로 사라짐

## 🏗️ 프로젝트 구조

```
language-indicator/
├── main.swift          # 메인 소스 코드 (리팩토링됨)
├── build.sh           # 빌드 스크립트
├── build/             # 빌드 결과물
└── README.md          # 문서
```

## 🔧 기술 스택

- **Swift 5.0+**
- **Cocoa Framework** - UI 윈도우 관리
- **Carbon Framework** - 입력 소스 감지
- **Accessibility API** - 텍스트 필드 감지
- **NSDistributedNotificationCenter** - 이벤트 기반 모니터링

## 📋 요구사항

- macOS 14.0 이상
- Swift 컴파일러 (Xcode Command Line Tools)
