import Foundation
import SwiftData

@Model
final class LoyaltyCard {
    var id: UUID
    var brandName: String
    var website: String
    var barcodeType: String
    var barcodeValue: String
    var brandPrimaryColorHex: String
    var dateAdded: Date
    var code: String
    var notes: String

    init(brandName: String, website: String, barcodeType: String, barcodeValue: String, brandPrimaryColorHex: String = "#000000", code: String = "", notes: String = "") {
        self.id = UUID()
        self.brandName = brandName
        self.website = website
        self.barcodeType = barcodeType
        self.barcodeValue = barcodeValue
        self.brandPrimaryColorHex = brandPrimaryColorHex
        self.dateAdded = Date()
        self.code = code
        self.notes = notes
    }
}
