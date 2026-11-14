import CommonCrypto
import Foundation

struct DeveloperImagePaths: Sendable {
    let image: URL
    let trustCache: URL
    let buildManifest: URL
}

/// The source revision and Git blob object IDs are immutable. Each downloaded
/// payload is checked against its Git object ID before it is accepted.
enum DeveloperImageStore {
    private static let revision = "dcec53989fa57695c2b3d3e11c2585f4735b2fef"
    private static let base = "https://raw.githubusercontent.com/doronz88/DeveloperDiskImage/\(revision)/PersonalizedImages/Xcode_iOS_DDI_Personalized"

    private struct Asset {
        let name: String
        let gitBlobSHA1: String
    }

    private static let assets = [
        Asset(name: "Image.dmg", gitBlobSHA1: "1e1f423fa6db5570fa8c00c683ce77cda14e8b99"),
        Asset(name: "Image.dmg.trustcache", gitBlobSHA1: "5d313bf7958c3f482a556d13cf6c6f22a0012835"),
        Asset(name: "BuildManifest.plist", gitBlobSHA1: "ecd4f63bc38be1682b3f9f52e82cff63dfa5057f")
    ]

    static var paths: DeveloperImagePaths {
        DeveloperImagePaths(
            image: directory.appendingPathComponent("Image.dmg"),
            trustCache: directory.appendingPathComponent("Image.dmg.trustcache"),
            buildManifest: directory.appendingPathComponent("BuildManifest.plist")
        )
    }

    static func ensureDownloaded(progress: @escaping @Sendable (String) -> Void) async throws {
        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true,
            attributes: [.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication]
        )

        for asset in assets {
            let destination = directory.appendingPathComponent(asset.name)
            if let existing = try? Data(contentsOf: destination, options: .mappedIfSafe),
               gitBlobSHA1(existing) == asset.gitBlobSHA1 {
                continue
            }

            progress("下載 \(asset.name)…")
            guard let url = URL(string: "\(base)/\(asset.name)") else {
                throw DeveloperImageStoreError.invalidURL
            }
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
                throw DeveloperImageStoreError.downloadFailed(asset.name)
            }
            guard gitBlobSHA1(data) == asset.gitBlobSHA1 else {
                throw DeveloperImageStoreError.integrityFailed(asset.name)
            }
            try data.write(to: destination, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
            try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: destination.path)
        }
    }

    private static func gitBlobSHA1(_ data: Data) -> String {
        var payload = Data("blob \(data.count)\0".utf8)
        payload.append(data)
        var digest = [UInt8](repeating: 0, count: Int(CC_SHA1_DIGEST_LENGTH))
        payload.withUnsafeBytes { bytes in
            _ = CC_SHA1(bytes.baseAddress, CC_LONG(payload.count), &digest)
        }
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    private static var directory: URL {
        FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("DeveloperImage", isDirectory: true)
    }
}

enum DeveloperImageStoreError: LocalizedError {
    case invalidURL
    case downloadFailed(String)
    case integrityFailed(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Developer Image download URL is invalid."
        case .downloadFailed(let name): return "Could not download \(name)."
        case .integrityFailed(let name): return "\(name) failed its pinned Git SHA-1 integrity check."
        }
    }
}
