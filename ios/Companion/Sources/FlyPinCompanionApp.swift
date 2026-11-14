import SwiftUI

@main
struct FlyPinCompanionApp: App {
    @StateObject private var model = CompanionModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(model)
                .onOpenURL { url in
                    model.handleIncomingURL(url)
                }
        }
    }
}
