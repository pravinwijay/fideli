import SwiftUI
import SwiftData
import CoreImage.CIFilterBuiltins

struct CardDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var card: LoyaltyCard

    var body: some View {
        Form {
            Section {
                VStack(spacing: 20) {
                    HStack {
                        Spacer()
                        logoView
                        Spacer()
                    }

                    if let barcodeImage = generateBarcode(from: card.barcodeValue) {
                        Image(uiImage: barcodeImage)
                            .interpolation(.none)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 100)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(10)
                            .shadow(radius: 1)
                    }

                    Text(card.barcodeValue)
                        .font(.title2)
                        .tracking(2)
                }
                .padding(.vertical)
                .listRowBackground(Color.clear)
            }

            Section(header: Text("Informations supplémentaires")) {
                TextField("Code (ex: code PIN, mot de passe)", text: $card.code)

                ZStack(alignment: .topLeading) {
                    if card.notes.isEmpty {
                        Text("Ajouter des notes...")
                            .foregroundColor(Color(UIColor.placeholderText))
                            .padding(.top, 8)
                            .padding(.leading, 4)
                    }
                    TextEditor(text: $card.notes)
                        .frame(minHeight: 100)
                }
            }
            
            // Nouvelle section pour modifier la couleur !
            Section(header: Text("Apparence")) {
                ColorPicker("Couleur de la carte", selection: Binding(
                    get: { Color(hex: card.brandPrimaryColorHex) },
                    set: { newColor in card.brandPrimaryColorHex = newColor.toHex() }
                ))
            }
        }
        .navigationTitle(card.brandName)
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private var logoView: some View {
        let cleanWeb = card.website.trimmingCharacters(in: .whitespaces)
        
        if cleanWeb.isEmpty {
            fallbackLogo
        } else {
            AsyncImage(url: URL(string: "https://img.logo.dev/\(cleanWeb)?token=pk_LUWX9D8vSbippxZ9MbHxuQ&size=160")) { phase in
                if let image = phase.image {
                    image.resizable().scaledToFill()
                        .frame(width: 80, height: 80)
                        .clipShape(Circle())
                        .shadow(radius: 2)
                } else if phase.error != nil {
                    fallbackLogo
                } else {
                    Circle()
                        .fill(Color(hex: card.brandPrimaryColorHex).opacity(0.8))
                        .frame(width: 80, height: 80)
                        .overlay(ProgressView().tint(.white))
                }
            }
        }
    }

    private var fallbackLogo: some View {
        Circle()
            .fill(Color(hex: card.brandPrimaryColorHex).opacity(0.8))
            .frame(width: 80, height: 80)
            .overlay(
                Text(String(card.brandName.prefix(1)).uppercased())
                    .font(.largeTitle).bold().foregroundColor(.white)
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
