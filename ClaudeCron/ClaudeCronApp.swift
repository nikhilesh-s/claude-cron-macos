import SwiftUI

@main
struct ClaudeCronApp: App {
    @StateObject private var model = AppModel()

    var body: some Scene {
        WindowGroup("Claude Cron") {
            ContentView(model: model)
                .frame(width: 430, height: 520)
        }
        .windowResizability(.contentSize)
    }
}

final class AppModel: ObservableObject {
    @Published var selectedTime = Date()
    @Published var times: [ScheduledTime] = []
    @Published var status = ""
    @Published var launchClaude = true
    @Published var accessibilityAllowed = AccessibilityManager.isTrusted

    private let cron = CronManager()

    init() {
        refresh()
        if CommandLine.arguments.contains("--submit-now") {
            let shouldLaunch = !CommandLine.arguments.contains("--no-launch")
            DispatchQueue.main.async {
                ClaudeSubmitter.submit(launchClaude: shouldLaunch)
                NSApp.terminate(nil)
            }
        }
    }

    func refresh() {
        times = cron.scheduledTimes()
        accessibilityAllowed = AccessibilityManager.isTrusted
    }

    func schedule() {
        do {
            try cron.add(ScheduledTime(date: selectedTime, launchClaude: launchClaude))
            refresh(); status = "Scheduled daily."
        } catch { status = error.localizedDescription }
    }

    func delete(_ time: ScheduledTime) {
        do { try cron.remove(time); refresh(); status = "Removed." }
        catch { status = error.localizedDescription }
    }

    func testNow() {
        status = "Submitting…"
        ClaudeSubmitter.submit(launchClaude: true)
        status = "Test submitted (if Claude was frontmost)."
    }
}
