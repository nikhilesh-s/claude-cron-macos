import Foundation

enum ClaudeSubmitter {
    static func submit(launchClaude: Bool) {
        let activation = launchClaude ? "tell application \"Claude\" to activate\ndelay 1" : "delay 0.1"
        let script = """
        \(activation)
        tell application "System Events"
            set frontApp to name of first application process whose frontmost is true
            if frontApp is "Claude" then key code 36
        end tell
        """
        let p = Process(); p.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        p.arguments = ["-e", script]
        try? p.run()
    }
}
