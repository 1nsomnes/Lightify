import Cocoa
import FlutterMacOS

private let kWindowChannel = "com.ced/window_utils"

class MainFlutterWindow: NSWindow {
    override func awakeFromNib() {
        let flutterViewController = FlutterViewController()
        let windowFrame = self.frame
        self.contentViewController = flutterViewController
        self.setFrame(windowFrame, display: true)

        self.titlebarAppearsTransparent = true
        self.titleVisibility = .hidden

        self.styleMask.insert(.fullSizeContentView)

        self.isMovableByWindowBackground = true
        self.titlebarAppearsTransparent = true

        //TODO: Still doesn't work over YouTube videos, but when would you be listening to music over youtube, right? idk
        self.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.screenSaverWindow)))
        self.orderFrontRegardless()

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

        super.awakeFromNib()
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
