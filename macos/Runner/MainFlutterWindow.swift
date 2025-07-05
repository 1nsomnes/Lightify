import Cocoa
import FlutterMacOS

private let kWindowChannel = "com.ced/window_utils"

class MainFlutterWindow: NSWindow {
    override func awakeFromNib() {
        super.awakeFromNib()
        self.isOpaque = false
        self.backgroundColor = .clear

        let flutterViewController = FlutterViewController()
        let windowFrame = self.frame
        self.contentViewController = flutterViewController
        flutterViewController.backgroundColor = .clear

        self.setFrame(windowFrame, display: true)

        //self.styleMask.remove(.titled)
        self.styleMask.insert(.fullSizeContentView)

        self.titleVisibility = .hidden
        self.isMovableByWindowBackground = true
        self.titlebarAppearsTransparent = true

        //TODO: Still doesn't work over YouTube videos, but when would you be listening to music over youtube, right? idk
        self.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.screenSaverWindow)))
        self.orderFrontRegardless()

        //let blurView = NSVisualEffectView(frame: contentView!.bounds)
        //blurView.autoresizingMask = [.width, .height]
        //blurView.blendingMode = .behindWindow  // composite behind window content
        //blurView.material = .hudWindow  // you can experiment: .sidebar, .popover, .fullScreenUI...
        //blurView.state = .active  // make it “live”
//
        //// 2️⃣ Insert it under the Flutter view
        //contentView?.addSubview(blurView, positioned: .below, relativeTo: flutterViewController.view)

        self.collectionBehavior.insert([.canJoinAllSpaces, .fullScreenAuxiliary])

        //TODO: possibly remove this?
        hasShadow = false

        // 4️⃣ Explicitly hide the traffic-light buttons
        for button in [
            NSWindow.ButtonType.closeButton,
            .miniaturizeButton,
            .zoomButton,
        ] {
            standardWindowButton(button)?.isHidden = true
        }

        let channel = FlutterMethodChannel(
            name: kWindowChannel,
            binaryMessenger: flutterViewController.engine.binaryMessenger,
        )

        channel.setMethodCallHandler { call, result in
            switch call.method {
            case "moveToActiveDisplay":
                self.moveToActiveDisplay()
                result(nil)
            default:
                result(FlutterMethodNotImplemented)
            }
        }

        self.contentViewController = flutterViewController
        RegisterGeneratedPlugins(registry: flutterViewController)

    }

    private func moveToActiveDisplay() {
        guard
            let screen = NSScreen.screens.first(where: {
                NSPointInRect(NSEvent.mouseLocation, $0.frame)
            })
        else {
            return
        }
        let winSize = frame.size
        // center on that screen (or adjust as you like)
        let x = screen.frame.minX + (screen.frame.width - winSize.width) / 2
        let y = screen.frame.minY + (screen.frame.height - winSize.height) / 2
        setFrameOrigin(NSPoint(x: x, y: y))
    }

    override func close() {
        super.close()
        NSApp.hide(self)  // hides app & returns focus to previous app :contentReference[oaicite:0]{index=0} (thanks chat GPT!)
    }

    override func resignKey() {
        close()
    }

    override func cancelOperation(_ sender: Any?) {
        close()
    }
}
