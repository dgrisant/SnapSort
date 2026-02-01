import Cocoa
import UserNotifications

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Request notification permissions
        NotificationService.shared.requestAuthorization()

        // Start file watching if enabled and folders are configured
        if AppSettings.shared.isEnabled {
            ScreenshotMoverService.shared.startWatching()
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        // Stop file watching
        ScreenshotMoverService.shared.stopWatching()

        // Reset macOS screenshot settings to defaults
        AppSettings.shared.resetToDefaultMacOSSettings()
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
}
