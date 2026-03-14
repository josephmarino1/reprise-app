import Foundation

/// Runs NSAppleScript on a dedicated background thread that owns an active RunLoop.
///
/// NSAppleScript sends Apple Events and awaits replies via the run loop mechanism.
/// DispatchQueue global threads have no run loop, causing silent failures.
/// This class provides a single persistent thread whose RunLoop stays alive for
/// the app's lifetime, and an async API so callers never block the main thread.
final class ScriptExecutor: NSObject {
    static let shared = ScriptExecutor()

    private var workerThread: Thread!

    private override init() {
        super.init()
        let ready = DispatchSemaphore(value: 0)
        workerThread = Thread {
            // A distant-future timer prevents the run loop from exiting when idle.
            Timer.scheduledTimer(withTimeInterval: .greatestFiniteMagnitude,
                                 repeats: false) { _ in }
            ready.signal()
            RunLoop.current.run()
        }
        workerThread.name = "Reprise.AppleScript"
        workerThread.qualityOfService = .userInitiated
        workerThread.start()
        ready.wait()
    }

    /// Schedule `block` on the AppleScript thread and suspend the caller until
    /// it completes. The calling Task is suspended (not the thread), so the
    /// main thread stays responsive.
    func execute<T: Sendable>(_ block: @escaping @Sendable () -> T) async -> T {
        await withCheckedContinuation { continuation in
            let wrapper = ScriptBlock { continuation.resume(returning: block()) }
            perform(#selector(runBlock(_:)),
                    on: workerThread,
                    with: wrapper,
                    waitUntilDone: false)
        }
    }

    @objc private func runBlock(_ wrapper: ScriptBlock) {
        wrapper.run()
    }
}

// NSObject subclass so it can be passed to perform(_:on:with:waitUntilDone:).
private final class ScriptBlock: NSObject {
    private let block: () -> Void
    init(_ block: @escaping () -> Void) { self.block = block }
    func run() { block() }
}
