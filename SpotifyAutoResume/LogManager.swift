import Foundation

struct LogEntry: Identifiable, Codable {
    let id: UUID
    let timestamp: Date
    let message: String

    init(id: UUID = UUID(), timestamp: Date = Date(), message: String) {
        self.id = id
        self.timestamp = timestamp
        self.message = message
    }
}

class LogManager: ObservableObject {
    static let shared = LogManager()

    @Published var entries: [LogEntry] = []

    private let maxEntries = 200
    private let logFileURL: URL

    private init() {
        let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first!
        let appDir = appSupport.appendingPathComponent("Reprise", isDirectory: true)

        // Create directory if needed
        try? FileManager.default.createDirectory(
            at: appDir,
            withIntermediateDirectories: true,
            attributes: nil
        )

        logFileURL = appDir.appendingPathComponent("activity.log")
        loadLog()
    }

    func log(_ message: String) {
        let entry = LogEntry(timestamp: Date(), message: message)
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.entries.insert(entry, at: 0)
            if self.entries.count > self.maxEntries {
                self.entries = Array(self.entries.prefix(self.maxEntries))
            }
            self.saveLog()
        }
    }

    func clearLog() {
        entries = []
        saveLog()
    }

    private func saveLog() {
        do {
            let data = try JSONEncoder().encode(entries)
            try data.write(to: logFileURL, options: .atomic)
        } catch {
            print("Failed to save log: \(error)")
        }
    }

    private func loadLog() {
        guard FileManager.default.fileExists(atPath: logFileURL.path) else { return }
        do {
            let data = try Data(contentsOf: logFileURL)
            let loaded = try JSONDecoder().decode([LogEntry].self, from: data)
            entries = loaded
        } catch {
            print("Failed to load log: \(error)")
            entries = []
        }
    }
}
