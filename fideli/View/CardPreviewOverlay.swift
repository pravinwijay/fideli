import SwiftUI
import CoreImage.CIFilterBuiltins

struct CardPreviewOverlay: View {
    var card: LoyaltyCard
    @Binding var isPresented: LoyaltyCard?
    @Binding var cardToNavigate: LoyaltyCard?

    private var textColor: Color {
        let hex = card.brandPrimaryColorHex.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "#", with: "")
        var rgb: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&rgb)
        let r = Double((rgb >> 16) & 0xFF) / 255.0
        let g = Double((rgb >> 8) & 0xFF) / 255.0
        let b = Double(rgb & 0xFF) / 255.0
        let luminance = 0.299 * r + 0.587 * g + 0.114 * b
        return luminance > 0.7 ? .black : .white
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .background(.ultraThinMaterial)
                .onTapGesture {
                    withAnimation { isPresented = nil }
                }

            VStack(spacing: 24) {
                HStack {
                    logoView
                        .frame(width: 50, height: 50)

                    Text(card.brandName)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(textColor)
                    
                    Spacer()
                    
                    Button {
                        withAnimation { isPresented = nil }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundColor(textColor)
                    }
                }
                
                VStack(spacing: 12) {
                    if let barcodeImage = generateBarcode(from: card.barcodeValue) {
                        Image(uiImage: barcodeImage)
                            .interpolation(.none)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: .infinity, maxHeight: 120)
                    }
                    Text(card.barcodeValue)
                        .font(.title3)
                        .tracking(3)
                        .foregroundColor(.black)
                }
                .padding(20)
                .background(Color.white)
                .cornerRadius(16)
                
                Button(action: {
                    withAnimation { isPresented = nil }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        cardToNavigate = card
                    }
                }) {
                    Text("Voir les détails")
                        .font(.headline)
                        .foregroundColor(textColor == .black ? .white : Color(hex: card.brandPrimaryColorHex))
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(textColor == .black ? Color.black : Color.white)
                        .cornerRadius(12)
                }
            }
            .padding(24)
            .background(Color(hex: card.brandPrimaryColorHex))
            .cornerRadius(24)
            .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
            .padding(30)
            .offset(y: -60)
        }
        .transition(.opacity.combined(with: .scale(scale: 0.95)))
        .zIndex(2)
    }

    @ViewBuilder
    private var logoView: some View {
        let cleanWeb = card.website.trimmingCharacters(in: .whitespaces).lowercased()
        
        if cleanWeb.isEmpty {
            fallbackLogo
        } else {
            AsyncImage(url: URL(string: "https://img.logo.dev/\(cleanWeb)?token=pk_LUWX9D8vSbippxZ9MbHxuQ&size=80")) { phase in
                if let image = phase.image {
                    image.resizable().scaledToFill()
                        .clipShape(Circle())
                } else if phase.error != nil {
                    fallbackLogo
                } else {
                    Circle()
                        .fill(.white.opacity(0.3))
                        .overlay(ProgressView().tint(.white))
                }
            }
        }
    }

    private var fallbackLogo: some View {
        Circle()
            .fill(.white.opacity(0.3))
            .overlay(
                Text(String(card.brandName.prefix(1)).uppercased())
                    .font(.title2).bold().foregroundColor(textColor)
            )
    }

    private func generateBarcode(from string: String) -> UIImage? {
        let filter = CIFilter.code128BarcodeGenerator()
        guard let data = string.data(using: .ascii) else { return nil }
        filter.message = data
        if let outputImage = filter.outputImage {
            let transform = CGAffineTransform(scaleX: 10, y: 10)
            let scaledImage = outputImage.transformed(by: transform)
            let context = CIContext()
            if let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) {
                return UIImage(cgImage: cgImage)
            }
        }
        return nil
    }
}
