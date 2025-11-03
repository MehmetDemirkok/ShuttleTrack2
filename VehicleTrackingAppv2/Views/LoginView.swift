import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import FirebaseFirestoreSwift

struct LoginView: View {
    @EnvironmentObject var appViewModel: AppViewModel
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var showingSignUp = false
    @State private var showingDriverOTP = false
    @State private var showAlert = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: ShuttleTrackTheme.Spacing.xl) {
                // Logo ve Başlık
                VStack(spacing: ShuttleTrackTheme.Spacing.lg) {
                    LogoView(size: 120)
                        .padding(.top, ShuttleTrackTheme.Spacing.xxl)
                    
                    VStack(spacing: ShuttleTrackTheme.Spacing.sm) {
                        Text("Hoş Geldiniz!")
                            .shuttleTrackTitle()
                        
                        Text("ShuttleTrack ile araçlarınızı takip edin")
                            .shuttleTrackCaption()
                            .multilineTextAlignment(.center)
                    }
                }
                
                Spacer()
                
                // Giriş Formu
                ShuttleTrackCard {
                    VStack(spacing: ShuttleTrackTheme.Spacing.md) {
                        // Email Field
                        VStack(alignment: .leading, spacing: ShuttleTrackTheme.Spacing.sm) {
                            Text("E-posta")
                                .shuttleTrackCaption()
                                .foregroundColor(.primary)
                            
                            TextField("ornek@email.com", text: $email)
                                .textFieldStyle(ShuttleTrackTextFieldStyle())
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                        }
                        
                        // Password Field
                        VStack(alignment: .leading, spacing: ShuttleTrackTheme.Spacing.sm) {
                            Text("Şifre")
                                .shuttleTrackCaption()
                                .foregroundColor(.primary)
                            
                            SecureField("••••••••", text: $password)
                                .textFieldStyle(ShuttleTrackTextFieldStyle())
                        }
                        
                        // Error Message
                        if !errorMessage.isEmpty {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(ShuttleTrackTheme.Colors.error)
                                Text(errorMessage)
                                    .shuttleTrackCaption()
                                    .foregroundColor(ShuttleTrackTheme.Colors.error)
                            }
                            .padding(.top, ShuttleTrackTheme.Spacing.sm)
                        }
                        
                        // Login Button
                        Button(action: signIn) {
                            HStack {
                                if isLoading {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                        .foregroundColor(.white)
                                }
                                Text("Giriş Yap")
                            }
                        }
                        .buttonStyle(ShuttleTrackButtonStyle(variant: .primary, size: .large))
                        .disabled(isLoading || email.isEmpty || password.isEmpty)
                        .padding(.top, ShuttleTrackTheme.Spacing.md)
                    }
                }
                .padding(.horizontal, ShuttleTrackTheme.Spacing.lg)
                
                // Sign Up Link
                VStack(spacing: 8) {
                    HStack {
                        Text("Hesabınız yok mu?")
                            .shuttleTrackCaption()
                        Button("Kayıt Ol") {
                            showingSignUp = true
                        }
                        .foregroundColor(ShuttleTrackTheme.Colors.primaryBlue)
                        .font(.system(size: 14, weight: .semibold))
                    }
                    Button("Sürücü OTP ile Giriş Yap") {
                        showingDriverOTP = true
                    }
                    .foregroundColor(ShuttleTrackTheme.Colors.primaryBlue)
                    .font(.system(size: 14, weight: .semibold))
                }
                
                Spacer()
            }
            .background(ShuttleTrackTheme.Colors.background)
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showingSignUp) {
            SignUpView()
        }
        .sheet(isPresented: $showingDriverOTP) {
            DriverOTPLoginView()
                .environmentObject(appViewModel)
        }
        .onReceive(appViewModel.$authMessage) { message in
            if !message.isEmpty {
                self.errorMessage = message
                self.showAlert = true
                appViewModel.authMessage = ""
            }
        }
        .onAppear {
            // Sign-out sonrası AppViewModel.authMessage zaten dolu olabilir; giriş ekranı açılır açılmaz göster
            if !appViewModel.authMessage.isEmpty {
                self.errorMessage = appViewModel.authMessage
                self.showAlert = true
                appViewModel.authMessage = ""
            }
        }
        .ignoresSafeArea(.keyboard)
        .alert("Bilgi", isPresented: $showAlert) {
            Button("Tamam") { showAlert = false }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func signIn() {
        isLoading = true
        errorMessage = ""
        
        let loginEmail: String = (email == "Admin") ? "admin@shuttletrack.local" : email
        Auth.auth().signIn(withEmail: loginEmail, password: password) { result, error in
            DispatchQueue.main.async {
                isLoading = false
                if let error = error {
                    errorMessage = error.localizedDescription
                } else if let user = result?.user {
                    // Profili kontrol et: aktif değilse çıkış yap ve bilgilendir
                    let db = Firestore.firestore()
                    db.collection("userProfiles").document(user.uid).getDocument { snapshot, err in
                        DispatchQueue.main.async {
                            if let err = err {
                                // Sessizce geç; AppViewModel yüklemeye çalışacak
                                print("⚠️ Profil kontrol hatası: \(err.localizedDescription)")
                                return
                            }
                            if let snapshot = snapshot, snapshot.exists {
                                do {
                                    let profile = try snapshot.data(as: UserProfile.self)
                                    if !(profile.userType == .owner) && profile.isActive == false {
                                        do { try Auth.auth().signOut() } catch { }
                                        self.errorMessage = "Hesabınız onay beklemektedir. Lütfen uygulama yetkilileri tarafından onaylanana kadar bekleyiniz."
                                        self.showAlert = true
                                    }
                                } catch {
                                    // Decode hatası durumunda bir şey yapma
                                }
                            } else {
                                // Profil yoksa büyük ihtimalle onay süreci bekleniyor
                                do { try Auth.auth().signOut() } catch { }
                                self.errorMessage = "Hesabınız onay beklemektedir. Lütfen uygulama yetkilileri tarafından onaylanana kadar bekleyiniz."
                                self.showAlert = true
                            }
                        }
                    }
                }
            }
        }
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
}
