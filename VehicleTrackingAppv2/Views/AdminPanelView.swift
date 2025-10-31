import SwiftUI

struct AdminPanelView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var viewModel = AdminViewModel()
    @State private var selectedTab = 0

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
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
            ForEach(viewModel.companies) { company in
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
            }
        }
    }

    private var usersTab: some View {
        List {
            ForEach(viewModel.users) { user in
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
            }
        }
    }

    private var vehiclesTab: some View {
        List(viewModel.vehicles) { v in
            VStack(alignment: .leading) {
                Text(v.displayName).font(.headline)
                Text(v.companyId).font(.caption).foregroundColor(.secondary)
            }
        }
    }

    private var driversTab: some View {
        List(viewModel.drivers) { d in
            VStack(alignment: .leading) {
                Text(d.fullName).font(.headline)
                Text(d.companyId).font(.caption).foregroundColor(.secondary)
            }
        }
    }

    private var tripsTab: some View {
        List(viewModel.trips) { t in
            VStack(alignment: .leading) {
                Text(t.displayName).font(.headline)
                Text("\(t.companyId) · \(t.statusText)").font(.caption).foregroundColor(.secondary)
            }
        }
    }
}


