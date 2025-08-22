import Cocoa
import Carbon

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    
    var statusBarItem: NSStatusItem!
    var languageIndicator: LanguageIndicatorView!
    var currentInputSource: String = ""
    var isEnabled = true
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Create status bar item
        statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusBarItem.button {
            button.title = "언어"
            button.action = #selector(statusBarButtonClicked)
            button.target = self
        }
        
        // Create language indicator view
        languageIndicator = LanguageIndicatorView()
        
        // Setup input source monitoring
        setupInputSourceMonitoring()
        
        // Initial language check
        updateCurrentInputSource()
        
        // Request accessibility permissions
        requestAccessibilityPermission()
    }
    
    func requestAccessibilityPermission() {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as String: true]
        let accessEnabled = AXIsProcessTrustedWithOptions(options)
        
        if !accessEnabled {
            let alert = NSAlert()
            alert.messageText = "접근성 권한이 필요합니다"
            alert.informativeText = "언어 표시 기능을 사용하려면 시스템 환경설정 > 보안 및 개인정보보호 > 개인정보보호 > 접근성에서 이 앱을 허용해주세요."
            alert.addButton(withTitle: "확인")
            alert.runModal()
        }
    }
    
    func setupInputSourceMonitoring() {
        // Monitor input source changes
        DistributedNotificationCenter.default.addObserver(
            self,
            selector: #selector(inputSourceChanged),
            name: NSNotification.Name(kTISNotifySelectedKeyboardInputSourceChanged as String),
            object: nil
        )
    }
    
    @objc func inputSourceChanged() {
        updateCurrentInputSource()
        
        if isEnabled {
            // Get current mouse location
            let mouseLocation = NSEvent.mouseLocation
            languageIndicator.showIndicator(at: mouseLocation, language: getLanguageDisplayText())
        }
    }
    
    func updateCurrentInputSource() {
        let inputSource = TISCopyCurrentKeyboardInputSource().takeRetainedValue()
        
        if let inputSourceID = TISGetInputSourceProperty(inputSource, kTISPropertyInputSourceID) {
            let id = Unmanaged<CFString>.fromOpaque(inputSourceID).takeUnretainedValue() as String
            currentInputSource = id
            
            // Update status bar
            if let button = statusBarItem.button {
                button.title = getLanguageDisplayText()
            }
        }
    }
    
    func getLanguageDisplayText() -> String {
        // Check if current input source is Korean
        if currentInputSource.contains("Korean") || 
           currentInputSource.contains("2SetKorean") ||
           currentInputSource.contains("HangulRoman") {
            return "한"
        } else {
            return "A"
        }
    }
    
    @objc func statusBarButtonClicked() {
        let menu = NSMenu()
        
        // Toggle enable/disable
        let toggleItem = NSMenuItem(title: isEnabled ? "비활성화" : "활성화", action: #selector(toggleEnabled), keyEquivalent: "")
        toggleItem.target = self
        menu.addItem(toggleItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Quit option
        let quitItem = NSMenuItem(title: "종료", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
        
        statusBarItem.menu = menu
        statusBarItem.button?.performClick(nil)
        statusBarItem.menu = nil
    }
    
    @objc func toggleEnabled() {
        isEnabled.toggle()
    }
    
    @objc func quitApp() {
        NSApplication.shared.terminate(nil)
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        DistributedNotificationCenter.default.removeObserver(self)
    }
}
