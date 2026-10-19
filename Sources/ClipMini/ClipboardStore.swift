import AppKit
import Combine
import CryptoKit
import Foundation

@MainActor
final class ClipboardStore: ObservableObject {
    @Published private(set) var items: [ClipboardItem] = []

    private let pasteboard = NSPasteboard.general
    private let maximumItemCount = 50
    private let maximumImageSize = 10 * 1024 * 1024
    private var lastChangeCount: Int
    private var timer: Timer?

    init() {
        lastChangeCount = pasteboard.changeCount
        loadHistory()
        startMonitoring()
    }

    func captureCurrentClipboard() {
        guard pasteboard.changeCount != lastChangeCount else { return }
        lastChangeCount = pasteboard.changeCount

        if let fileURLs = pasteboard.readObjects(
            forClasses: [NSURL.self],
            options: [.urlReadingFileURLsOnly: true]
        ) as? [URL], !fileURLs.isEmpty {
            add(.files(fileURLs.map(\.path)))
            return
        }

        if let image = NSImage(pasteboard: pasteboard),
           let tiffData = image.tiffRepresentation,
           let bitmap = NSBitmapImageRep(data: tiffData),
           let pngData = bitmap.representation(using: .png, properties: [:]) {
            guard pngData.count <= maximumImageSize,
                  let fileName = saveImage(pngData) else {
                return
            }
            add(.image(fileName: fileName))
            return
        }

        if let text = pasteboard.string(forType: .string), !text.isEmpty {
            add(.text(text))
        }
    }

    func restore(_ item: ClipboardItem) {
        pasteboard.clearContents()

        switch item.kind {
        case .text:
            if let text = item.text {
                pasteboard.setString(text, forType: .string)
            }
        case .image:
            if let image = image(for: item) {
                pasteboard.writeObjects([image])
            }
        case .file:
            if let filePaths = item.filePaths {
                pasteboard.writeObjects(filePaths.map { NSURL(fileURLWithPath: $0) })
            }
        }

        lastChangeCount = pasteboard.changeCount
        moveToFront(item)
    }

    func clear() {
        items.removeAll()
        saveHistory()
        removeUnusedImages()
    }

    func image(for item: ClipboardItem) -> NSImage? {
        guard let fileName = item.imageFileName,
              let imagesDirectory else {
            return nil
        }
        return NSImage(contentsOf: imagesDirectory.appendingPathComponent(fileName))
    }

    func delete(_ item: ClipboardItem) {
        items.removeAll { $0.id == item.id }
        saveHistory()
        removeUnusedImages()
    }

    private func startMonitoring() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.captureCurrentClipboard()
            }
        }
    }

    private func add(_ item: ClipboardItem) {
        items.removeAll { $0.hasSameContent(as: item) }
        items.insert(item, at: 0)
        sortItems()

        if items.count > maximumItemCount {
            items.removeLast(items.count - maximumItemCount)
        }

        saveHistory()
        removeUnusedImages()
    }

    private func moveToFront(_ item: ClipboardItem) {
        items.removeAll { $0.id == item.id }
        items.insert(item, at: 0)
        sortItems()
        saveHistory()
    }

    private var historyURL: URL? {
        guard let appDirectory else {
            return nil
        }
        return appDirectory.appendingPathComponent("history.json")
    }

    private var appDirectory: URL? {
        guard let directory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            return nil
        }
        let appDirectory = directory.appendingPathComponent("ClipMini", isDirectory: true)
        try? FileManager.default.createDirectory(at: appDirectory, withIntermediateDirectories: true)
        return appDirectory
    }

    private var imagesDirectory: URL? {
        guard let appDirectory else { return nil }
        let imagesDirectory = appDirectory.appendingPathComponent("Images", isDirectory: true)
        try? FileManager.default.createDirectory(at: imagesDirectory, withIntermediateDirectories: true)
        return imagesDirectory
    }

    private func loadHistory() {
        guard let historyURL,
              let data = try? Data(contentsOf: historyURL),
              let savedItems = try? JSONDecoder().decode([ClipboardItem].self, from: data) else {
            return
        }

        items = Array(savedItems.prefix(maximumItemCount)).compactMap { item in
            guard item.kind == .image,
                  item.imageFileName == nil,
                  let legacyImageData = item.legacyImageData,
                  let fileName = saveImage(legacyImageData) else {
                return item.kind == .image && item.imageFileName == nil ? nil : item
            }
            return item.replacingLegacyImage(with: fileName)
        }
        sortItems()
        saveHistory()
        removeUnusedImages()
    }

    private func saveHistory() {
        guard let historyURL,
              let data = try? JSONEncoder().encode(items) else {
            return
        }

        try? data.write(to: historyURL, options: .atomic)
    }

    private func saveImage(_ data: Data) -> String? {
        guard let imagesDirectory else { return nil }
        let digest = SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
        let fileName = "\(digest).png"
        let fileURL = imagesDirectory.appendingPathComponent(fileName)

        if !FileManager.default.fileExists(atPath: fileURL.path) {
            do {
                try data.write(to: fileURL, options: .atomic)
            } catch {
                return nil
            }
        }
        return fileName
    }

    private func removeUnusedImages() {
        guard let imagesDirectory,
              let files = try? FileManager.default.contentsOfDirectory(
                at: imagesDirectory,
                includingPropertiesForKeys: nil
              ) else {
            return
        }

        let usedFileNames = Set(items.compactMap(\.imageFileName))
        for file in files where !usedFileNames.contains(file.lastPathComponent) {
            try? FileManager.default.removeItem(at: file)
        }
    }

    private func sortItems() {
        items.sort { $0.createdAt > $1.createdAt }
    }
}
