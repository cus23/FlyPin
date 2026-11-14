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
                    Text("從 FlyPin 網頁選取位置後，座標會自動傳到這裡。")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("Apple 健康步數") {
                    Button {
                        Task { await model.readHealthStepsAndReturnToWeb() }
                    } label: {
                        Label("讀取健康 App 今日步數並返回 FlyPin", systemImage: "heart.text.square")
                    }
                    Text("透過 HealthKit 讀取 Apple 健康中可授權讀取的今日步數來源。FlyPin 自訂步數只會保存在 FlyPin，不會寫入 Apple 健康。")
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
                    Text("配對檔只儲存在本機受保護的 App Support 目錄，不會上傳。")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("LocalDevVPN") {
                    Button("開啟 LocalDevVPN") { model.openLocalDevVPN() }
                    Text("啟動後切回 FlyPin Companion，再按下方連線。")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("裝置準備") {
                    Button {
                        model.prepareDevice()
                    } label: {
                        if model.isBusy {
                            HStack { ProgressView(); Text("處理中…") }
                        } else {
                            Text("連線與準備（RSD + Developer Image）")
                        }
                    }
                    .disabled(model.isBusy || !model.pairingImported)

                    if model.isPrepared {
                        Label("裝置已準備", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    }
                }

                Section("定位模擬") {
                    Button("套用目前座標") {
                        Task { await model.applySelectedCoordinate() }
                    }
                    .disabled(model.isBusy || !model.pairingImported)

                    Button("停止並清除模擬定位", role: .destructive) {
                        Task { await model.clearSimulation() }
                    }
                    .disabled(model.isBusy || !model.pairingImported)

                    if model.isSimulating {
                        Label("定位模擬已啟用", systemImage: "location.fill")
                            .foregroundStyle(.green)
                    }
                    Text("若已完成準備，從 FlyPin 網頁再次送出座標即可切換位置。")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("狀態") {
                    Text(model.status)
                        .font(.callout)
                        .textSelection(.enabled)
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
                Button("確定", role: .cancel) { model.errorMessage = nil }
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
