import Foundation
import SwiftUI
import UIKit
import UniformTypeIdentifiers

@MainActor
final class CompanionModel: ObservableObject {
    @Published var coordinate = SelectedCoordinate(latitude: 25.0330, longitude: 121.5654)!
    @Published var status = "尚未建立 DVT 連線"
    @Published var pairingImported = PairingFileStore.exists
    @Published var showingPairingImporter = false
    @Published var errorMessage: String?
    @Published private(set) var isPrepared = false
    @Published private(set) var isSimulating = false
    @Published private(set) var isBusy = false

    private let bridge = DeveloperServiceBridge()

    init() {
        isPrepared = UserDefaults.standard.bool(forKey: "flypin.devicePrepared")
    }

    func handleIncomingURL(_ url: URL) {
        guard url.scheme == "flypin-companion",
              url.host == "set-location",
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let latitudeText = components.queryItems?.first(where: { $0.name == "lat" })?.value,
              let longitudeText = components.queryItems?.first(where: { $0.name == "lon" })?.value,
              let latitude = Double(latitudeText),
              let longitude = Double(longitudeText),
              let newCoordinate = SelectedCoordinate(latitude: latitude, longitude: longitude) else {
            return
        }

        coordinate = newCoordinate
        if isPrepared {
            Task { await applySelectedCoordinate() }
        } else {
            status = "已收到網頁座標。先完成「連線與準備」，之後可直接從網頁切換位置。"
        }
    }

    func importPairingFile(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            do {
                try PairingFileStore.importFile(from: url)
                pairingImported = true
                status = "配對檔已安全儲存；尚未驗證裝置連線"
            } catch {
                errorMessage = "無法匯入配對檔：\(error.localizedDescription)"
            }
        case .failure(let error):
            let nsError = error as NSError
            guard !(nsError.domain == NSCocoaErrorDomain && nsError.code == NSUserCancelledError) else { return }
            errorMessage = "檔案匯入失敗：\(error.localizedDescription)"
        }
    }

    func openLocalDevVPN() {
        guard let url = URL(string: "localdevvpn://enable") else { return }
        status = "正在開啟 LocalDevVPN。切回 FlyPin 後，按「連線與準備」。"
        UIApplication.shared.open(url) { [weak self] opened in
            guard !opened else { return }
            self?.status = "無法開啟 LocalDevVPN。請先安裝並手動啟動一次。"
        }
    }

    func prepareDevice() {
        guard pairingImported else {
            errorMessage = "請先匯入這台 iPhone 的配對檔。"
            return
        }
        guard !isBusy else { return }

        isBusy = true
        status = "正在建立 RSD 連線…"
        Task {
            defer { isBusy = false }
            do {
                try await bridge.connect(pairingFile: PairingFileStore.fileURL)
                status = "RSD 已連線，正在檢查 Developer Image…"

                if try await !bridge.hasMountedDeveloperImage() {
                    try await DeveloperImageStore.ensureDownloaded { [weak self] message in
                        Task { @MainActor in self?.status = message }
                    }
                    status = "檔案已驗證，正在向 iPhone 要求掛載 Developer Image…"
                    try await bridge.installDeveloperImage(from: DeveloperImageStore.paths.directory)
                }

                isPrepared = true
                UserDefaults.standard.set(true, forKey: "flypin.devicePrepared")
                status = "裝置已準備完成。現在可從 FlyPin 網頁選擇位置並套用。"
            } catch {
                isPrepared = false
                UserDefaults.standard.set(false, forKey: "flypin.devicePrepared")
                status = "準備失敗：\(error.localizedDescription)"
                await bridge.disconnect()
            }
        }
    }

    func applySelectedCoordinate() async {
        guard pairingImported else {
            errorMessage = "請先匯入配對檔。"
            return
        }
        guard !isBusy else { return }

        isBusy = true
        status = "正在連線並套用座標…"
        defer { isBusy = false }

        do {
            try await bridge.connect(pairingFile: PairingFileStore.fileURL)
            guard try await bridge.hasMountedDeveloperImage() else {
                isPrepared = false
                UserDefaults.standard.set(false, forKey: "flypin.devicePrepared")
                status = "Developer Image 尚未掛載。請先按「連線與準備」。"
                return
            }
            try await bridge.setLocation(coordinate)
            isPrepared = true
            UserDefaults.standard.set(true, forKey: "flypin.devicePrepared")
            isSimulating = true
            status = "定位模擬已套用：\(coordinate.latitude), \(coordinate.longitude)"
        } catch {
            isPrepared = false
            UserDefaults.standard.set(false, forKey: "flypin.devicePrepared")
            isSimulating = false
            status = "套用失敗：\(error.localizedDescription)"
            await bridge.disconnect()
        }
    }

    func clearSimulation() async {
        guard !isBusy else { return }
        isBusy = true
        defer { isBusy = false }
        do {
            try await bridge.connect(pairingFile: PairingFileStore.fileURL)
            try await bridge.clearLocation()
            isSimulating = false
            status = "已要求 iPhone 清除定位模擬。"
        } catch {
            status = "清除失敗：\(error.localizedDescription)"
        }
        await bridge.disconnect()
    }
}
