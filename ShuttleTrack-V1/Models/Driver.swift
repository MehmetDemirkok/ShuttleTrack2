import Foundation
import SwiftUI
import FirebaseFirestore
import FirebaseFirestoreSwift

struct Driver: Identifiable, Codable {
    @DocumentID var id: String?
    var firstName: String
    var lastName: String
    var phoneNumber: String
    var email: String
    var authUserId: String?
    var isActive: Bool
    var assignedVehicleId: String?
    var companyId: String
    var createdAt: Date
    var updatedAt: Date
    
    init(id: String? = nil,
         firstName: String,
         lastName: String,
         phoneNumber: String,
         email: String,
         isActive: Bool = true,
         companyId: String) {
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
        self.phoneNumber = phoneNumber
        self.email = email
        self.isActive = isActive
        self.authUserId = nil
        self.assignedVehicleId = nil
        self.companyId = companyId
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    var fullName: String {
        return "\(firstName) \(lastName)"
    }
    
    var statusText: String {
        return isActive ? "Aktif" : "Pasif"
    }
    
    var statusColor: Color {
        return isActive ? .green : .red
    }
    
}
