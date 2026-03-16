import SwiftUI
import SwiftData

struct MyCardsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \LoyaltyCard.brandName) private var cards: [LoyaltyCard]
    
    @State private var selectedPreviewCard: LoyaltyCard? = nil
    @State private var cardToNavigate: LoyaltyCard? = nil
    @State private var isEditing = false
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(cards) { card in
                            CardRowView(
                                card: card,
                                selectedPreviewCard: $selectedPreviewCard,
                                isEditing: $isEditing,
                                onDelete: { deleteCard(card) }
                            )
                        }
                    }
                    .padding()
                }
                .onTapGesture {
                    if isEditing {
                        withAnimation { isEditing = false }
                    }
                }
                
                if cards.isEmpty {
                    ContentUnavailableView(
                        "Aucune carte",
                        systemImage: "creditcard.trianglebadge.exclamationmark",
                        description: Text("Appuyez sur l'onglet 'Ajouter' pour enregistrer votre première carte de fidélité.")
                    )
                }
                
                if let card = selectedPreviewCard {
                    CardPreviewOverlay(
                        card: card,
                        isPresented: $selectedPreviewCard,
                        cardToNavigate: $cardToNavigate
                    )
                }
            }
            .navigationTitle("Mes Cartes")
            .toolbar {
                if isEditing {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Terminé") {
                            withAnimation { isEditing = false }
                        }
                        .fontWeight(.bold)
                    }
                }
            }
            .navigationDestination(item: $cardToNavigate) { card in
                CardDetailView(card: card)
            }
        }
    }
    
    private func deleteCard(_ card: LoyaltyCard) {
        withAnimation {
            modelContext.delete(card)
        }
    }
}
