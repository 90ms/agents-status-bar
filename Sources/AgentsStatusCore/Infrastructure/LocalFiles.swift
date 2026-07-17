import Foundation

enum LocalFiles {
    static func newestFiles(
        below root: URL,
        named fileName: String? = nil,
        extension fileExtension: String? = nil,
        modifiedAfter: Date? = nil,
        limit: Int) -> [URL]
    {
        guard let enumerator = FileManager.default.enumerator(
            at: root,
            includingPropertiesForKeys: [.contentModificationDateKey, .isRegularFileKey],
            options: [.skipsHiddenFiles, .skipsPackageDescendants])
        else { return [] }

        var candidates: [(url: URL, modifiedAt: Date)] = []
        for case let url as URL in enumerator {
            guard fileName == nil || url.lastPathComponent == fileName else { continue }
            guard fileExtension == nil || url.pathExtension == fileExtension else { continue }
            guard let values = try? url.resourceValues(forKeys: [.contentModificationDateKey, .isRegularFileKey]),
                  values.isRegularFile == true,
                  let modifiedAt = values.contentModificationDate
            else { continue }
            guard modifiedAfter == nil || modifiedAt >= modifiedAfter! else { continue }
            candidates.append((url, modifiedAt))
        }

        return candidates
            .sorted { $0.modifiedAt > $1.modifiedAt }
            .prefix(limit)
            .map(\.url)
    }

    static func lines(in file: URL) -> [Data] {
        guard let data = try? Data(contentsOf: file, options: .mappedIfSafe) else { return [] }
        return data.split(whereSeparator: { $0 == 0x0A }).map { Data($0) }
    }
}

enum TimestampParser {
    static func parse(_ value: String?) -> Date? {
        guard let value else { return nil }
        if let date = try? Date(value, strategy: .iso8601) {
            return date
        }
        return ISO8601DateFormatter().date(from: value)
    }
}
