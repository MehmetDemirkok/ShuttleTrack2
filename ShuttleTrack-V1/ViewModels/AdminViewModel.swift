import SwiftUI
import Combine
import FirebaseFirestore
import FirebaseFirestoreSwift

@MainActor
class AdminViewModel: ObservableObject {
    @Published var companies: [Company] = []
    @Published var users: [UserProfile] = []
    @Published var vehicles: [Vehicle] = []
    @Published var drivers: [Driver] = []
    @Published var trips: [Trip] = []
    @Published var isLoading = false
    @Published var errorMessage = ""
    @Published var searchText = ""

    private let db = Firestore.firestore()

    func loadAll() {
        isLoading = true
        errorMessage = ""
        let group = DispatchGroup()

        group.enter()
        db.collection("companies").getDocuments { [weak self] snap, err in
            DispatchQueue.main.async {
                if let err = err { self?.errorMessage = err.localizedDescription; group.leave(); return }
                self?.companies = (snap?.documents.compactMap { try? $0.data(as: Company.self) } ?? []).sorted { $0.createdAt > $1.createdAt }
                group.leave()
            }
        }

        group.enter()
        db.collection("userProfiles").getDocuments { [weak self] snap, err in
            DispatchQueue.main.async {
                if let err = err { self?.errorMessage = err.localizedDescription; group.leave(); return }
                self?.users = snap?.documents.compactMap { try? $0.data(as: UserProfile.self) } ?? []
                group.leave()
            }
        }

        group.enter()
        db.collection("vehicles").getDocuments { [weak self] snap, err in
            DispatchQueue.main.async {
                if let err = err { self?.errorMessage = err.localizedDescription; group.leave(); return }
                self?.vehicles = snap?.documents.compactMap { try? $0.data(as: Vehicle.self) } ?? []
                group.leave()
            }
        }

        group.enter()
        db.collection("drivers").getDocuments { [weak self] snap, err in
            DispatchQueue.main.async {
                if let err = err { self?.errorMessage = err.localizedDescription; group.leave(); return }
                self?.drivers = snap?.documents.compactMap { try? $0.data(as: Driver.self) } ?? []
                group.leave()
            }
        }

        group.enter()
        db.collection("trips").getDocuments { [weak self] snap, err in
            DispatchQueue.main.async {
                if let err = err { self?.errorMessage = err.localizedDescription; group.leave(); return }
                self?.trips = snap?.documents.compactMap { try? $0.data(as: Trip.self) } ?? []
                group.leave()
            }
        }

        group.notify(queue: .main) { [weak self] in
            self?.isLoading = false
        }
    }

    func setCompanyActive(_ companyId: String, isActive: Bool) {
        db.collection("companies").document(companyId).updateData(["isActive": isActive, "updatedAt": Date()]) { [weak self] err in
            DispatchQueue.main.async {
                if let err = err { self?.errorMessage = err.localizedDescription }
            }
        }
    }

    func setUserActive(_ userId: String, isActive: Bool) {
        db.collection("userProfiles").document(userId).updateData(["isActive": isActive, "updatedAt": Date()]) { [weak self] err in
            DispatchQueue.main.async {
                if let err = err { self?.errorMessage = err.localizedDescription }
            }
        }
    }

    func deleteCompany(_ companyId: String) {
        db.collection("companies").document(companyId).delete { [weak self] err in
            DispatchQueue.main.async {
                if let err = err { self?.errorMessage = err.localizedDescription } else { self?.loadAll() }
            }
        }
    }

    func deleteUser(_ userId: String) {
        db.collection("userProfiles").document(userId).delete { [weak self] err in
            DispatchQueue.main.async {
                if let err = err { self?.errorMessage = err.localizedDescription } else { self?.loadAll() }
            }
        }
    }

    func deleteVehicle(_ id: String) {
        db.collection("vehicles").document(id).delete { [weak self] err in
            DispatchQueue.main.async {
                if let err = err { self?.errorMessage = err.localizedDescription } else { self?.loadAll() }
            }
        }
    }

    func deleteDriver(_ id: String) {
        db.collection("drivers").document(id).delete { [weak self] err in
            DispatchQueue.main.async {
                if let err = err { self?.errorMessage = err.localizedDescription } else { self?.loadAll() }
            }
        }
    }

    func deleteTrip(_ id: String) {
        db.collection("trips").document(id).delete { [weak self] err in
            DispatchQueue.main.async {
                if let err = err { self?.errorMessage = err.localizedDescription } else { self?.loadAll() }
            }
        }
    }
}


