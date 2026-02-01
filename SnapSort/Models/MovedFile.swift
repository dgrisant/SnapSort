import Foundation

struct MovedFile: Identifiable, Codable {
    let id: UUID
    let originalName: String
    let destinationPath: String
    let movedAt: Date

    init(originalName: String, destinationPath: String) {
        self.id = UUID()
        self.originalName = originalName
        self.destinationPath = destinationPath
        self.movedAt = Date()
    }

    var destinationURL: URL {
        URL(fileURLWithPath: destinationPath)
    }

    var formattedTime: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: movedAt, relativeTo: Date())
    }
}

class RecentFilesManager: ObservableObject {
    static let shared = RecentFilesManager()

    private let maxRecentFiles = 10
    private let storageKey = "recentMovedFiles"

    @Published var recentFiles: [MovedFile] = []

    private init() {
        loadRecentFiles()
    }

    func addFile(_ file: MovedFile) {
        recentFiles.insert(file, at: 0)
        if recentFiles.count > maxRecentFiles {
            recentFiles = Array(recentFiles.prefix(maxRecentFiles))
        }
        saveRecentFiles()
    }

    func clearRecentFiles() {
        recentFiles.removeAll()
        saveRecentFiles()
    }

    private func loadRecentFiles() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let files = try? JSONDecoder().decode([MovedFile].self, from: data) else {
            return
        }
        recentFiles = files
    }

    private func saveRecentFiles() {
        guard let data = try? JSONEncoder().encode(recentFiles) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }
}
