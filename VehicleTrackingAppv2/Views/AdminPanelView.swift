import SwiftUI

struct AdminPanelView: View {
    @EnvironmentObject var appViewModel: AppViewModel
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var viewModel = AdminViewModel()
    @State private var selectedTab = 0

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Üst Sekme - kapsayıcı kart görünümü
                ShuttleTrackCard {
                    Picker("Kategori", selection: $selectedTab) {
                    Text("Şirketler").tag(0)
                    Text("Kullanıcılar").tag(1)
                    Text("Araçlar").tag(2)
                    Text("Sürücüler").tag(3)
                    Text("İşler").tag(4)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
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
            .navigationBarItems(
                leading: Button(action: { appViewModel.signOut() }) { Image(systemName: "power").foregroundColor(.red) },
                trailing: Button(action: { viewModel.loadAll() }) { Image(systemName: "arrow.clockwise") }
            )
            .onAppear { viewModel.loadAll() }
            .ignoresSafeArea(.keyboard, edges: .bottom)
        }
        .scrollDismissesKeyboard(.interactively)
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
                ShuttleTrackCard {
                    HStack(alignment: .center, spacing: 12) {
                        ZStack {
                            Circle().fill(ShuttleTrackTheme.Colors.secondaryBlue.opacity(0.2))
                            Text(String(company.name.prefix(2)).uppercased())
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(ShuttleTrackTheme.Colors.primaryBlue)
                        }
                        .frame(width: 40, height: 40)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(company.name).font(.headline)
                            HStack(spacing: 8) {
                                Image(systemName: "envelope.fill").foregroundColor(ShuttleTrackTheme.Colors.envelopeIcon)
                                Text(company.email).font(.caption).foregroundColor(.secondary)
                            }
                            Text(company.taxNumber).font(.caption2).foregroundColor(.secondary)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 8) {
                            Text(company.isActive ? "Aktif" : "Pasif")
                                .font(.caption)
                                .foregroundColor(company.isActive ? ShuttleTrackTheme.Colors.success : ShuttleTrackTheme.Colors.error)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background((company.isActive ? ShuttleTrackTheme.Colors.success : ShuttleTrackTheme.Colors.error).opacity(0.1))
                                .cornerRadius(10)
                            Toggle("", isOn: Binding(
                                get: { company.isActive },
                                set: { viewModel.setCompanyActive(company.id ?? "", isActive: $0) }
                            ))
                            .labelsHidden()
                        }
                    }
                }
                .listRowSeparator(.hidden)
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) { if let id = company.id { viewModel.deleteCompany(id) } } label: { Label("Sil", systemImage: "trash") }
                }
            }
        }
        .listStyle(.plain)
    }

    private var usersTab: some View {
        List {
            ForEach(viewModel.users.filter { viewModel.searchText.isEmpty ? true : (userMatch($0, viewModel.searchText)) }) { user in
                ShuttleTrackCard {
                    HStack(spacing: 12) {
                        Image(systemName: "person.crop.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(ShuttleTrackTheme.Colors.personIcon)
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
                }
                .listRowSeparator(.hidden)
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) { viewModel.deleteUser(user.userId) } label: { Label("Sil", systemImage: "trash") }
                }
            }
        }
        .listStyle(.plain)
    }

    private var vehiclesTab: some View {
        List(viewModel.vehicles.filter { viewModel.searchText.isEmpty ? true : (vMatch($0, viewModel.searchText)) }) { v in
            ShuttleTrackCard {
                HStack(spacing: 12) {
                    Image(systemName: "car.fill")
                        .font(.system(size: 28))
                        .foregroundColor(ShuttleTrackTheme.Colors.vehicleIcon)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(v.displayName).font(.headline)
                        Text("Kapasite: \(v.capacity) • \(v.vehicleType.displayName)").font(.caption).foregroundColor(.secondary)
                    }
                    Spacer()
                    Text(v.statusText)
                        .font(.caption)
                        .foregroundColor(v.statusColor)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(v.statusColor.opacity(0.1))
                        .cornerRadius(10)
                }
            }
            .listRowSeparator(.hidden)
            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                Button(role: .destructive) { viewModel.deleteVehicle(v.id) } label: { Label("Sil", systemImage: "trash") }
            }
        }
        .listStyle(.plain)
    }

    private var driversTab: some View {
        List(viewModel.drivers.filter { viewModel.searchText.isEmpty ? true : (dMatch($0, viewModel.searchText)) }) { d in
            ShuttleTrackCard {
                HStack(spacing: 12) {
                    Image(systemName: "steeringwheel")
                        .font(.system(size: 28))
                        .foregroundColor(ShuttleTrackTheme.Colors.primaryPurple)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(d.fullName).font(.headline)
                        Text("Tel: \(d.phoneNumber)").font(.caption).foregroundColor(.secondary)
                    }
                    Spacer()
                    Text(d.statusText)
                        .font(.caption)
                        .foregroundColor(d.statusColor)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(d.statusColor.opacity(0.1))
                        .cornerRadius(10)
                }
            }
            .listRowSeparator(.hidden)
            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                Button(role: .destructive) { viewModel.deleteDriver(d.id) } label: { Label("Sil", systemImage: "trash") }
            }
        }
        .listStyle(.plain)
    }

    private var tripsTab: some View {
        List(viewModel.trips.filter { t in viewModel.searchText.isEmpty ? true : (t.displayName.lowercased().contains(viewModel.searchText.lowercased())) }) { t in
            ShuttleTrackCard {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(t.tripNumber).font(.headline)
                        Spacer()
                        Text(t.statusText)
                            .font(.caption)
                            .foregroundColor(t.statusColor)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(t.statusColor.opacity(0.1))
                            .cornerRadius(10)
                    }
                    HStack(spacing: 8) {
                        Image(systemName: "mappin.and.ellipse").foregroundColor(ShuttleTrackTheme.Colors.pickupIcon)
                        Text(t.pickupLocation.name).font(.caption).foregroundColor(.secondary)
                        Image(systemName: "arrow.right").foregroundColor(.secondary)
                        Text(t.dropoffLocation.name).font(.caption).foregroundColor(.secondary)
                    }
                }
            }
            .listRowSeparator(.hidden)
            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                if let id = t.id {
                    Button(role: .destructive) { viewModel.deleteTrip(id) } label: { Label("Sil", systemImage: "trash") }
                }
            }
        }
        .listStyle(.plain)
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


