import SwiftUI

@main
struct SnapSortApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var appSettings = AppSettings.shared
    @StateObject private var screenshotMover = ScreenshotMoverService.shared

    var body: some Scene {
        MenuBarExtra {
            MenuBarView()
                .environmentObject(appSettings)
                .environmentObject(screenshotMover)
        } label: {
            Image(systemName: appSettings.isEnabled ? "photo.on.rectangle.angled" : "photo")
        }
        .menuBarExtraStyle(.menu)
    }
}
