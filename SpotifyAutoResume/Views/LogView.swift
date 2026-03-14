import SwiftUI

struct LogView: View {
    @EnvironmentObject var logManager: LogManager
    /// Called when the user taps "Done". In sheet context this was dismiss();
    /// in inline MenuBarExtra navigation it navigates back to the main page.
    var onDismiss: () -> Void = {}

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Activity Log")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                Button("Clear") {
                    logManager.clearLog()
                }
                .font(.subheadline)
                .foregroundColor(.red)
                .buttonStyle(.plain)

                Button("Done") {
                    onDismiss()
                }
                .font(.subheadline)
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Divider()

            if logManager.entries.isEmpty {
                Spacer()
                VStack(spacing: 8) {
                    Image(systemName: "doc.text")
                        .font(.system(size: 36))
                        .foregroundColor(.secondary)
                    Text("No activity logged yet")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
            } else {
                List(logManager.entries) { entry in
                    HStack(alignment: .top, spacing: 12) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(dateString(entry.timestamp))
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .monospacedDigit()
                            Text(timeString(entry.timestamp))
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .monospacedDigit()
                        }
                        .frame(minWidth: 60, alignment: .leading)

                        Text(entry.message)
                            .font(.caption)
                            .foregroundColor(.primary)
                            .fixedSize(horizontal: false, vertical: true)

                        Spacer()
                    }
                    .padding(.vertical, 2)
                }
                .listStyle(.plain)
            }
        }
        .frame(width: 320)
        .background(Color(NSColor.windowBackgroundColor))
    }

    private func dateString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }

    private func timeString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .medium
        return formatter.string(from: date)
    }
}
