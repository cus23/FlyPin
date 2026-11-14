import Darwin
import Foundation
import IDevice

/// Owns the RSD tunnel and Cryptex/DVT handles. All FFI operations are serialized.
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
            let parsed = self.tunnelAddress.withCString { inet_pton(AF_INET, $0, &endpoint.sin_addr) }
            guard parsed == 1 else { throw DeveloperServiceError.message("LocalDevVPN endpoint is invalid.") }

            var pairing: OpaquePointer?
            try self.check(pairingFile.path.withCString { rp_pairing_file_read($0, &pairing) },
                           "Cannot read the pairing record. Import it again.")
            guard let pairing else { throw DeveloperServiceError.message("The pairing record is invalid.") }
            defer { rp_pairing_file_free(pairing) }

            let failure = "FlyPin".withCString { label in
                withUnsafePointer(to: &endpoint) { pointer in
                    pointer.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                        tunnel_create_rppairing(
                            $0, socklen_t(MemoryLayout<sockaddr_in>.stride), label, pairing,
                            nil, nil, &self.adapter, &self.handshake
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
            var installed: UnsafeMutablePointer<InstalledCryptexC>?
            try self.check(cryptexd_installed_ddi(self.adapter, self.handshake, &installed),
                           "Cannot query the installed Developer Image cryptex.")
            guard let installed else { return false }
            cryptexd_free_installed_cryptex(installed)
            return true
        }
    }

    func installDeveloperImage(from directory: URL) async throws {
        try await run {
            try self.requireTunnel()
            if try self.isCryptexInstalled() { return }

            var assets: OpaquePointer?
            try self.check(directory.path.withCString { cryptex1_assets_load($0, &assets) },
                           "The verified Cryptex Developer Image files could not be loaded.")
            guard let assets else {
                throw DeveloperServiceError.message("The Cryptex asset loader returned no handle.")
            }
            defer { cryptex1_assets_free(assets) }

            var installed: UnsafeMutablePointer<InstalledCryptexC>?
            try self.check(cryptexd_install_ddi(self.adapter, self.handshake, assets, &installed),
                           "Apple could not personalize and install the Developer Image. Check internet access, Developer Mode, and iOS compatibility.")
            if let installed { cryptexd_free_installed_cryptex(installed) }

            guard try self.isCryptexInstalled() else {
                throw DeveloperServiceError.message("The install request returned, but iOS did not report an installed Developer Image.")
            }
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

    private func isCryptexInstalled() throws -> Bool {
        var installed: UnsafeMutablePointer<InstalledCryptexC>?
        try check(cryptexd_installed_ddi(adapter, handshake, &installed),
                  "Cannot query the installed Developer Image cryptex.")
        guard let installed else { return false }
        cryptexd_free_installed_cryptex(installed)
        return true
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
                      "DVT location simulation is unavailable. Install the Cryptex Developer Image first.")
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
