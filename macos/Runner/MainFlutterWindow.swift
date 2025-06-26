import Cocoa
import FlutterMacOS

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

        self.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.mainMenuWindow)))
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

        RegisterGeneratedPlugins(registry: flutterViewController)

        super.awakeFromNib()
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
