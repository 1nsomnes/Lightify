import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)


    hasShadow = false

    // 3️⃣ Make the title bar transparent so you can drag by background
    titlebarAppearsTransparent = true
    isMovableByWindowBackground = true

    // 4️⃣ Explicitly hide the traffic-light buttons
    for button in [
      NSWindow.ButtonType.closeButton,
      .miniaturizeButton,
      .zoomButton
    ] {
      standardWindowButton(button)?.isHidden = true
    }

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }
}
