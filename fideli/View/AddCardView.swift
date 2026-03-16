import SwiftUI
import SwiftData
import CodeScanner
import AVFoundation

private let logoDevToken = "pk_LUWX9D8vSbippxZ9MbHxuQ"

struct AddCardView: View {
    @Environment(\.modelContext) private var modelContext

    @State private var brandName: String = ""
    @State private var website: String = ""
    @State private var selectedCardColor: Color = .blue
    @State private var barcodeValue: String = ""
    @State private var showSuccessAlert = false
    @State private var isShowingScanner = false
    @State private var isExtractingColor = false
    @State private var colorTask: Task<Void, Never>? = nil

    private var cleanDomain: String {
        website
            .lowercased()
            .trimmingCharacters(in: .whitespaces)
            .replacingOccurrences(of: "https://", with: "")
            .replacingOccurrences(of: "http://", with: "")
            .replacingOccurrences(of: "www.", with: "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Détails de l'enseigne")) {

                    // Logo + champ nom
                    HStack(spacing: 12) {
                        logoView
                        TextField("Nom (ex: Carrefour)", text: $brandName)
                            .autocorrectionDisabled()
                    }

                    // Site web optionnel
                    HStack {
                        TextField("Site web (optionnel, ex: lidl.fr)", text: $website)
                            .keyboardType(.URL)
                            .autocapitalization(.none)
                            .autocorrectionDisabled()
                            .onChange(of: website) { _, newValue in
                                colorTask?.cancel()
                                guard !newValue.isEmpty else { return }
                                // Debounce 800 ms — on attend que l'utilisateur finisse de taper
                                colorTask = Task {
                                    try? await Task.sleep(nanoseconds: 800_000_000)
                                    guard !Task.isCancelled else { return }
                                    await extractAndApplyColor()
                                }
                            }
                        if !website.isEmpty {
                            if isExtractingColor {
                                ProgressView().scaleEffect(0.7)
                                    .frame(width: 20, height: 20)
                            } else {
                                Button {
                                    website = ""
                                    colorTask?.cancel()
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.secondary)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    // Couleur — pré-remplie automatiquement, modifiable
                    ColorPicker("Couleur de la carte", selection: $selectedCardColor)

                    TextField("Numéro de la carte", text: $barcodeValue)
                        .keyboardType(.numberPad)
                }

                Section {
                    Button { isShowingScanner = true } label: {
                        Label("Scanner un code-barres", systemImage: "barcode.viewfinder")
                            .frame(maxWidth: .infinity)
                            .foregroundColor(.blue)
                    }
                }

                Section {
                    Button { saveCard() } label: {
                        Text("Enregistrer la carte")
                            .frame(maxWidth: .infinity)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                    }
                    .disabled(brandName.isEmpty || barcodeValue.isEmpty)
                }
            }
            .navigationTitle("Ajouter une carte")
            .alert("Carte sauvegardée !", isPresented: $showSuccessAlert) {
                Button("OK", role: .cancel) { resetForm() }
            }
            .sheet(isPresented: $isShowingScanner) {
                CodeScannerView(
                    codeTypes: [.ean13, .ean8, .qr, .code128],
                    simulatedData: "3123456789012",
                    completion: handleScan
                )
            }
        }
    }

    // MARK: - Logo

    @ViewBuilder
    private var logoView: some View {
        if cleanDomain.isEmpty {
            fallbackLogo
        } else {
            AsyncImage(url: URL(string: "https://img.logo.dev/\(cleanDomain)?token=\(logoDevToken)&size=80")) { phase in
                if let image = phase.image {
                    image.resizable().scaledToFill()
                        .frame(width: 44, height: 44)
                        .clipShape(Circle())
                        .shadow(radius: 1)
                } else {
                    fallbackLogo
                }
            }
        }
    }

    private var fallbackLogo: some View {
        Circle()
            .fill(selectedCardColor.opacity(0.85))
            .frame(width: 44, height: 44)
            .overlay(
                Text(brandName.isEmpty ? "?" : String(brandName.prefix(1)).uppercased())
                    .font(.headline).bold().foregroundColor(.white)
            )
    }

    // MARK: - Extraction couleur dominante

    private func extractAndApplyColor() async {
        let domain = cleanDomain
        guard !domain.isEmpty,
              let url = URL(string: "https://img.logo.dev/\(domain)?token=\(logoDevToken)&size=80")
        else { return }

        await MainActor.run { isExtractingColor = true }

        guard let (data, _) = try? await URLSession.shared.data(from: url),
              let uiImage = UIImage(data: data),
              let color = dominantColor(from: uiImage)
        else {
            await MainActor.run { isExtractingColor = false }
            return
        }

        await MainActor.run {
            selectedCardColor = color
            isExtractingColor = false
        }
    }

    /// Réduit l'image à 1×1 px pour obtenir la couleur moyenne,
    /// puis filtre le blanc/noir/gris pour garder une teinte vive.
    private func dominantColor(from image: UIImage) -> Color? {
        guard let cgImage = image.cgImage else { return nil }

        let size = CGSize(width: 1, height: 1)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        var pixel = [UInt8](repeating: 0, count: 4)

        guard let context = CGContext(
            data: &pixel,
            width: 1, height: 1,
            bitsPerComponent: 8, bytesPerRow: 4,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }

        context.draw(cgImage, in: CGRect(origin: .zero, size: size))

        let r = Double(pixel[0]) / 255
        let g = Double(pixel[1]) / 255
        let b = Double(pixel[2]) / 255
        let a = Double(pixel[3]) / 255

        guard a > 0.1 else { return nil }

        // Saturation minimale pour éviter blanc/noir/gris
        let maxC = max(r, g, b)
        let minC = min(r, g, b)
        let saturation = maxC > 0 ? (maxC - minC) / maxC : 0
        let brightness = maxC

        guard saturation > 0.25, brightness > 0.15, brightness < 0.97 else { return nil }

        return Color(red: r, green: g, blue: b)
    }

    // MARK: - Sauvegarde

    private func saveCard() {
        let newCard = LoyaltyCard(
            brandName: brandName,
            website: cleanDomain,
            barcodeType: "Code-barres",
            barcodeValue: barcodeValue,
            brandPrimaryColorHex: selectedCardColor.toHex()
        )
        modelContext.insert(newCard)
        showSuccessAlert = true
    }

    private func resetForm() {
        brandName = ""; website = ""; barcodeValue = ""
        selectedCardColor = .blue
        colorTask?.cancel()
        isExtractingColor = false
    }

    // MARK: - Scanner

    private func handleScan(result: Result<ScanResult, ScanError>) {
        isShowingScanner = false
        switch result {
        case .success(let scan): barcodeValue = scan.string
        case .failure(let error): print("Scan error: \(error.localizedDescription)")
        }
    }
}

#Preview {
    AddCardView()
        .modelContainer(for: LoyaltyCard.self, inMemory: true)
}
