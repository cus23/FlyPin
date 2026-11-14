import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @EnvironmentObject private var model: CompanionModel

    var body: some View {
        NavigationStack {
            Form {
                Section("FlyPin 座標") {
                    coordinateRow("緯度", value: model.coordinate.latitude)
                    coordinateRow("經度", value: model.coordinate.longitude)
                    Text("座標由 FlyPin 網頁透過 flypin-companion://set-location 傳入。")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("裝置配對") {
                    HStack {
                        Text("配對檔")
                        Spacer()
                        Text(model.pairingImported ? "已匯入" : "尚未匯入")
                            .foregroundStyle(model.pairingImported ? .green : .secondary)
                    }
                    Button("匯入此 iPhone 的配對檔") {
                        model.showingPairingImporter = true
                    }
                    Text("配對檔是敏感憑證，只儲存在本機受保護的 App Support 目錄，不會上傳。")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("LocalDevVPN") {
                    Button("開啟 LocalDevVPN") {
                        model.openLocalDevVPN()
                    }
                    Text("開啟回呼不代表隧道已連線；正式版本會在此處加入實際連線驗證。")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("定位模擬") {
                    Button("Start（尚未啟用）") {
                        model.startSimulation()
                    }
                    .disabled(true)

                    Button("Stop（尚未啟用）", role: .destructive) {
                        model.stopSimulation()
                    }
                    .disabled(true)

                    Text("DVT / RSD 傳輸尚未整合。按鈕目前刻意停用，避免顯示不實的定位成功狀態。")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("狀態") {
                    Text(model.status)
                        .font(.callout)
                }
            }
            .navigationTitle("FlyPin Companion")
            .fileImporter(
                isPresented: $model.showingPairingImporter,
                allowedContentTypes: [.propertyList, .data],
                allowsMultipleSelection: false,
                onCompletion: model.importPairingFile
            )
            .alert("FlyPin Companion", isPresented: Binding(
                get: { model.errorMessage != nil },
                set: { if !$0 { model.errorMessage = nil } }
            )) {
                Button("確定", role: .cancel) {
                    model.errorMessage = nil
                }
            } message: {
                Text(model.errorMessage ?? "")
            }
        }
    }

    private func coordinateRow(_ title: String, value: Double) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(value.formatted(.number.precision(.fractionLength(6))))
                .monospacedDigit()
        }
    }
}
