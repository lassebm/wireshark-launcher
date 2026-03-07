import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
    private var launchedFromFileOpen = false

    func applicationWillFinishLaunching(_ notification: Notification) {
        // Called before application(_:openFiles:), allowing us to detect file opens
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        // If no file was opened via Dock drop, launch a fresh empty Wireshark instance
        if !launchedFromFileOpen {
            launchWireshark(withFile: nil)
        }
        // Terminate after a short delay to ensure the launch completes
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            NSApp.terminate(nil)
        }
    }

    func application(_ sender: NSApplication, openFiles filenames: [String]) {
        launchedFromFileOpen = true
        for filename in filenames {
            launchWireshark(withFile: filename)
        }
        sender.reply(toOpenOrPrint: .success)
        // Terminate after a short delay to ensure the launches complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            NSApp.terminate(nil)
        }
    }

    private func launchWireshark(withFile file: String?) {
        let wiresharkPath = "/Applications/Wireshark.app"

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/open")

        var arguments = ["-n", "-a", wiresharkPath]
        if let file = file {
            arguments += ["--args", "-r", file]
        }
        process.arguments = arguments

        do {
            try process.run()
        } catch {
            NSLog("Failed to launch Wireshark: \(error)")
        }
    }
}

// Main entry point
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
