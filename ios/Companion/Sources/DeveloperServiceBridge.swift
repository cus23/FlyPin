import Darwin
import Foundation
import IDevice

/// Owns the RSD tunnel and DVT location-simulation handles.
/// All FFI calls are serialized because the underlying C handles are stateful.
final class DeveloperServiceBridge: @unchecked Sendable {
    private let queue = DispatchQueue(label: "tw.flypin.developer-service", qos: .userInitiated)
    private var adapter: OpaquePointer?
    private var handshake: OpaquePointer?
    private var remoteServer: OpaquePointer?
    private var locationClient: OpaquePointer?

    private let tunnelAddress = "10.7.0.1"
    private let tunnelPort: UInt16 = 49_152

    deinit { releaseAll() }

    func connect(pairingFile: URL) async throws {
        try await run {
            self.releaseAll()
            var endpoint = sockaddr_in()
            endpoint.sin_family = sa_family_t(AF_INET)
            endpoint.sin_port = in_port_t(self.tunnelPort).bigEndian

            let parsed = self.tunnelAddress.withCString {
                inet_pton(AF_INET, $0, &endpoint.sin_addr)
            }
            guard parsed == 1 else {
                throw DeveloperServiceError.message("LocalDevVPN endpoint is invalid.")
            }

            var pairing: OpaquePointer?
            try self.check(pairingFile.path.withCString {
                rp_pairing_file_read($0, &pairing)
            }, "Cannot read the pairing record. Import the pairing file again.")
            guard let pairing else {
                throw DeveloperServiceError.message("The pairing record is not valid.")
            }
            defer { rp_pairing_file_free(pairing) }

            let failure = "FlyPin".withCString { label in
                withUnsafePointer(to: &endpoint) { pointer in
                    pointer.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                        tunnel_create_rppairing(
                            $0,
                            socklen_t(MemoryLayout<sockaddr_in>.stride),
                            label,
                            pairing,
                            nil,
                            nil,
                            &self.adapter,
                            &self.handshake
                        )
                    }
                }
            }
            do {
                try self.check(failure, "Cannot reach the iPhone developer tunnel. Check LocalDevVPN and Wi-Fi.")
                guard self.adapter != nil, self.handshake != nil else {
                    throw DeveloperServiceError.message("RSD did not return valid connection handles.")
                }
            } catch {
                self.releaseAll()
                throw error
            }
        }
    }

    func hasMountedDeveloperImage() async throws -> Bool {
        try await run {
            try self.requireTunnel()
            var service: OpaquePointer?
            try self.check(image_mounter_connect_rsd(self.adapter, self.handshake, &service),
                           "Cannot connect to the Developer Image service.")
            guard let service else { throw DeveloperServiceError.message("Developer Image service unavailable.") }
            defer { image_mounter_free(service) }

            var entries: UnsafeMutablePointer<plist_t?>?
            var count = 0
            try self.check(image_mounter_copy_devices(service, &entries, &count),
                           "Cannot query mounted Developer Images.")
            if let entries { idevice_plist_array_free(entries, UInt(count)) }
            return count > 0
        }
    }

    func mountDeveloperImage(_ paths: DeveloperImagePaths) async throws {
        try await run {
            try self.requireTunnel()
            if try self.mountedImageCount() > 0 { return }

            let image = try Data(contentsOf: paths.image, options: .mappedIfSafe)
            let trust = try Data(contentsOf: paths.trustCache, options: .mappedIfSafe)
            let manifest = try Data(contentsOf: paths.buildManifest, options: .mappedIfSafe)
            guard !image.isEmpty, !trust.isEmpty, !manifest.isEmpty else {
                throw DeveloperServiceError.message("One or more Developer Image files are empty.")
            }

            var lockdown: OpaquePointer?
            try self.check(lockdownd_connect_rsd(self.adapter, self.handshake, &lockdown),
                           "Cannot connect to lockdownd.")
            guard let lockdown else { throw DeveloperServiceError.message("lockdownd did not respond.") }
            defer { lockdownd_client_free(lockdown) }

            var chipNode: plist_t?
            try self.check(lockdownd_get_value(lockdown, "UniqueChipID", nil, &chipNode),
                           "Cannot read the device chip identifier.")
            guard let chipNode else { throw DeveloperServiceError.message("Device chip identifier is missing.") }
            defer { plist_free(chipNode) }

            var chipID: UInt64 = 0
            plist_get_uint_val(chipNode, &chipID)
            guard chipID != 0 else { throw DeveloperServiceError.message("Device chip identifier is invalid.") }

            var mounter: OpaquePointer?
            try self.check(image_mounter_connect_rsd(self.adapter, self.handshake, &mounter),
                           "Cannot open the image mounter.")
            guard let mounter else { throw DeveloperServiceError.message("Image mounter is unavailable.") }
            defer { image_mounter_free(mounter) }

            let failure: UnsafeMutablePointer<IdeviceFfiError>? = image.withUnsafeBytes { imageBytes in
                trust.withUnsafeBytes { trustBytes in
                    manifest.withUnsafeBytes { manifestBytes in
                        image_mounter_mount_personalized_rsd(
                            mounter,
                            self.adapter,
                            self.handshake,
                            imageBytes.bindMemory(to: UInt8.self).baseAddress,
                            image.count,
                            trustBytes.bindMemory(to: UInt8.self).baseAddress,
                            trust.count,
                            manifestBytes.bindMemory(to: UInt8.self).baseAddress,
                            manifest.count,
                            nil,
                            chipID
                        )
                    }
                }
            }
            try self.check(failure, "Apple could not personalize or mount this Developer Image. It may not match this iOS build or device.")
        }
    }

    func setLocation(_ coordinate: SelectedCoordinate) async throws {
        try await run {
            guard coordinate.isValid else { throw DeveloperServiceError.message("Coordinates are outside the valid range.") }
            try self.requireTunnel()
            try self.ensureLocationClient()
            guard let client = self.locationClient else {
                throw DeveloperServiceError.message("DVT location-simulation client was not created.")
            }
            do {
                try self.check(location_simulation_set(client, coordinate.latitude, coordinate.longitude),
                               "The iPhone rejected the simulated location.")
            } catch {
                self.releaseAll()
                throw error
            }
        }
    }

    func clearLocation() async throws {
        try await run {
            try self.requireTunnel()
            try self.ensureLocationClient()
            guard let client = self.locationClient else {
                throw DeveloperServiceError.message("DVT location-simulation client was not created.")
            }
            do {
                try self.check(location_simulation_clear(client),
                               "The iPhone could not clear the simulated location.")
                self.releaseLocationSession()
            } catch {
                self.releaseAll()
                throw error
            }
        }
    }

    func disconnect() async {
        await withCheckedContinuation { continuation in
            queue.async {
                self.releaseAll()
                continuation.resume()
            }
        }
    }

    private func run<T: Sendable>(_ work: @escaping @Sendable () throws -> T) async throws -> T {
        try await withCheckedThrowingContinuation { continuation in
            queue.async { continuation.resume(with: Result(catching: work)) }
        }
    }

    private func requireTunnel() throws {
        guard adapter != nil, handshake != nil else {
            throw DeveloperServiceError.message("RSD is disconnected. Reconnect through LocalDevVPN.")
        }
    }

    private func mountedImageCount() throws -> Int {
        var service: OpaquePointer?
        try check(image_mounter_connect_rsd(adapter, handshake, &service),
                  "Cannot connect to the Developer Image service.")
        guard let service else { throw DeveloperServiceError.message("Developer Image service unavailable.") }
        defer { image_mounter_free(service) }

        var devices: UnsafeMutablePointer<plist_t?>?
        var count = 0
        try check(image_mounter_copy_devices(service, &devices, &count),
                  "Cannot query mounted Developer Images.")
        if let devices { idevice_plist_array_free(devices, UInt(count)) }
        return count
    }

    private func ensureLocationClient() throws {
        if locationClient != nil { return }
        try requireTunnel()
        releaseLocationSession()

        do {
            try check(remote_server_connect_rsd(adapter, handshake, &remoteServer),
                      "Cannot connect to the DVT remote server.")
            guard let remoteServer else {
                throw DeveloperServiceError.message("DVT remote server did not return a client.")
            }
            try check(location_simulation_new(remoteServer, &locationClient),
                      "DVT location simulation is unavailable. Mount the matching Developer Image first.")
            guard locationClient != nil else {
                throw DeveloperServiceError.message("DVT location simulation did not return a client.")
            }
        } catch {
            releaseAll()
            throw error
        }
    }

    private func check(_ error: UnsafeMutablePointer<IdeviceFfiError>?, _ fallback: String) throws {
        guard let error else { return }
        let code = Int(error.pointee.code)
        let detail = error.pointee.message.flatMap(String.init(validatingUTF8:)) ?? fallback
        idevice_error_free(error)
        throw DeveloperServiceError.ffi(code: code, detail: detail)
    }

    private func releaseLocationSession() {
        if let locationClient {
            location_simulation_free(locationClient)
            self.locationClient = nil
        }
        if let remoteServer {
            remote_server_free(remoteServer)
            self.remoteServer = nil
        }
    }

    private func releaseAll() {
        releaseLocationSession()
        if let handshake {
            rsd_handshake_free(handshake)
            self.handshake = nil
        }
        if let adapter {
            adapter_free(adapter)
            self.adapter = nil
        }
    }
}

enum DeveloperServiceError: LocalizedError, Sendable {
    case ffi(code: Int, detail: String)
    case message(String)

    var errorDescription: String? {
        switch self {
        case .ffi(let code, let detail): return "\(detail) (idevice error \(code))"
        case .message(let message): return message
        }
    }
}
