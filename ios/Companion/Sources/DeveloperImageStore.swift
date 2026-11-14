import CommonCrypto
import Foundation

struct DeveloperImagePaths: Sendable {
    let directory: URL
}

/// Pinned Cryptex DDI payloads. Git blob IDs are verified before any file is used.
enum DeveloperImageStore {
    private static let revision = "dcec53989fa57695c2b3d3e11c2585f4735b2fef"
    private static let base = "https://raw.githubusercontent.com/doronz88/DeveloperDiskImage/\(revision)/PersonalizedImages/Xcode_iOS_DDI_Cryptex"

    private struct Asset {
        let name: String
        let blobID: String
    }

    private static let assets = [
        Asset(name: "Image.dmg", blobID: "dd404fd2770097e3b0799b02ca8fdecb077b3af0"),
        Asset(name: "Image.dmg.trustcache", blobID: "c82e227c779a726cf7a8ebf4a12d807d3d0d9ac4"),
        Asset(name: "Image.dmg.cryptex_info", blobID: "9be13ce00289d8cc46315ed7f975a89be3af9dd1"),
        Asset(name: "Image.dmg.root_hash", blobID: "85fc5c4d3be2226e9197bfa339a5ad5b7eb61a5c"),
        Asset(name: "BuildManifest.plist", blobID: "8a1bdfb94677db0a935749c1daa57ffa0bd4b569")
    ]

    static var paths: DeveloperImagePaths {
        DeveloperImagePaths(directory: directory)
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
               gitBlobSHA1(existing) == asset.blobID {
                continue
            }

            progress("下載並驗證 \(asset.name)…")
            guard let url = URL(string: "\(base)/\(asset.name)") else {
                throw DeveloperImageStoreError.invalidURL
            }
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
                throw DeveloperImageStoreError.downloadFailed(asset.name)
            }
            guard gitBlobSHA1(data) == asset.blobID else {
                throw DeveloperImageStoreError.integrityFailed(asset.name)
            }
            try data.write(to: destination, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
            try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: destination.path)
        }

        let manifestURL = directory.appendingPathComponent("BuildManifest.plist")
        let manifestData = try Data(contentsOf: manifestURL)
        guard let manifest = try PropertyListSerialization.propertyList(from: manifestData, options: [], format: nil) as? [String: Any],
              let identities = manifest["BuildIdentities"] as? [Any],
              !identities.isEmpty else {
            throw DeveloperImageStoreError.invalidManifest
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
    case invalidManifest

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Developer Image download URL is invalid."
        case .downloadFailed(let name): return "Could not download \(name)."
        case .integrityFailed(let name): return "\(name) failed its pinned Git object integrity check."
        case .invalidManifest: return "The downloaded Developer Image manifest is not valid."
        }
    }
}
