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
}

/// Lightify's menu in the macOS menu bar: what's playing, playback controls,
/// show the window, refresh, log out and quit. Clicks are sent to Flutter as
/// `menuAction` calls on the window channel (lib/utilities/status_menu.dart),
/// which sends `updateStatusMenu` back when the song or play state changes.
final class StatusMenu: NSObject {
  static let shared = StatusMenu()

  // kept so the item isn't released
  private var statusItem: NSStatusItem?
  private var channel: FlutterMethodChannel?

  private let songItem = NSMenuItem(title: "Nothing playing", action: nil, keyEquivalent: "")
  private let artistItem = NSMenuItem(title: "", action: nil, keyEquivalent: "")
  private var playPauseItem: NSMenuItem!
  private var playbackItems: [NSMenuItem] = []

  /// Adds the menu bar icon (once). Called by MainFlutterWindow at startup.
  func setUp(channel: FlutterMethodChannel) {
    self.channel = channel
    guard statusItem == nil else { return }

    let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    item.button?.image = StatusMenu.icon()
    item.button?.toolTip = "Lightify"

    let menu = NSMenu()
    // items are enabled by hand: the song lines are labels, and playback
    // needs the player
    menu.autoenablesItems = false
    songItem.isEnabled = false
    artistItem.isEnabled = false
    artistItem.isHidden = true
    menu.addItem(songItem)
    menu.addItem(artistItem)
    menu.addItem(.separator())

    playPauseItem = action("Play", "playPause")
    playbackItems = [playPauseItem, action("Next Song", "next"), action("Previous Song", "previous")]
    playbackItems.forEach(menu.addItem)
    menu.addItem(.separator())

    menu.addItem(action("Show Lightify", "toggleWindow"))
    menu.addItem(.separator())
    // shown like Quit's ⌘Q; the keys themselves are the app's Ctrl hotkeys
    let transferItem = action(
      "Transfer Playback Here", "transfer", key: "t", modifiers: .control)
    playbackItems.append(transferItem)
    menu.addItem(transferItem)
    menu.addItem(action("Refresh", "refresh", key: "r", modifiers: .control))
    menu.addItem(action("Log Out", "logout", key: "d", modifiers: .control))
    menu.addItem(.separator())
    menu.addItem(
      NSMenuItem(
        title: "Quit Lightify",
        action: #selector(NSApplication.terminate(_:)),
        keyEquivalent: "q"))

    item.menu = menu
    statusItem = item
    update(hasPlayer: false, song: nil, artist: nil, playing: false)
  }

  /// From Flutter's `updateStatusMenu`.
  func update(_ args: [String: Any]) {
    update(
      hasPlayer: args["hasPlayer"] as? Bool ?? false,
      song: args["song"] as? String,
      artist: args["artist"] as? String,
      playing: args["playing"] as? Bool ?? false)
  }

  private func update(hasPlayer: Bool, song: String?, artist: String?, playing: Bool) {
    let hasSong = hasPlayer && !(song ?? "").isEmpty
    songItem.attributedTitle = NSAttributedString(
      string: hasSong ? song! : "Nothing playing",
      attributes: [.font: NSFont.menuFont(ofSize: 0).bold()])
    artistItem.title = artist ?? ""
    artistItem.isHidden = !hasSong || (artist ?? "").isEmpty
    playPauseItem.title = playing ? "Pause" : "Play"
    playbackItems.forEach { $0.isEnabled = hasPlayer }
  }

  private func action(
    _ title: String, _ name: String, key: String = "",
    modifiers: NSEvent.ModifierFlags = .command
  ) -> NSMenuItem {
    let item = NSMenuItem(title: title, action: #selector(clicked(_:)), keyEquivalent: key)
    item.keyEquivalentModifierMask = modifiers
    item.target = self
    item.representedObject = name
    return item
  }

  @objc private func clicked(_ sender: NSMenuItem) {
    channel?.invokeMethod("menuAction", arguments: sender.representedObject)
  }

  // The logo's stroke (brand_assets/lightify_icon.svg) as a template image,
  // so macOS tints it to match the menu bar
  fileprivate static func icon() -> NSImage {
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

extension NSFont {
  fileprivate func bold() -> NSFont {
    NSFontManager.shared.convert(self, toHaveTrait: .boldFontMask)
  }
}
