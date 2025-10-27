import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

struct Company: Identifiable, Codable {
    @DocumentID var id: String?
    var name: String
    var email: String
    var phone: String
    var address: String
    var licenseNumber: String
    var isActive: Bool
    var createdAt: Date
    var updatedAt: Date
    
    init(name: String, email: String, phone: String, address: String, licenseNumber: String) {
        self.name = name
        self.email = email
        self.phone = phone
        self.address = address
        self.licenseNumber = licenseNumber
        self.isActive = true
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}
