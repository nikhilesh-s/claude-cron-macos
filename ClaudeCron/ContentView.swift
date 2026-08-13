import SwiftUI

struct ContentView: View {
    @ObservedObject var model: AppModel
    private let timeFormat: Date.FormatStyle = .dateTime.hour().minute()

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Claude Cron").font(.title2.bold())
            Text("Submit Claude prompts on a daily schedule.").foregroundStyle(.secondary)
            Divider()
            HStack {
                DatePicker("Submit at", selection: $model.selectedTime, displayedComponents: .hourAndMinute)
                Button("Schedule", action: model.schedule).keyboardShortcut(.defaultAction)
            }
            Toggle("Launch Claude before submitting", isOn: $model.launchClaude)
            Text("Scheduled").font(.headline)
            if model.times.isEmpty {
                Text("No scheduled submissions.").foregroundStyle(.secondary)
            } else {
                ForEach(model.times) { time in
                    HStack {
                        Text(time.display)
                        Spacer()
                        Button(role: .destructive) { model.delete(time) } label: {
                            Image(systemName: "trash")
                        }.buttonStyle(.borderless)
                    }
                }
            }
            Divider()
            Text("Next submission: \(model.times.first?.display ?? "none")")
            Button("Test Now", action: model.testNow)
            HStack {
                Circle().fill(model.accessibilityAllowed ? .green : .orange).frame(width: 8, height: 8)
                Text("Accessibility: \(model.accessibilityAllowed ? "Allowed" : "Not allowed")")
                Spacer()
                Button("Open Accessibility Settings") { AccessibilityManager.openSettings() }
            }.font(.caption)
            if !model.accessibilityAllowed {
                Text("Claude Cron needs Accessibility permission so it can press Return in Claude.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            if !model.status.isEmpty { Text(model.status).font(.caption).foregroundStyle(.secondary) }
            Spacer()
        }.padding(24)
    }
}
