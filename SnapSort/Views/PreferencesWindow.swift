import SwiftUI

struct PreferencesWindow: View {
    @EnvironmentObject var appSettings: AppSettings
    @StateObject private var launchAtLogin = LaunchAtLoginService.shared
    @State private var newPrefix = ""
    @State private var showingWatchFolderPicker = false
    @State private var showingDestinationFolderPicker = false

    var body: some View {
        TabView {
            GeneralTab()
                .tabItem {
                    Label("General", systemImage: "gear")
                }

            FoldersTab()
                .tabItem {
                    Label("Folders", systemImage: "folder")
                }

            PrefixesTab()
                .tabItem {
                    Label("Prefixes", systemImage: "text.cursor")
                }

            AboutTab()
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
        }
        .frame(width: 450, height: 300)
        .environmentObject(appSettings)
        .environmentObject(launchAtLogin)
    }
}

// MARK: - General Tab
struct GeneralTab: View {
    @EnvironmentObject var appSettings: AppSettings
    @EnvironmentObject var launchAtLogin: LaunchAtLoginService

    var body: some View {
        Form {
            Section {
                Toggle("Enable SnapSort", isOn: $appSettings.isEnabled)
                    .disabled(!appSettings.isConfigured)

                if !appSettings.isConfigured {
                    Text("Configure watch and destination folders first")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }

            Section {
                Toggle("Show notifications when files are moved", isOn: $appSettings.showNotifications)
                Toggle("Launch at login", isOn: $appSettings.launchAtLogin)
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

// MARK: - Folders Tab
struct FoldersTab: View {
    @EnvironmentObject var appSettings: AppSettings
    @State private var showingWatchFolderPicker = false
    @State private var showingDestinationFolderPicker = false

    var body: some View {
        Form {
            Section("Watch Folder") {
                HStack {
                    if let url = appSettings.watchFolderURL {
                        Image(systemName: "folder.fill")
                            .foregroundColor(.blue)
                        Text(url.path)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    } else {
                        Image(systemName: "folder")
                            .foregroundColor(.secondary)
                        Text("Not selected")
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Button("Choose...") {
                        showingWatchFolderPicker = true
                    }
                }

                Text("SnapSort will monitor this folder for new screenshots")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Section("Destination Folder") {
                HStack {
                    if let url = appSettings.destinationFolderURL {
                        Image(systemName: "folder.fill")
                            .foregroundColor(.green)
                        Text(url.path)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    } else {
                        Image(systemName: "folder")
                            .foregroundColor(.secondary)
                        Text("Not selected")
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Button("Choose...") {
                        showingDestinationFolderPicker = true
                    }
                }

                Text("Matching screenshots will be moved here")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .formStyle(.grouped)
        .padding()
        .fileImporter(
            isPresented: $showingWatchFolderPicker,
            allowedContentTypes: [.folder],
            allowsMultipleSelection: false
        ) { result in
            if case .success(let urls) = result, let url = urls.first {
                if url.startAccessingSecurityScopedResource() {
                    appSettings.watchFolderURL = url
                    ScreenshotMoverService.shared.restartWatching()
                }
            }
        }
        .fileImporter(
            isPresented: $showingDestinationFolderPicker,
            allowedContentTypes: [.folder],
            allowsMultipleSelection: false
        ) { result in
            if case .success(let urls) = result, let url = urls.first {
                if url.startAccessingSecurityScopedResource() {
                    appSettings.destinationFolderURL = url
                    ScreenshotMoverService.shared.restartWatching()
                }
            }
        }
    }
}

// MARK: - Prefixes Tab
struct PrefixesTab: View {
    @EnvironmentObject var appSettings: AppSettings
    @State private var newPrefix = ""

    var body: some View {
        Form {
            Section("File Prefixes") {
                Text("Files starting with these prefixes will be moved automatically")
                    .font(.caption)
                    .foregroundColor(.secondary)

                List {
                    ForEach(appSettings.filePrefixes, id: \.self) { prefix in
                        HStack {
                            Text(prefix)
                            Spacer()
                            Button(action: { removePrefix(prefix) }) {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundColor(.red)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .frame(height: 100)

                HStack {
                    TextField("New prefix...", text: $newPrefix)
                        .textFieldStyle(.roundedBorder)
                        .onSubmit(addPrefix)

                    Button(action: addPrefix) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.green)
                    }
                    .buttonStyle(.plain)
                    .disabled(newPrefix.isEmpty)
                }

                Button("Reset to Defaults") {
                    appSettings.filePrefixes = ["Screenshot", "Screen Shot", "mac_"]
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }

    private func addPrefix() {
        let trimmed = newPrefix.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, !appSettings.filePrefixes.contains(trimmed) else { return }
        appSettings.filePrefixes.append(trimmed)
        newPrefix = ""
    }

    private func removePrefix(_ prefix: String) {
        appSettings.filePrefixes.removeAll { $0 == prefix }
    }
}

// MARK: - About Tab
struct AboutTab: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 64))
                .foregroundColor(.accentColor)

            Text("SnapSort")
                .font(.title)
                .fontWeight(.bold)

            Text("Version 1.0")
                .font(.caption)
                .foregroundColor(.secondary)

            Text("Automatically organize your screenshots")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Spacer()

            Text("Made with SwiftUI")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

#Preview {
    PreferencesWindow()
        .environmentObject(AppSettings.shared)
}
