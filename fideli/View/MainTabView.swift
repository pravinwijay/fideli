import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            MyCardsView()
                .tabItem {
                    Label("Mes cartes", systemImage: "creditcard.fill")
                }
            
            AddCardView()
                .tabItem {
                    Label("Ajouter", systemImage: "plus.circle.fill")
                }
            
            AccountView()
                .tabItem {
                    Label("Mon compte", systemImage: "person.crop.circle.fill")
                }
            
            SettingsView()
                .tabItem {
                    Label("Réglages", systemImage: "gearshape.fill")
                }
        }
    }
}
