import Foundation

struct ClipboardItem: Codable, Identifiable, Hashable {
    enum Kind: String, Codable {
        case text
        case image
        case file
    }

    let id: UUID
    let kind: Kind
    let text: String?
    let imageFileName: String?
    let filePaths: [String]?
    let createdAt: Date
    let legacyImageData: Data?

    private enum CodingKeys: String, CodingKey {
        case id
        case kind
        case text
        case imageFileName
        case imageData
        case filePaths
        case createdAt
    }

    static func text(_ value: String) -> ClipboardItem {
        ClipboardItem(
            id: UUID(),
            kind: .text,
            text: value,
            imageFileName: nil,
            filePaths: nil,
            createdAt: Date(),
            legacyImageData: nil
        )
    }

    static func image(fileName: String) -> ClipboardItem {
        ClipboardItem(
            id: UUID(),
            kind: .image,
            text: nil,
            imageFileName: fileName,
            filePaths: nil,
            createdAt: Date(),
            legacyImageData: nil
        )
    }

    static func files(_ paths: [String]) -> ClipboardItem {
        ClipboardItem(
            id: UUID(),
            kind: .file,
            text: nil,
            imageFileName: nil,
            filePaths: paths,
            createdAt: Date(),
            legacyImageData: nil
        )
    }

    var previewText: String {
        switch kind {
        case .text:
            return text?
                .replacingOccurrences(of: "\n", with: " ")
                .trimmingCharacters(in: .whitespacesAndNewlines) ?? "文本"
        case .image:
            return "图片"
        case .file:
            return filePaths?
                .map { URL(fileURLWithPath: $0).lastPathComponent }
                .joined(separator: "、") ?? "文件"
        }
    }

    func hasSameContent(as other: ClipboardItem) -> Bool {
        kind == other.kind &&
            text == other.text &&
            imageFileName == other.imageFileName &&
            filePaths == other.filePaths
    }

    func replacingLegacyImage(with fileName: String) -> ClipboardItem {
        ClipboardItem(
            id: id,
            kind: kind,
            text: text,
            imageFileName: fileName,
            filePaths: filePaths,
            createdAt: createdAt,
            legacyImageData: nil
        )
    }

    init(
        id: UUID,
        kind: Kind,
        text: String?,
        imageFileName: String?,
        filePaths: [String]?,
        createdAt: Date,
        legacyImageData: Data?
    ) {
        self.id = id
        self.kind = kind
        self.text = text
        self.imageFileName = imageFileName
        self.filePaths = filePaths
        self.createdAt = createdAt
        self.legacyImageData = legacyImageData
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        kind = try container.decode(Kind.self, forKey: .kind)
        text = try container.decodeIfPresent(String.self, forKey: .text)
        imageFileName = try container.decodeIfPresent(String.self, forKey: .imageFileName)
        filePaths = try container.decodeIfPresent([String].self, forKey: .filePaths)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        legacyImageData = try container.decodeIfPresent(Data.self, forKey: .imageData)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(kind, forKey: .kind)
        try container.encodeIfPresent(text, forKey: .text)
        try container.encodeIfPresent(imageFileName, forKey: .imageFileName)
        try container.encodeIfPresent(filePaths, forKey: .filePaths)
        try container.encode(createdAt, forKey: .createdAt)
    }
}
