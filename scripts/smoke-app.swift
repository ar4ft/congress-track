import AppKit
import CoreGraphics

// Exercise the installed-style executable and require a real main window, not
// merely a live process. The optional architecture is the slice to execute.
guard CommandLine.arguments.count >= 2 else {
    fatalError("Usage: swift scripts/smoke-app.swift <executable> [arm64|x86_64]")
}
let executable = URL(fileURLWithPath: CommandLine.arguments[1]).standardizedFileURL
let architecture = CommandLine.arguments.count > 2 ? CommandLine.arguments[2] : nil
let process = Process()
if let architecture {
    guard ["arm64", "x86_64"].contains(architecture) else { fatalError("Unsupported architecture") }
    process.executableURL = URL(fileURLWithPath: "/usr/bin/arch")
    process.arguments = ["-" + architecture, executable.path]
} else {
    process.executableURL = executable
}
// Do not inherit a restored window from an earlier CI run.
process.arguments = (process.arguments ?? []) + ["-ApplePersistenceIgnoreState", "YES"]
try process.run()
defer {
    if process.isRunning {
        process.terminate()
        process.waitUntilExit()
    }
}
var observedWindow = false
let deadline = Date().addingTimeInterval(10)
while Date() < deadline {
    guard process.isRunning else {
        fatalError("Packaged app exited during startup (status \(process.terminationStatus))")
    }
    if let windows = CGWindowListCopyWindowInfo(.optionAll, kCGNullWindowID) as? [[String: Any]] {
        observedWindow = observedWindow || windows.contains { window in
            guard let pid = window[kCGWindowOwnerPID as String] as? NSNumber,
                  pid.int32Value == process.processIdentifier,
                  let layer = window[kCGWindowLayer as String] as? NSNumber, layer.intValue == 0,
                  let bounds = window[kCGWindowBounds as String] as? [String: NSNumber] else { return false }
            return (bounds["Width"]?.doubleValue ?? 0) >= 1000 && (bounds["Height"]?.doubleValue ?? 0) >= 600
        }
    }
    RunLoop.current.run(until: Date().addingTimeInterval(0.25))
}
guard observedWindow && process.isRunning else { fatalError("Packaged app did not display its main window") }
print("Packaged app displayed its main window and survived startup\(architecture.map { " (\($0))" } ?? "").")
