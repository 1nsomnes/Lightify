import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return false
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }

  // the Lightify icon in the menu bar; kept so it isn't released
  private static var statusItem: NSStatusItem?

  /// Adds the menu bar icon (once). Called by MainFlutterWindow at startup.
  static func setUpStatusItem() {
    guard statusItem == nil else { return }
    let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    item.button?.image = AppDelegate.menuBarIcon()
    item.button?.toolTip = "Lightify"

    let menu = NSMenu()
    menu.addItem(
      NSMenuItem(
        title: "Quit Lightify",
        action: #selector(NSApplication.terminate(_:)),
        keyEquivalent: "q"))
    item.menu = menu
    statusItem = item
  }

  // The logo's stroke (brand_assets/lightify_icon.svg) as a template image,
  // so macOS tints it to match the menu bar
  private static func menuBarIcon() -> NSImage {
    let size: CGFloat = 18
    let image = NSImage(size: NSSize(width: size, height: size), flipped: true) { rect in
      // the logo is drawn on a 120×120 canvas
      let scale = rect.width / 120
      let path = NSBezierPath()
      func p(_ x: CGFloat, _ y: CGFloat) -> NSPoint { NSPoint(x: x * scale, y: y * scale) }
      path.move(to: p(-8, 102))
      path.curve(to: p(65, 42), controlPoint1: p(18, 94), controlPoint2: p(50, 72))
      path.curve(to: p(59, 12), controlPoint1: p(75, 20), controlPoint2: p(69, 6))
      path.curve(to: p(50, 82), controlPoint1: p(47, 20), controlPoint2: p(44, 58))
      path.curve(to: p(91, 95), controlPoint1: p(55, 101), controlPoint2: p(73, 105))
      path.curve(to: p(130, 62), controlPoint1: p(105, 87), controlPoint2: p(115, 76))
      path.lineWidth = 11 * scale
      path.lineCapStyle = .round
      path.lineJoinStyle = .round
      NSBezierPath(rect: rect).addClip()
      NSColor.black.setStroke()
      path.stroke()
      return true
    }
    image.isTemplate = true
    return image
  }
}
