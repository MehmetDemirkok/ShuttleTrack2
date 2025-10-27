import Foundation

struct Driver: Identifiable, Codable {
    let id: String
    var firstName: String
    var lastName: String
    var phoneNumber: String
    var isActive: Bool
    var assignedVehicleId: String?
    var companyId: String
    var createdAt: Date
    var updatedAt: Date
    
    init(id: String = UUID().uuidString,
         firstName: String,
         lastName: String,
         phoneNumber: String,
         isActive: Bool = true,
         companyId: String) {
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
        self.phoneNumber = phoneNumber
        self.isActive = isActive
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
    
    var statusColor: String {
        return isActive ? "green" : "red"
    }
    
}
