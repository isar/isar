import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController.init()
    self.titlebarAppearsTransparent = true
    //self.titleVisibility = .hidden
    self.isOpaque = false
    self.backgroundColor = .clear
    self.styleMask = [.titled, .closable, .resizable, .fullSizeContentView, .miniaturizable]
    self.titleVisibility = .hidden;

    let customToolbar = NSToolbar(identifier: "toolbar")
    self.toolbar = customToolbar

    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }

  func moveButtons() {
    self.moveButton(button: self.standardWindowButton(.closeButton)!)
    self.moveButton(button: self.standardWindowButton(.miniaturizeButton)!)
    self.moveButton(button: self.standardWindowButton(.zoomButton)!)
  }

  func moveButton(button: NSView) {
    button.setFrameOrigin(NSMakePoint(button.frame.origin.x+80, button.frame.origin.y+5.0))
    self.contentView!.addSubview(button)
  }
}


