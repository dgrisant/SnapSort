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

        // Organization Settings
        Menu("Organize by Date") {
            ForEach(FolderOrganization.allCases) { option in
                Button {
                    appSettings.folderOrganization = option
                } label: {
                    HStack {
                        Text(option.displayName)
                        if appSettings.folderOrganization == option {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }

            Divider()

            Text("Example: \(appSettings.folderOrganization.example)")
                .font(.caption)
        }

        Menu("Rename Format") {
            ForEach(NamingFormat.allCases) { format in
                Button {
                    appSettings.namingFormat = format
                } label: {
                    HStack {
                        Text(format.displayName)
                        if appSettings.namingFormat == format {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }

            Divider()

            Text("Example: \(appSettings.namingFormat.example)")
                .font(.caption)

            if appSettings.namingFormat == .custom || appSettings.namingFormat == .sequential {
                Divider()
                Text("Prefix: \(appSettings.customPrefix)")
                    .font(.caption)
            }
        }

        // Phase 2: Intelligent Sorting
        Toggle("Sort by App", isOn: $appSettings.appSortingEnabled)

        Toggle("Sort by Type", isOn: $appSettings.typeSortingEnabled)

        if appSettings.appSortingEnabled || appSettings.typeSortingEnabled {
            Text(getSortingDescription())
                .font(.caption)
                .foregroundColor(.secondary)
        }

        Divider()

        if screenshotMover.movedCount > 0 {
            Text("\(screenshotMover.movedCount) files moved")
        }

        Button("Open Screenshots Folder") {
            if let url = appSettings.getDestinationFolder() {
                NSWorkspace.shared.open(url)
            }
        }

        Button("Reorganize Existing Files") {
            screenshotMover.reorganizeExistingFiles { count in
                print("[SnapSort] Reorganized \(count) files")
            }
        }

        Divider()

        Button("Quit SnapSort") {
            NSApplication.shared.terminate(nil)
        }
        .keyboardShortcut("q", modifiers: .command)
    }

    private func getSortingDescription() -> String {
        var parts: [String] = []
        if appSettings.appSortingEnabled {
            parts.append("app")
        }
        if appSettings.typeSortingEnabled {
            parts.append("type")
        }
        return "Sorting by: \(parts.joined(separator: ", "))"
    }
}

#Preview {
    MenuBarView()
        .environmentObject(AppSettings.shared)
        .environmentObject(ScreenshotMoverService.shared)
}
