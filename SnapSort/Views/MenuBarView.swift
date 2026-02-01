import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject var appSettings: AppSettings
    @EnvironmentObject var screenshotMover: ScreenshotMoverService

    var body: some View {
        // Status
        if screenshotMover.isWatching {
            let watchName = appSettings.watchFolderURL?.lastPathComponent ?? "Desktop"
            Label("Watching \(watchName)", systemImage: "eye.circle.fill")
        } else {
            Label("Paused", systemImage: "pause.circle")
        }

        Toggle("Enable SnapSort", isOn: $appSettings.isEnabled)

        Toggle("Instant Move (skip preview)", isOn: $appSettings.quickMoveEnabled)

        Divider()

        if screenshotMover.movedCount > 0 {
            Text("\(screenshotMover.movedCount) files moved")
        }

        Button("Open Screenshots Folder") {
            if let url = appSettings.destinationFolderURL {
                NSWorkspace.shared.open(url)
            }
        }

        Divider()

        Button("Quit SnapSort") {
            NSApplication.shared.terminate(nil)
        }
        .keyboardShortcut("q", modifiers: .command)
    }
}

#Preview {
    MenuBarView()
        .environmentObject(AppSettings.shared)
        .environmentObject(ScreenshotMoverService.shared)
}
