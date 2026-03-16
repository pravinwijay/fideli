import SwiftUI

struct CardRowView: View {
    var card: LoyaltyCard
    @Binding var selectedPreviewCard: LoyaltyCard?
    @Binding var isEditing: Bool
    var onDelete: () -> Void
    
    @State private var rotation: Double = 0

    // Nouvelle règle : Noir uniquement si le fond est blanc !
    private var textColor: Color {
        let hex = card.brandPrimaryColorHex.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "#", with: "")
        var rgb: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&rgb)
        let r = Double((rgb >> 16) & 0xFF) / 255.0
        let g = Double((rgb >> 8) & 0xFF) / 255.0
        let b = Double(rgb & 0xFF) / 255.0
        
        // Si la couleur est du blanc pur (ou un gris/blanc très clair)
        if r > 0.95 && g > 0.95 && b > 0.95 {
            return .black
        }
        // Pour tout le reste (rouge, jaune, bleu, etc.)
        return .white
    }

    var body: some View {
        HStack(spacing: 12) {
            Text(card.brandName)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(textColor)
                .lineLimit(2)
                .minimumScaleFactor(0.7)
                .frame(maxWidth: .infinity, alignment: .leading)

            logoView
                .frame(width: 45, height: 45)
        }
        .padding(.horizontal, 16)
        .frame(height: 75)
        .background(Color(hex: card.brandPrimaryColorHex))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.12), radius: 3, x: 0, y: 2)
        .overlay(alignment: .topTrailing) {
            if isEditing {
                Button(action: onDelete) {
                    Image(systemName: "minus.circle.fill")
                        .font(.title3)
                        .foregroundColor(.red)
                        .background(Circle().fill(.white).frame(width: 18, height: 18))
                }
                .offset(x: 6, y: -6)
            }
        }
        .rotationEffect(.degrees(rotation))
        .onTapGesture {
            if !isEditing {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                    selectedPreviewCard = card
                }
            }
        }
        .onLongPressGesture {
            if !isEditing {
                withAnimation {
                    isEditing = true
                }
            }
        }
        .onChange(of: isEditing) { _, newValue in
            if newValue {
                rotation = Double.random(in: -1.5...1.5)
                withAnimation(.easeInOut(duration: 0.12).repeatForever(autoreverses: true)) {
                    rotation = rotation > 0 ? -2.0 : 2.0
                }
            } else {
                withAnimation {
                    rotation = 0
                }
            }
        }
    }

    @ViewBuilder
    private var logoView: some View {
        let cleanWeb = card.website.trimmingCharacters(in: .whitespaces).lowercased()

        if cleanWeb.isEmpty {
            fallbackLogo
        } else {
            AsyncImage(url: URL(string: "https://img.logo.dev/\(cleanWeb)?token=pk_LUWX9D8vSbippxZ9MbHxuQ&size=80")) { phase in
                if let image = phase.image {
                    image
                        .resizable()
                        .scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                } else if phase.error != nil {
                    fallbackLogo
                } else {
                    Color.clear
                }
            }
        }
    }

    private var fallbackLogo: some View {
        Text(String(card.brandName.prefix(1)).uppercased())
            .font(.title).bold()
            .foregroundColor(textColor)
    }
}
