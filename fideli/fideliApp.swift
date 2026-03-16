import SwiftUI
import SwiftData

@main
struct fideliApp: App {
    var body: some Scene {
        WindowGroup {
            MainTabView()
        }
        .modelContainer(for: LoyaltyCard.self)
    }
}
