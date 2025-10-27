import Foundation
import FirebaseFirestore

struct UserProfile: Codable, Identifiable {
    var id: String?
    let userId: String
    var userType: UserType
    var email: String
    var fullName: String
    var phone: String?
    var companyId: String?
    var driverLicenseNumber: String?
    let isActive: Bool
    let createdAt: Date
    var updatedAt: Date?
    var lastLoginAt: Date?
    
    init(userId: String, userType: UserType, email: String, fullName: String, phone: String? = nil, companyId: String? = nil, driverLicenseNumber: String? = nil) {
        self.userId = userId
        self.userType = userType
        self.email = email
        self.fullName = fullName
        self.phone = phone
        self.companyId = companyId
        self.driverLicenseNumber = driverLicenseNumber
        self.isActive = true
        self.createdAt = Date()
        self.updatedAt = nil
        self.lastLoginAt = nil
    }
}
