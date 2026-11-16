import Cocoa

// MARK: - Preferences
enum Prefs {
    static let d = UserDefaults.standard
    static var size: Double {
        get { d.object(forKey: "size") as? Double ?? 80 }
        set { d.set(newValue, forKey: "size") }
    }
    static var opacity: Double {
        get { d.object(forKey: "opacity") as? Double ?? 40 }
        set { d.set(newValue, forKey: "opacity") }
    }
    static var thickness: Double {
        get { d.object(forKey: "thickness") as? Double ?? 6 }
        set { d.set(newValue, forKey: "thickness") }
    }
    static var ring: Bool {
        get { d.object(forKey: "ring") as? Bool ?? false }
        set { d.set(newValue, forKey: "ring") }
    }
    static var enabled: Bool {
        get { d.object(forKey: "enabled") as? Bool ?? true }
        set { d.set(newValue, forKey: "enabled") }
    }
    static var color: NSColor {
        get {
            guard let a = d.array(forKey: "color") as? [Double], a.count == 3 else {
                return NSColor(srgbRed: 1, green: 0.83, blue: 0, alpha: 1)
            }
            return NSColor(srgbRed: a[0], green: a[1], blue: a[2], alpha: 1)
        }
        set {
            let c = newValue.usingColorSpace(.sRGB) ?? newValue
            d.set([Double(c.redComponent), Double(c.greenComponent), Double(c.blueComponent)], forKey: "color")
        }
    }
}

// MARK: - Halo view
final class HaloView: NSView {
    override var isOpaque: Bool { false }
    override func draw(_ dirtyRect: NSRect) {
        NSGraphicsContext.current?.cgContext.clear(bounds)
        let c = Prefs.color.withAlphaComponent(CGFloat(Prefs.opacity / 100))
        if Prefs.ring {
            let t = CGFloat(Prefs.thickness)
            let p = NSBezierPath(ovalIn: bounds.insetBy(dx: t / 2, dy: t / 2))
            p.lineWidth = t
            c.setStroke(); p.stroke()
        } else {
            c.setFill(); NSBezierPath(ovalIn: bounds).fill()
        }
    }
}

// MARK: - App
final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    var halo: NSWindow!
    var haloView: HaloView!
    var settings: NSWindow!
    var sizeLabel = NSTextField(labelWithString: "")
    var opacityLabel = NSTextField(labelWithString: "")
    var thicknessLabel = NSTextField(labelWithString: "")
    var colorWell = NSColorWell()
    var timer: Timer?

    func applicationDidFinishLaunching(_ n: Notification) {
        buildMenu()
        buildHalo()
        buildSettings()
        apply()
        let t = Timer(timeInterval: 1.0 / 120.0, repeats: true) { [weak self] _ in self?.follow() }
        RunLoop.main.add(t, forMode: .common)
        timer = t
        NSApp.activate(ignoringOtherApps: true)
    }

    func buildMenu() {
        let main = NSMenu()
        let item = NSMenuItem()
        main.addItem(item)
        let sub = NSMenu()
        sub.addItem(withTitle: "Quit Cursor Halo", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        item.submenu = sub
        NSApp.mainMenu = main
    }

    func buildHalo() {
        halo = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 80, height: 80),
                        styleMask: .borderless, backing: .buffered, defer: false)
        halo.isOpaque = false
        halo.backgroundColor = .clear
        halo.hasShadow = false
        halo.ignoresMouseEvents = true
        halo.level = .screenSaver
        halo.isReleasedWhenClosed = false
        halo.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary, .ignoresCycle]
        haloView = HaloView(frame: halo.contentRect(forFrameRect: halo.frame))
        haloView.autoresizingMask = [.width, .height]
        halo.contentView = haloView
    }

    func follow() {
        guard Prefs.enabled else { return }
        let p = NSEvent.mouseLocation
        let s = halo.frame.width
        halo.setFrameOrigin(NSPoint(x: p.x - s / 2, y: p.y - s / 2))
    }

    func apply() {
        let s = CGFloat(Prefs.size)
        var f = halo.frame
        f.size = NSSize(width: s, height: s)
        halo.setFrame(f, display: false)
        haloView.needsDisplay = true
        if Prefs.enabled { halo.orderFrontRegardless() } else { halo.orderOut(nil) }
        sizeLabel.stringValue = "Size: \(Int(Prefs.size)) px"
        opacityLabel.stringValue = "Opacity: \(Int(Prefs.opacity))%"
        thicknessLabel.stringValue = "Ring thickness: \(Int(Prefs.thickness)) px"
    }

    // MARK: Settings UI
    func slider(_ y: CGFloat, _ lo: Double, _ hi: Double, _ v: Double, _ action: Selector, in view: NSView) {
        let s = NSSlider(value: v, minValue: lo, maxValue: hi, target: self, action: action)
        s.frame = NSRect(x: 20, y: y, width: 320, height: 24)
        view.addSubview(s)
    }

    func label(_ l: NSTextField, _ y: CGFloat, in view: NSView) {
        l.frame = NSRect(x: 20, y: y, width: 320, height: 20)
        view.addSubview(l)
    }

    func buildSettings() {
        settings = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 360, height: 360),
                            styleMask: [.titled, .closable, .miniaturizable], backing: .buffered, defer: false)
        settings.title = "Cursor Halo"
        settings.delegate = self
        settings.center()
        settings.isReleasedWhenClosed = false
        let v = settings.contentView!

        label(sizeLabel, 325, in: v)
        slider(300, 20, 400, Prefs.size, #selector(sizeChanged(_:)), in: v)
        label(opacityLabel, 262, in: v)
        slider(237, 5, 100, Prefs.opacity, #selector(opacityChanged(_:)), in: v)
        label(thicknessLabel, 199, in: v)
        slider(174, 2, 40, Prefs.thickness, #selector(thicknessChanged(_:)), in: v)

        let ring = NSButton(checkboxWithTitle: "Ring (hollow)", target: self, action: #selector(ringChanged(_:)))
        ring.frame = NSRect(x: 20, y: 135, width: 150, height: 20)
        ring.state = Prefs.ring ? .on : .off
        v.addSubview(ring)

        let en = NSButton(checkboxWithTitle: "Halo enabled", target: self, action: #selector(enabledChanged(_:)))
        en.frame = NSRect(x: 190, y: 135, width: 150, height: 20)
        en.state = Prefs.enabled ? .on : .off
        v.addSubview(en)

        let cl = NSTextField(labelWithString: "Colour:")
        cl.frame = NSRect(x: 20, y: 95, width: 60, height: 20)
        v.addSubview(cl)
        colorWell.frame = NSRect(x: 80, y: 90, width: 50, height: 28)
        colorWell.color = Prefs.color
        colorWell.target = self
        colorWell.action = #selector(colorChanged(_:))
        v.addSubview(colorWell)

        var x: CGFloat = 150
        let swatches: [(CGFloat, CGFloat, CGFloat)] = [(1, 0.83, 0), (1, 0.23, 0.19), (0.2, 0.78, 0.35), (0.04, 0.52, 1), (1, 1, 1)]
        for s in swatches {
            let b = NSButton(frame: NSRect(x: x, y: 94, width: 24, height: 24))
            b.title = ""
            b.isBordered = false
            b.wantsLayer = true
            b.layer?.backgroundColor = NSColor(srgbRed: s.0, green: s.1, blue: s.2, alpha: 1).cgColor
            b.layer?.cornerRadius = 12
            b.layer?.borderWidth = 1
            b.layer?.borderColor = NSColor.gray.cgColor
            b.target = self
            b.action = #selector(swatch(_:))
            v.addSubview(b)
            x += 32
        }

        let note = NSTextField(wrappingLabelWithString: "Recording? Use Display Capture in OBS so the halo is included. Window Capture only records the chosen window.")
        note.frame = NSRect(x: 20, y: 15, width: 320, height: 60)
        note.textColor = .secondaryLabelColor
        v.addSubview(note)

        settings.makeKeyAndOrderFront(nil)
    }

    @objc func sizeChanged(_ s: NSSlider) { Prefs.size = s.doubleValue; apply() }
    @objc func opacityChanged(_ s: NSSlider) { Prefs.opacity = s.doubleValue; apply() }
    @objc func thicknessChanged(_ s: NSSlider) { Prefs.thickness = s.doubleValue; apply() }
    @objc func ringChanged(_ b: NSButton) { Prefs.ring = b.state == .on; apply() }
    @objc func enabledChanged(_ b: NSButton) { Prefs.enabled = b.state == .on; apply() }
    @objc func colorChanged(_ w: NSColorWell) { Prefs.color = w.color; apply() }
    @objc func swatch(_ b: NSButton) {
        guard let cg = b.layer?.backgroundColor, let c = NSColor(cgColor: cg) else { return }
        Prefs.color = c; colorWell.color = c; apply()
    }

    func windowWillClose(_ notification: Notification) { NSApp.terminate(nil) }
}

let app = NSApplication.shared
app.setActivationPolicy(.regular)
let delegate = AppDelegate()
app.delegate = delegate
app.run()
