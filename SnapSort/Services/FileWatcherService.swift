import Foundation

protocol FileWatcherDelegate: AnyObject {
    func fileWatcher(_ watcher: FileWatcherService, didDetectNewFile url: URL)
}

class FileWatcherService {
    weak var delegate: FileWatcherDelegate?

    private var eventStream: FSEventStreamRef?
    private let watchedPath: String
    private var isWatching = false
    private let dispatchQueue = DispatchQueue(label: "com.snapsort.filewatcher", qos: .utility)

    init(path: String) {
        self.watchedPath = path
    }

    deinit {
        stop()
    }

    func start() {
        guard !isWatching else { return }

        var context = FSEventStreamContext(
            version: 0,
            info: Unmanaged.passUnretained(self).toOpaque(),
            retain: nil,
            release: nil,
            copyDescription: nil
        )

        let paths = [watchedPath] as CFArray

        let callback: FSEventStreamCallback = { (
            streamRef,
            clientCallBackInfo,
            numEvents,
            eventPaths,
            eventFlags,
            eventIds
        ) in
            guard let clientInfo = clientCallBackInfo else { return }
            let watcher = Unmanaged<FileWatcherService>.fromOpaque(clientInfo).takeUnretainedValue()

            guard let paths = unsafeBitCast(eventPaths, to: NSArray.self) as? [String] else { return }

            for i in 0..<numEvents {
                let path = paths[i]
                let flags = eventFlags[i]

                // Check if this is a file creation or modification event
                if flags & UInt32(kFSEventStreamEventFlagItemCreated) != 0 ||
                   flags & UInt32(kFSEventStreamEventFlagItemModified) != 0 ||
                   flags & UInt32(kFSEventStreamEventFlagItemRenamed) != 0 {

                    let url = URL(fileURLWithPath: path)

                    // Only notify for files (not directories)
                    var isDirectory: ObjCBool = false
                    if FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory),
                       !isDirectory.boolValue {
                        DispatchQueue.main.async {
                            watcher.delegate?.fileWatcher(watcher, didDetectNewFile: url)
                        }
                    }
                }
            }
        }

        eventStream = FSEventStreamCreate(
            nil,
            callback,
            &context,
            paths,
            FSEventStreamEventId(kFSEventStreamEventIdSinceNow),
            0.5, // Latency in seconds
            UInt32(kFSEventStreamCreateFlagFileEvents | kFSEventStreamCreateFlagUseCFTypes)
        )

        if let stream = eventStream {
            FSEventStreamSetDispatchQueue(stream, dispatchQueue)
            FSEventStreamStart(stream)
            isWatching = true
        }
    }

    func stop() {
        guard isWatching, let stream = eventStream else { return }

        FSEventStreamStop(stream)
        FSEventStreamInvalidate(stream)
        FSEventStreamRelease(stream)
        eventStream = nil
        isWatching = false
    }
}
