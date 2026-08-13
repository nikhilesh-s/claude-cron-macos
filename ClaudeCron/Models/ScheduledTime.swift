import Foundation

struct ScheduledTime: Identifiable, Equatable {
    let hour: Int
    let minute: Int
    let launchClaude: Bool

    init(date: Date, launchClaude: Bool = true) {
        let c = Calendar.current.dateComponents([.hour, .minute], from: date)
        hour = c.hour ?? 0; minute = c.minute ?? 0; self.launchClaude = launchClaude
    }

    init?(marker: String, launchClaude: Bool = true) {
        guard marker.count == 4, let value = Int(marker), value < 2400,
              value % 100 < 60 else { return nil }
        hour = value / 100; minute = value % 100; self.launchClaude = launchClaude
    }

    var id: String { String(format: "%02d%02d", hour, minute) }
    var display: String {
        var c = DateComponents(); c.hour = hour; c.minute = minute
        return (Calendar.current.date(from: c) ?? Date()).formatted(.dateTime.hour().minute())
    }
}
