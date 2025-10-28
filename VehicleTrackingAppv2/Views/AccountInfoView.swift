import SwiftUI
import FirebaseAuth

struct AccountInfoView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var appViewModel: AppViewModel
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Hesap Bilgileri")) {
                    HStack {
                        Text("E-posta")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(appViewModel.currentUser?.email ?? "Bilinmiyor")
                            .foregroundColor(.primary)
                    }
                    
                    HStack {
                        Text("Kullanıcı ID")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(appViewModel.currentUser?.uid ?? "Bilinmiyor")
                            .foregroundColor(.primary)
                            .font(.caption)
                    }
                    
                    HStack {
                        Text("Hesap Oluşturma")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(formatDate(appViewModel.currentUser?.metadata.creationDate))
                            .foregroundColor(.primary)
                    }
                    
                    HStack {
                        Text("Son Giriş")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(formatDate(appViewModel.currentUser?.metadata.lastSignInDate))
                            .foregroundColor(.primary)
                    }
                }
                
                if let profile = appViewModel.currentUserProfile {
                    Section(header: Text("Profil Bilgileri")) {
                        HStack {
                            Text("Ad Soyad")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(profile.fullName.isEmpty ? "Belirtilmemiş" : profile.fullName)
                                .foregroundColor(.primary)
                        }
                        
                        HStack {
                            Text("Telefon")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(profile.phone ?? "Belirtilmemiş")
                                .foregroundColor(.primary)
                        }
                        
                        HStack {
                            Text("Kullanıcı Tipi")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(profile.userType.displayName)
                                .foregroundColor(.primary)
                        }
                        
                        HStack {
                            Text("Şirket ID")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(profile.companyId ?? "Belirtilmemiş")
                                .foregroundColor(.primary)
                                .font(.caption)
                        }
                    }
                }
                
                if let company = appViewModel.currentCompany {
                    Section(header: Text("Şirket Bilgileri")) {
                        HStack {
                            Text("Şirket Adı")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(company.name)
                                .foregroundColor(.primary)
                        }
                        
                        HStack {
                            Text("Şirket E-posta")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(company.email)
                                .foregroundColor(.primary)
                        }
                        
                        HStack {
                            Text("Şirket Telefon")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(company.phone)
                                .foregroundColor(.primary)
                        }
                    }
                }
                
                Section(header: Text("Güvenlik")) {
                    HStack {
                        Text("E-posta Doğrulandı")
                            .foregroundColor(.secondary)
                        Spacer()
                        Image(systemName: appViewModel.currentUser?.isEmailVerified == true ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(appViewModel.currentUser?.isEmailVerified == true ? .green : .red)
                    }
                }
            }
            .navigationTitle("Hesap Bilgileri")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                trailing: Button("Kapat") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
    
    private func formatDate(_ date: Date?) -> String {
        guard let date = date else { return "Bilinmiyor" }
        
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "tr_TR")
        
        return formatter.string(from: date)
    }
}

struct AccountInfoView_Previews: PreviewProvider {
    static var previews: some View {
        AccountInfoView()
    }
}
