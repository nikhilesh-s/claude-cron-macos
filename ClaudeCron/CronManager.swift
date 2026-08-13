import Foundation

private enum Shell {
    static func run(_ executable: String, _ arguments: [String] = [], input: String? = nil) throws -> String {
        let p = Process(); let out = Pipe(); let inputPipe = Pipe()
        p.executableURL = URL(fileURLWithPath: executable); p.arguments = arguments
        p.standardOutput = out; p.standardError = out
        if input != nil { p.standardInput = inputPipe }
        try p.run()
        if let input { inputPipe.fileHandleForWriting.write(Data(input.utf8)); inputPipe.fileHandleForWriting.closeFile() }
        p.waitUntilExit()
        let result = String(decoding: out.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self)
        guard p.terminationStatus == 0 else { throw NSError(domain: "ClaudeCron", code: Int(p.terminationStatus), userInfo: [NSLocalizedDescriptionKey: result.isEmpty ? "crontab failed" : result]) }
        return result
    }
}

final class CronManager {
    private let marker = "# CLAUDE_CRON:"
    private var scriptPath: String { FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/Application Support/ClaudeCron/submit-claude.sh").path }

    func scheduledTimes() -> [ScheduledTime] {
        let text = (try? Shell.run("/usr/bin/crontab", ["-l"])) ?? ""
        return text.split(separator: "\n").compactMap { line in
            guard let range = line.range(of: marker) else { return nil }
            let code = String(line[range.upperBound...].prefix(4))
            return ScheduledTime(marker: code, launchClaude: !line.contains("--no-launch"))
        }.sorted { ($0.hour, $0.minute) < ($1.hour, $1.minute) }
    }

    func add(_ time: ScheduledTime) throws {
        var lines = try allLines()
        let existing = lines.first { $0.contains("\(marker)\(time.id)") }
        if existing == nil {
            let noLaunch = time.launchClaude ? "" : " --no-launch"
            lines.append("\(time.minute) \(time.hour) * * * /usr/bin/open -a \\\"Claude Cron\\\" --args --submit-now\(noLaunch) \(marker)\(time.id)")
            try install(lines)
        }
    }

    func remove(_ time: ScheduledTime) throws {
        let lines = try allLines().filter { !$0.contains("\(marker)\(time.id)") }
        try install(lines)
    }

    private func allLines() throws -> [String] {
        let current = (try? Shell.run("/usr/bin/crontab", ["-l"])) ?? ""
        return current.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
    }

    private func install(_ lines: [String]) throws {
        let result = lines.joined(separator: "\n") + "\n"
        _ = try Shell.run("/usr/bin/crontab", ["-"], input: result)
    }
}
