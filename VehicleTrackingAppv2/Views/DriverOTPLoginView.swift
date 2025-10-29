import SwiftUI

struct DriverOTPLoginView: View {
    @EnvironmentObject var appViewModel: AppViewModel
    @StateObject private var viewModel = DriverOTPViewModel()
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Sürücü Girişi")
                    .font(.title)
                    .fontWeight(.bold)
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Telefon Numarası")
                        .font(.caption)
                    TextField("+90 5xx xxx xx xx", text: $viewModel.phoneNumber)
                        .keyboardType(.phonePad)
                        .textFieldStyle(ShuttleTrackTextFieldStyle())
                }
                .padding(.horizontal)
                
                if viewModel.isCodeSent {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("SMS Kodu")
                            .font(.caption)
                        TextField("123456", text: $viewModel.smsCode)
                            .keyboardType(.numberPad)
                            .textFieldStyle(ShuttleTrackTextFieldStyle())
                    }
                    .padding(.horizontal)
                }
                
                if !viewModel.errorMessage.isEmpty {
                    Text(viewModel.errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding(.top, 4)
                }
                if !viewModel.infoMessage.isEmpty {
                    Text(viewModel.infoMessage)
                        .foregroundColor(.green)
                        .font(.caption)
                        .padding(.top, 4)
                }
                
                Button(action: {
                    if viewModel.isCodeSent {
                        viewModel.verifyAndSignIn(appViewModel: appViewModel)
                    } else {
                        viewModel.sendCode()
                    }
                }) {
                    HStack {
                        if viewModel.isLoading { ProgressView().tint(.white) }
                        Text(viewModel.isCodeSent ? "Giriş Yap" : "Kodu Gönder")
                    }
                }
                .buttonStyle(ShuttleTrackButtonStyle(variant: .primary, size: .large))
                .padding(.horizontal)
                .disabled(viewModel.isLoading)
                
                Spacer()
            }
            .navigationBarItems(leading: Button("Kapat") { presentationMode.wrappedValue.dismiss() })
        }
        .ignoresSafeArea(.keyboard)
    }
}


