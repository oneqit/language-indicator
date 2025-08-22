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

// MARK: - Language Indicator Main Class
class LanguageIndicator {
    // MARK: - Properties
    private var currentInputSource: String = ""
    private var indicatorWindow: NSWindow?
    private var fadeTimer: Timer?
    
    // MARK: - Initialization
    init() {
        updateCurrentInputSource()
        setupEventMonitoring()
        debugPrint("✅ Language Indicator initialized with event-based monitoring")
    }
    
    // MARK: - Event Monitoring Setup
    private func setupEventMonitoring() {
        // setupInputSourceMonitoring()
        setupApplicationMonitoring()
    }
    
    // private func setupInputSourceMonitoring() {
    //     // Monitor input source changes
    //     DistributedNotificationCenter.default.addObserver(
    //         self,
    //         selector: #selector(inputSourceChanged),
    //         name: NSNotification.Name(rawValue: kTISNotifySelectedKeyboardInputSourceChanged as String),
    //         object: nil
    //     )
    // }
    
    private func setupApplicationMonitoring() {
        // Monitor application activation changes
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(applicationDidActivate),
            name: NSWorkspace.didActivateApplicationNotification,
            object: nil
        )
    }
    
    
    // MARK: - Event Handlers
    @objc private func applicationDidActivate(_ notification: Notification) {
        debugPrint("📱 Application activated - checking focus")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            self?.checkForTextFieldFocus()
        }
    }
    
    // @objc private func inputSourceChanged() {
    //     DispatchQueue.main.async { [weak self] in
    //         self?.updateCurrentInputSource()
    //         self?.showLanguageIndicator()
    //     }
    // }
    
    // MARK: - Focus Detection
    private func checkForTextFieldFocus() {
        let systemWideElement = AXUIElementCreateSystemWide()
        var focusedElement: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(systemWideElement, kAXFocusedUIElementAttribute as CFString, &focusedElement)
        
        if result == .success, let element = focusedElement {
            let currentElement = element as! AXUIElement
            
            // Only show indicator if it's a text input element
            if isTextInputElement(currentElement) {
                debugPrint("⌨️  Text field focused - showing language indicator")
                showLanguageIndicator()
            }
        }
    }
    
    private func isTextInputElement(_ element: AXUIElement) -> Bool {
        var roleValue: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(element, kAXRoleAttribute as CFString, &roleValue)
        
        if result == .success, let role = roleValue as? String {
            let textRoles = ["AXTextField", "AXTextArea", "AXComboBox"]
            return textRoles.contains(role)
        }
        
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
        }
    }
    
    private func getLanguageDisplayText() -> String {
        // Check if current input source is Korean
        let koreanIdentifiers = ["Korean", "2SetKorean", "HangulRoman", "com.apple.inputmethod.Korean"]
        let isKorean = koreanIdentifiers.contains { currentInputSource.contains($0) }
        return isKorean ? "한" : "A"
    }
    
    private func showLanguageIndicator() {
        let mouseLocation = NSEvent.mouseLocation
        let language = getLanguageDisplayText()
        debugPrint("🔤 Showing indicator '\(language)' at location: \(mouseLocation)")
        showIndicator(at: mouseLocation, language: language)
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
        // Observer 제거 - 실제로 등록된 observer만 제거
        NSWorkspace.shared.notificationCenter.removeObserver(self)
        // DistributedNotificationCenter.default.removeObserver(self)
        
        // Timer 정리
        fadeTimer?.invalidate()
        fadeTimer = nil
        
        // Window 정리
        hideIndicator()
    }
}

// MARK: - App Delegate
class AppDelegate: NSObject, NSApplicationDelegate {
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        print("🚀 Language Indicator started!")
        debugPrint("📱 Event-based monitoring initialized")
        
        // Initialize language indicator
        globalLanguageIndicator = LanguageIndicator()
        
        debugPrint("💡 Usage: Change your input language to see the indicator!")
        debugPrint("🛑 Press Ctrl+C to quit")
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
