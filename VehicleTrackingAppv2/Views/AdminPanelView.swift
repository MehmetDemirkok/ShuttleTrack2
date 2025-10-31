import SwiftUI

struct AdminPanelView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var viewModel = AdminViewModel()
    @State private var selectedTab = 0

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                Picker("Kategori", selection: $selectedTab) {
                    Text("Şirketler").tag(0)
                    Text("Kullanıcılar").tag(1)
                    Text("Araçlar").tag(2)
                    Text("Sürücüler").tag(3)
                    Text("İşler").tag(4)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)

                HStack {
                    Image(systemName: "magnifyingglass").foregroundColor(.secondary)
                    TextField("Ara...", text: $viewModel.searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                }
                .padding(12)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
                .padding([.horizontal, .top])
                TabView(selection: $selectedTab) {
                    companiesTab.tag(0)
                    usersTab.tag(1)
                    vehiclesTab.tag(2)
                    driversTab.tag(3)
                    tripsTab.tag(4)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
            .navigationTitle(tabTitle)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button(action: { viewModel.loadAll() }) { Image(systemName: "arrow.clockwise") })
            .onAppear { viewModel.loadAll() }
        }
    }

    private var tabTitle: String {
        switch selectedTab {
        case 0: return "Şirketler"
        case 1: return "Kullanıcılar"
        case 2: return "Araçlar"
        case 3: return "Sürücüler"
        case 4: return "İşler"
        default: return "Admin Paneli"
        }
    }

    private var companiesTab: some View {
        List {
            ForEach(viewModel.companies.filter { viewModel.searchText.isEmpty ? true : ($0.name.lowercased().contains(viewModel.searchText.lowercased()) || $0.email.lowercased().contains(viewModel.searchText.lowercased())) }) { company in
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(company.name).font(.headline)
                        Text(company.email).font(.caption).foregroundColor(.secondary)
                        Text(company.taxNumber).font(.caption2).foregroundColor(.secondary)
                    }
                    Spacer()
                    Toggle("", isOn: Binding(
                        get: { company.isActive },
                        set: { viewModel.setCompanyActive(company.id ?? "", isActive: $0) }
                    ))
                    .labelsHidden()
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) { if let id = company.id { viewModel.deleteCompany(id) } } label: { Label("Sil", systemImage: "trash") }
                }
            }
        }
    }

    private var usersTab: some View {
        List {
            ForEach(viewModel.users.filter { viewModel.searchText.isEmpty ? true : (userMatch($0, viewModel.searchText)) }) { user in
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(user.fullName).font(.headline)
                        Text(user.email).font(.caption).foregroundColor(.secondary)
                        Text(user.userType.displayName).font(.caption2).foregroundColor(.secondary)
                    }
                    Spacer()
                    Toggle("", isOn: Binding(
                        get: { user.isActive },
                        set: { viewModel.setUserActive(user.userId, isActive: $0) }
                    ))
                    .labelsHidden()
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) { viewModel.deleteUser(user.userId) } label: { Label("Sil", systemImage: "trash") }
                }
            }
        }
    }

    private var vehiclesTab: some View {
        List(viewModel.vehicles.filter { viewModel.searchText.isEmpty ? true : (vMatch($0, viewModel.searchText)) }) { v in
            VStack(alignment: .leading) {
                Text(v.displayName).font(.headline)
                Text(v.companyId).font(.caption).foregroundColor(.secondary)
            }
            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                Button(role: .destructive) { viewModel.deleteVehicle(v.id) } label: { Label("Sil", systemImage: "trash") }
            }
        }
    }

    private var driversTab: some View {
        List(viewModel.drivers.filter { viewModel.searchText.isEmpty ? true : (dMatch($0, viewModel.searchText)) }) { d in
            VStack(alignment: .leading) {
                Text(d.fullName).font(.headline)
                Text(d.companyId).font(.caption).foregroundColor(.secondary)
            }
            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                Button(role: .destructive) { viewModel.deleteDriver(d.id) } label: { Label("Sil", systemImage: "trash") }
            }
        }
    }

    private var tripsTab: some View {
        List(viewModel.trips.filter { t in viewModel.searchText.isEmpty ? true : (t.displayName.lowercased().contains(viewModel.searchText.lowercased())) }) { t in
            VStack(alignment: .leading) {
                Text(t.displayName).font(.headline)
                Text("\(t.companyId) · \(t.statusText)").font(.caption).foregroundColor(.secondary)
            }
            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                if let id = t.id {
                    Button(role: .destructive) { viewModel.deleteTrip(id) } label: { Label("Sil", systemImage: "trash") }
                }
            }
        }
    }

    private func userMatch(_ u: UserProfile, _ q: String) -> Bool {
        let lq = q.lowercased()
        return u.fullName.lowercased().contains(lq) || u.email.lowercased().contains(lq) || (u.companyId ?? "").lowercased().contains(lq)
    }
    private func vMatch(_ v: Vehicle, _ q: String) -> Bool {
        let lq = q.lowercased()
        return v.displayName.lowercased().contains(lq) || v.companyId.lowercased().contains(lq)
    }
    private func dMatch(_ d: Driver, _ q: String) -> Bool {
        let lq = q.lowercased()
        return d.fullName.lowercased().contains(lq) || d.companyId.lowercased().contains(lq)
    }
}


