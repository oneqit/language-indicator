# Language Indicator for macOS

macOS에서 텍스트 필드 포커스 시 현재 입력 언어를 시각적으로 표시해주는 앱입니다. Swift로 작성되었으며 Xcode 없이 `swiftc`로 빌드할 수 있습니다.

## ✨ 주요 기능

- 🎯 마우스 클릭으로 텍스트 필드 포커스 시 언어 표시기 표시 ("한" / "A")
- 🖱️ 마우스 클릭 이벤트 기반 스마트 감지
- 🔄 동일 element 재클릭 시 중복 표시 방지
- ⏱️ 3초 쿨다운으로 과도한 표시 방지
- 💻 백그라운드 실행 및 로그인 시 자동 시작
- 🎨 macOS Sonoma 스타일 디자인

## 🚀 설치 및 실행

### 자동 설치 (권장)

```bash
# 빌드 및 자동 시작 설치
./install.sh
```

설치 완료 후:
- 로그인 시 자동 실행
- 백그라운드에서 동작
- 메뉴바에서 상태 확인 가능

### 제거

```bash
# 완전 제거
./uninstall.sh
```

### 수동 빌드 및 실행

```bash
# 1. 빌드
./build.sh

# 2. 수동 실행
./build/LanguageIndicator
```

## ⚙️ 설정

### 접근성 권한 설정 (필수)
처음 실행 시 접근성 권한이 필요합니다:

1. **시스템 환경설정** > **보안 및 개인정보보호** > **개인정보보호**
2. **접근성** 섹션에서 **LanguageIndicator** 허용

## 🔧 관리 명령어

### 서비스 상태 확인
```bash
# 실행 상태 확인
launchctl list | grep languageindicator

# 프로세스 확인
ps aux | grep LanguageIndicator
```

### 서비스 제어
```bash
# 서비스 중지
launchctl stop com.oneqit.languageindicator

# 서비스 시작
launchctl start com.oneqit.languageindicator

# 서비스 재시작
launchctl stop com.oneqit.languageindicator && sleep 1 && launchctl start com.oneqit.languageindicator
```

### 로그 확인
```bash
# 출력 로그 확인
tail -f /tmp/languageindicator.out

# 에러 로그 확인
tail -f /tmp/languageindicator.err

# 실시간 모니터링
tail -f /tmp/languageindicator.out /tmp/languageindicator.err
```

### 디버그 모드
```bash
# 디버그 모드로 실행 (서비스 중지 후)
launchctl stop com.oneqit.languageindicator
~/.language-indicator/LanguageIndicator -d
```

## 📁 설치 파일 위치

- **실행 파일**: `~/.language-indicator/LanguageIndicator`
- **자동 시작 설정**: `~/Library/LaunchAgents/com.oneqit.languageindicator.plist`
- **로그 파일**: `/tmp/languageindicator.out`, `/tmp/languageindicator.err`

## 🔧 기술 스택

- **Swift 5.0+**
- **Cocoa Framework** - UI 윈도우 관리
- **Carbon Framework** - 입력 소스 감지
- **Accessibility API** - 텍스트 필드 감지
- **NSEvent Global Monitor** - 마우스 클릭 감지
- **LaunchAgent** - 자동 시작 관리

## 📋 요구사항

- macOS 10.15 이상
- Swift 컴파일러 (Xcode Command Line Tools)
- 접근성 권한 허용
