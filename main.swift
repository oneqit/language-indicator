import Cocoa
import Carbon

// MARK: - Global Variables
var globalLanguageIndicator: LanguageIndicator?
var isDebugMode = false

// MARK: - Debug Utility
func debugPrint(_ message: String) {
    if isDebugMode {
        print(message)
    }
}

// MARK: - Menu Bar Manager
class MenuBarManager {
    private var statusItem: NSStatusItem?
    private var languageIndicator: LanguageIndicator?
    
    init(languageIndicator: LanguageIndicator) {
        self.languageIndicator = languageIndicator
        setupStatusItem()
    }
    
    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            // 메뉴바에 표시할 아이콘 (언어 표시 아이콘)
            button.title = "한/A"
            button.font = NSFont.systemFont(ofSize: 12)
        }
        
        setupMenu()
        debugPrint("📍 Menu bar icon added")
    }
    
    private func setupMenu() {
        let menu = NSMenu()
        
        // 현재 상태 표시 (비활성화된 메뉴 아이템) - 변수명 변경
        let statusMenuItem = NSMenuItem(title: "Language Indicator", action: nil, keyEquivalent: "")
        statusMenuItem.isEnabled = false
        menu.addItem(statusMenuItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // 종료 메뉴
        let quitItem = NSMenuItem(title: "Quit Language Indicator", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
        
        statusItem?.menu = menu
    }
    
    @objc private func quitApp() {
        debugPrint("👋 Quitting from menu bar...")
        NSApplication.shared.terminate(nil)
    }
    
    func updateMenuBarIcon(with language: String) {
        if let button = statusItem?.button {
            button.title = language
        }
    }
    
    deinit {
        debugPrint("🔄 Cleaning up Menu Bar Manager")
        statusItem = nil
    }
}

// MARK: - Language Indicator Main Class
class LanguageIndicator {
    // MARK: - Properties
    private var currentInputSource: String = ""
    private var indicatorWindow: NSWindow?
    private var fadeTimer: Timer?
    private var menuBarManager: MenuBarManager?
    private var mouseEventMonitor: Any?
    private var lastIndicatorTime: Date?
    private let indicatorCooldownInterval: TimeInterval = 2.0
    private var lastFocusedElementIdentifier: String?
    
    // MARK: - Initialization
    init() {
        updateCurrentInputSource()
        setupEventMonitoring()
        setupMenuBar()
        debugPrint("✅ Language Indicator initialized with mouse click monitoring")
    }
    
    private func setupMenuBar() {
        menuBarManager = MenuBarManager(languageIndicator: self)
    }
    
    // MARK: - Event Monitoring Setup
    private func setupEventMonitoring() {
        setupInputSourceMonitoring()
        setupMouseClickMonitoring()
        debugPrint("🖱️ Mouse click monitoring enabled")
    }
    
    private func setupInputSourceMonitoring() {
        // Monitor input source changes
        DistributedNotificationCenter.default.addObserver(
            self,
            selector: #selector(inputSourceChanged),
            name: NSNotification.Name(rawValue: kTISNotifySelectedKeyboardInputSourceChanged as String),
            object: nil
        )
    }
    
    @objc private func inputSourceChanged() {
        DispatchQueue.main.async { [weak self] in
            self?.updateCurrentInputSource()
        }
    }
    
    private func setupMouseClickMonitoring() {
        // 마우스 클릭 이벤트 모니터링
        mouseEventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown]) { [weak self] event in
            debugPrint("🖱️ Mouse click detected")
            // 짧은 지연 후 포커스 확인 (포커스 변경이 완료되도록)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self?.checkForTextFieldFocusAfterClick(clickLocation: event.locationInWindow)
            }
        }
    }
    
    // 마우스 클릭 후 텍스트 필드 포커스 확인
    private func checkForTextFieldFocusAfterClick(clickLocation: CGPoint) {
        let systemWideElement = AXUIElementCreateSystemWide()
        var focusedElement: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(systemWideElement, kAXFocusedUIElementAttribute as CFString, &focusedElement)
        
        if result == .success, let element = focusedElement {
            let currentElement = element as! AXUIElement
            
            if isTextInputElement(currentElement) {
                let currentElementIdentifier = getElementIdentifier(currentElement)
                debugPrint("⌨️ Text field focused after click - identifier: \(currentElementIdentifier)")
                
                // 이전과 다른 element인지 확인
                if hasElementChanged(newIdentifier: currentElementIdentifier) {
                    debugPrint("🔄 Element changed - checking cooldown")
                    
                    // 쿨다운 확인
                    if canShowIndicator() {
                        let mouseLocation = NSEvent.mouseLocation
                        showLanguageIndicatorAt(location: mouseLocation)
                        lastFocusedElementIdentifier = currentElementIdentifier
                    } else {
                        debugPrint("⏰ Indicator cooldown active - skipping display")
                    }
                } else {
                    debugPrint("🔄 Same element focused - skipping indicator")
                }
            } else {
                debugPrint("💭 Non-text element focused after click - skipping indicator")
                // 텍스트 element가 아닌 경우 마지막 식별자 초기화
                lastFocusedElementIdentifier = nil
            }
        } else {
            debugPrint("💭 No focused element after click")
            lastFocusedElementIdentifier = nil
        }
    }
    
    // MARK: - Element Change Detection
    private func getElementIdentifier(_ element: AXUIElement) -> String {
        // Try to get identifier attribute first
        var identifierValue: CFTypeRef?
        let identifierResult = AXUIElementCopyAttributeValue(element, kAXIdentifierAttribute as CFString, &identifierValue)
        if identifierResult == .success, let identifier = identifierValue as? String, !identifier.isEmpty {
            return "id:\(identifier)"
        }
        
        // Fallback to combination of title, placeholder, and position
        var fallbackIdentifier = ""
        
        // Get title
        var titleValue: CFTypeRef?
        let titleResult = AXUIElementCopyAttributeValue(element, kAXTitleAttribute as CFString, &titleValue)
        if titleResult == .success, let title = titleValue as? String, !title.isEmpty {
            fallbackIdentifier += "title:\(title)"
        }
        
        // Get placeholder
        var placeholderValue: CFTypeRef?
        let placeholderResult = AXUIElementCopyAttributeValue(element, kAXPlaceholderValueAttribute as CFString, &placeholderValue)
        if placeholderResult == .success, let placeholder = placeholderValue as? String, !placeholder.isEmpty {
            if !fallbackIdentifier.isEmpty { fallbackIdentifier += "|" }
            fallbackIdentifier += "placeholder:\(placeholder)"
        }
        
        // Get position as fallback
        var positionValue: CFTypeRef?
        let positionResult = AXUIElementCopyAttributeValue(element, kAXPositionAttribute as CFString, &positionValue)
        if positionResult == .success, let position = positionValue {
            var point = CGPoint.zero
            if AXValueGetValue(position as! AXValue, .cgPoint, &point) {
                if !fallbackIdentifier.isEmpty { fallbackIdentifier += "|" }
                fallbackIdentifier += "pos:\(Int(point.x)),\(Int(point.y))"
            }
        }
        
        // If still empty, use element pointer as last resort
        if fallbackIdentifier.isEmpty {
            fallbackIdentifier = "ptr:\(Unmanaged.passUnretained(element).toOpaque())"
        }
        
        return fallbackIdentifier
    }
    
    private func hasElementChanged(newIdentifier: String) -> Bool {
        guard let lastIdentifier = lastFocusedElementIdentifier else {
            // 첫 번째 포커스인 경우
            return true
        }
        
        let hasChanged = lastIdentifier != newIdentifier
        if hasChanged {
            debugPrint("🔄 Element changed from '\(lastIdentifier)' to '\(newIdentifier)'")
        } else {
            debugPrint("🔄 Same element: '\(newIdentifier)'")
        }
        
        return hasChanged
    }
    
    // MARK: - Cooldown Management
    private func canShowIndicator() -> Bool {
        guard let lastTime = lastIndicatorTime else {
            return true
        }
        
        let timeSinceLastIndicator = Date().timeIntervalSince(lastTime)
        let canShow = timeSinceLastIndicator >= indicatorCooldownInterval
        
        if !canShow {
            let remainingTime = indicatorCooldownInterval - timeSinceLastIndicator
            debugPrint("⏰ Cooldown active: \(String(format: "%.1f", remainingTime))s remaining")
        }
        
        return canShow
    }
    
    private func recordIndicatorShown() {
        lastIndicatorTime = Date()
        debugPrint("⏰ Indicator cooldown started (2 seconds)")
    }
    
    // MARK: - Focus Detection
    private func isTextInputElement(_ element: AXUIElement) -> Bool {
        var roleValue: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(element, kAXRoleAttribute as CFString, &roleValue)
        
        if result == .success, let role = roleValue as? String {
            let textRoles = ["AXTextField", "AXTextArea", "AXComboBox", "AXStaticText", "AXSecureTextField"]
            let isTextElement = textRoles.contains(role)
            debugPrint("🔍 Element role: \(role), isTextElement: \(isTextElement)")
            return isTextElement
        }
        
        debugPrint("🔍 Failed to get element role")
        return false
    }
    
    // MARK: - Language Detection
    private func updateCurrentInputSource() {
        guard let inputSource = TISCopyCurrentKeyboardInputSource()?.takeRetainedValue() else {
            debugPrint("❌ Failed to get current input source")
            return
        }
        
        guard let inputSourceIDRef = TISGetInputSourceProperty(inputSource, kTISPropertyInputSourceID) else {
            debugPrint("❌ Failed to get input source ID")
            return
        }
        
        let inputSourceID = Unmanaged<CFString>.fromOpaque(inputSourceIDRef).takeUnretainedValue() as String
        if inputSourceID != currentInputSource {
            currentInputSource = inputSourceID
            debugPrint("🔄 Input source changed to: \(inputSourceID)")
            
            // 메뉴바 아이콘 업데이트
            let language = getLanguageDisplayText()
            menuBarManager?.updateMenuBarIcon(with: language)
        }
    }
    
    private func getLanguageDisplayText() -> String {
        // Check if current input source is Korean
        let koreanIdentifiers = ["Korean", "2SetKorean", "HangulRoman", "com.apple.inputmethod.Korean"]
        let isKorean = koreanIdentifiers.contains { currentInputSource.contains($0) }
        return isKorean ? "한" : "A"
    }
    
    private func showLanguageIndicatorAt(location: NSPoint) {
        let language = getLanguageDisplayText()
        debugPrint("🔤 Showing indicator '\(language)' at location: \(location)")
        showIndicator(at: location, language: language)
        recordIndicatorShown()
    }
    
    // MARK: - UI Display
    private func showIndicator(at location: NSPoint, language: String) {
        hideIndicator()
        createIndicatorWindow(at: location, with: language)
        scheduleAutoHide()
    }
    
    private func createIndicatorWindow(at location: NSPoint, with language: String) {
        // Sonoma 스타일의 더 큰 둥근 팝업
        let windowRect = NSRect(
            x: location.x + 5, 
            y: location.y + 5, 
            width: 30, 
            height: 20
        )
        
        indicatorWindow = NSWindow(
            contentRect: windowRect,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        
        guard let window = indicatorWindow else { 
            debugPrint("❌ Failed to create indicator window")
            return 
        }
        
        configureSonomaWindow(window)
        addLanguageLabel(to: window, with: language)
        window.orderFront(nil)
        
        debugPrint("✅ Sonoma-style indicator window displayed")
    }
    
    private func configureSonomaWindow(_ window: NSWindow) {
        // 윈도우 배경을 투명하게 설정
        window.backgroundColor = NSColor.clear
        window.level = NSWindow.Level.floating
        window.isOpaque = false
        window.ignoresMouseEvents = true
        window.hasShadow = true
        
        // 둥근 모서리 효과를 위한 커스텀 뷰 생성
        if let contentView = window.contentView {
            contentView.wantsLayer = true
            // 작은 창 크기에 맞는 적절한 cornerRadius (창 높이의 절반 정도)
            contentView.layer?.cornerRadius = 10.0
            contentView.layer?.masksToBounds = true
            contentView.layer?.backgroundColor = NSColor.systemBlue.cgColor
        }
    }
    
    private func addLanguageLabel(to window: NSWindow, with language: String) {
        guard let contentView = window.contentView else { return }
        
        // Sonoma 스타일의 더 큰 흰색 글자
        let label = NSTextField(labelWithString: language)
        label.font = NSFont.systemFont(ofSize: 12, weight: .semibold)
        label.textColor = NSColor.white
        label.backgroundColor = NSColor.clear
        label.isBordered = false
        label.isEditable = false
        label.alignment = .center
        
        // 30x20 창 크기에 맞춰 수평/수직 모두 가운데 정렬
        let contentRect = contentView.bounds
        label.frame = NSRect(
            x: 0,
            y: -2,
            width: contentRect.width,
            height: contentRect.height
        )
        
        // 레이어 설정으로 더 나은 렌더링
        label.wantsLayer = true
        label.layer?.backgroundColor = NSColor.clear.cgColor
        
        contentView.addSubview(label)
    }
    
    private func scheduleAutoHide() {
        fadeTimer?.invalidate()
        fadeTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: false) { [weak self] _ in
            self?.hideIndicator()
        }
    }
    
    private func hideIndicator() {
        // Timer 정리
        fadeTimer?.invalidate()
        fadeTimer = nil
        
        // Window 정리
        if let window = indicatorWindow {
            window.orderOut(nil)
            // Window의 모든 subview 제거 (메모리 해제)
            window.contentView?.subviews.removeAll()
            debugPrint("🔄 Indicator window hidden")
        }
        indicatorWindow = nil
    }
    
    // MARK: - Cleanup
    deinit {
        debugPrint("🔄 Cleaning up Language Indicator")
        
        // Mouse event monitor 정리
        if let monitor = mouseEventMonitor {
            NSEvent.removeMonitor(monitor)
            mouseEventMonitor = nil
        }
        
        // Observer 제거
        DistributedNotificationCenter.default.removeObserver(self)
        
        // Timer 정리
        fadeTimer?.invalidate()
        fadeTimer = nil
        
        // Window 정리
        hideIndicator()
        
        // MenuBar 정리
        menuBarManager = nil
    }
}

// MARK: - App Delegate
class AppDelegate: NSObject, NSApplicationDelegate {
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        print("🚀 Language Indicator started!")
        debugPrint("🖱️ Mouse click monitoring initialized")
        
        // Initialize language indicator
        globalLanguageIndicator = LanguageIndicator()
        
        debugPrint("💡 Usage: Click on text fields to see the language indicator!")
        debugPrint("📍 Check the menu bar for options and quit button")
        debugPrint("🛑 Press Ctrl+C or use menu bar to quit")
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        debugPrint("👋 Language Indicator terminating...")
        globalLanguageIndicator = nil
    }
}

// MARK: - Main Execution
autoreleasepool {
    // Parse command line arguments
    let arguments = CommandLine.arguments
    if arguments.contains("-d") || arguments.contains("--debug") {
        isDebugMode = true
        debugPrint("🔧 Debug mode enabled")
    }
    
    let app = NSApplication.shared
    app.setActivationPolicy(.accessory) // Background app
    
    let delegate = AppDelegate()
    app.delegate = delegate
    
    // Handle Ctrl+C gracefully
    signal(SIGINT) { _ in
        print("\n👋 앱을 종료합니다...")
        DispatchQueue.main.async {
            NSApplication.shared.terminate(nil)
        }
    }
    
    app.run()
}