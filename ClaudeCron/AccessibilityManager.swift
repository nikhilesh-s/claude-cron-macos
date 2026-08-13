import AppKit
import ApplicationServices

enum AccessibilityManager {
    static var isTrusted: Bool { AXIsProcessTrusted() }
    static func openSettings() {
        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
    }
}
