import SwiftUI

struct TrackingView: View {
    var body: some View {
        NavigationView {
            VStack {
                Text("Araç Takibi")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding()
                
                Text("Araç konumları burada görünecek")
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .navigationTitle("Takip")
        }
    }
}

struct TrackingView_Previews: PreviewProvider {
    static var previews: some View {
        TrackingView()
    }
}
