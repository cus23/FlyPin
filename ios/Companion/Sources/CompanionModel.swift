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
        status = "已收到 FlyPin 座標；尚未套用至系統定位"
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
            guard !(nsError.domain == NSCocoaErrorDomain && nsError.code == NSUserCancelledError) else {
                return
            }
            errorMessage = "檔案匯入失敗：\(error.localizedDescription)"
        }
    }

    func openLocalDevVPN() {
        guard let url = URL(string: "localdevvpn://enable") else { return }
        status = "已要求開啟 LocalDevVPN；等待使用者返回並驗證隧道"
        UIApplication.shared.open(url) { [weak self] opened in
            guard !opened else { return }
            self?.status = "無法開啟 LocalDevVPN。請先從 App Store 安裝並手動開啟一次。"
        }
    }

    func startSimulation() {
        // Intentionally fail closed until the independently implemented RSD/DVT
        // transport is integrated and tested on a physical iOS 26 device.
        status = "DVT 引擎尚未整合；目前不會假裝已變更系統定位"
    }

    func stopSimulation() {
        // Do not claim that location was cleared without a live DVT clear response.
        status = "目前沒有可確認的 DVT 工作階段"
    }
}
