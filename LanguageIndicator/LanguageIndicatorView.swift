import Cocoa

class LanguageIndicatorView: NSView {
    
    private var indicatorWindow: NSWindow?
    private var fadeTimer: Timer?
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    private func setupView() {
        wantsLayer = true
        layer?.backgroundColor = NSColor.black.withAlphaComponent(0.8).cgColor
        layer?.cornerRadius = 8
    }
    
    func showIndicator(at location: NSPoint, language: String) {
        // Remove existing window if any
        hideIndicator()
        
        // Create new window
        let windowSize = NSSize(width: 60, height: 40)
        let windowRect = NSRect(
            x: location.x - windowSize.width / 2,
            y: location.y - windowSize.height - 20, // Show above cursor
            width: windowSize.width,
            height: windowSize.height
        )
        
        indicatorWindow = NSWindow(
            contentRect: windowRect,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        
        guard let window = indicatorWindow else { return }
        
        // Window configuration
        window.backgroundColor = NSColor.clear
        window.isOpaque = false
        window.hasShadow = true
        window.level = NSWindow.Level.floating
        window.ignoresMouseEvents = true
        window.collectionBehavior = [.canJoinAllSpaces, .stationary]
        
        // Create content view
        let contentView = NSView(frame: window.contentRect(forFrameRect: windowRect))
        contentView.wantsLayer = true
        contentView.layer?.backgroundColor = NSColor.black.withAlphaComponent(0.85).cgColor
        contentView.layer?.cornerRadius = 8
        
        // Create label
        let label = NSTextField(labelWithString: language)
        label.font = NSFont.systemFont(ofSize: 18, weight: .bold)
        label.textColor = NSColor.white
        label.alignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.addSubview(label)
        
        // Center the label
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
        
        window.contentView = contentView
        
        // Show window with animation
        window.alphaValue = 0.0
        window.makeKeyAndOrderFront(nil)
        
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.2
            window.animator().alphaValue = 1.0
        }
        
        // Auto-hide after delay
        fadeTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: false) { [weak self] _ in
            self?.hideIndicatorWithAnimation()
        }
    }
    
    private func hideIndicatorWithAnimation() {
        guard let window = indicatorWindow else { return }
        
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.3
            window.animator().alphaValue = 0.0
        }) { [weak self] in
            self?.hideIndicator()
        }
    }
    
    func hideIndicator() {
        fadeTimer?.invalidate()
        fadeTimer = nil
        
        indicatorWindow?.close()
        indicatorWindow = nil
    }
}
