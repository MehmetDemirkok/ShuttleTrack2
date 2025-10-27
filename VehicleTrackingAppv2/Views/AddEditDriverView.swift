import SwiftUI

struct AddEditDriverView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var viewModel: DriverViewModel
    @StateObject private var appViewModel: AppViewModel
    
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var phoneNumber = ""
    @State private var isActive = true
    @State private var isLoading = false
    @State private var errorMessage = ""
    
    let driver: Driver?
    let isEditing: Bool
    
    init(driver: Driver? = nil, viewModel: DriverViewModel, appViewModel: AppViewModel) {
        self.driver = driver
        self.isEditing = driver != nil
        self._viewModel = StateObject(wrappedValue: viewModel)
        self._appViewModel = StateObject(wrappedValue: appViewModel)
        
        if let driver = driver {
            _firstName = State(initialValue: driver.firstName)
            _lastName = State(initialValue: driver.lastName)
            _phoneNumber = State(initialValue: driver.phoneNumber)
            _isActive = State(initialValue: driver.isActive)
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Kişisel Bilgiler")) {
                    TextField("Ad", text: $firstName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    TextField("Soyad", text: $lastName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    TextField("Telefon", text: $phoneNumber)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.phonePad)
                }
                
                Section(header: Text("Durum")) {
                    Toggle("Aktif", isOn: $isActive)
                }
                
                if !errorMessage.isEmpty {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle(isEditing ? "Şoför Düzenle" : "Yeni Şoför")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("İptal") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Kaydet") {
                    saveDriver()
                }
                .disabled(isLoading || firstName.isEmpty || lastName.isEmpty || phoneNumber.isEmpty)
            )
        }
    }
    
    private func saveDriver() {
        isLoading = true
        errorMessage = ""
        
        guard let companyId = appViewModel.currentCompany?.id else {
            errorMessage = "Şirket bilgisi bulunamadı"
            isLoading = false
            return
        }
        
        let newDriver = Driver(
            id: driver?.id ?? UUID().uuidString,
            firstName: firstName,
            lastName: lastName,
            phoneNumber: phoneNumber,
            isActive: isActive,
            companyId: companyId
        )
        
        if isEditing {
            viewModel.updateDriver(newDriver)
        } else {
            viewModel.addDriver(newDriver)
        }
        
        // Simulate save completion
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            isLoading = false
            if viewModel.errorMessage.isEmpty {
                presentationMode.wrappedValue.dismiss()
            } else {
                errorMessage = viewModel.errorMessage
            }
        }
    }
}

struct AddEditDriverView_Previews: PreviewProvider {
    static var previews: some View {
        AddEditDriverView(
            viewModel: DriverViewModel(),
            appViewModel: AppViewModel()
        )
    }
}
