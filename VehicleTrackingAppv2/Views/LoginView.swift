import SwiftUI
import FirebaseAuth

struct LoginView: View {
    @EnvironmentObject var appViewModel: AppViewModel
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var showingSignUp = false
    
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
                HStack {
                    Text("Hesabınız yok mu?")
                        .shuttleTrackCaption()
                    
                    Button("Kayıt Ol") {
                        showingSignUp = true
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
    }
    
    private func signIn() {
        isLoading = true
        errorMessage = ""
        
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            DispatchQueue.main.async {
                isLoading = false
                if let error = error {
                    errorMessage = error.localizedDescription
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
