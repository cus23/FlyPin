import Foundation

enum PairingFileStore {
    private static let directoryName = "Pairing"
    private static let fileName = "device-pairing.plist"

    private static var directoryURL: URL {
        FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(directoryName, isDirectory: true)
    }

    static var fileURL: URL {
        directoryURL.appendingPathComponent(fileName)
    }

    static var exists: Bool {
        FileManager.default.fileExists(atPath: fileURL.path)
    }

    /// Imports a pairing record selected by the user. The record is never put in a URL,
    /// log, GitHub artifact, or app preference.
    static func importFile(from sourceURL: URL) throws {
        let didAccess = sourceURL.startAccessingSecurityScopedResource()
        defer {
            if didAccess {
                sourceURL.stopAccessingSecurityScopedResource()
            }
        }

        let data = try Data(contentsOf: sourceURL)
        guard !data.isEmpty else {
            throw PairingStoreError.emptyFile
        }

        // Basic plist validation catches accidental selection of unrelated files.
        // The native pairing library must still validate the record before use.
        var format = PropertyListSerialization.PropertyListFormat.xml
        _ = try PropertyListSerialization.propertyList(
            from: data,
            options: [],
            format: &format
        )

        let manager = FileManager.default
        try manager.createDirectory(
            at: directoryURL,
            withIntermediateDirectories: true,
            attributes: [.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication]
        )

        try data.write(
            to: fileURL,
            options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication]
        )
        try manager.setAttributes(
            [.posixPermissions: 0o600],
            ofItemAtPath: fileURL.path
        )

        var protectedURL = fileURL
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        try protectedURL.setResourceValues(values)
    }
}

enum PairingStoreError: LocalizedError {
    case emptyFile

    var errorDescription: String? {
        "選取的配對檔是空的。"
    }
}
