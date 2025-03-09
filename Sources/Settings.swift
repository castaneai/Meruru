import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: AppViewModel
    @State var checkConnectionStatus: String = ""
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack {
            Form {
                TextField("Mirakurun URL", text: $viewModel.mirakurunURL)
                Button("Check connection") { Task { await checkConnection() } }
                Text(checkConnectionStatus)
            }
            Spacer()
            HStack {
                Spacer()
                Button("OK") {
                    self.dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }.padding()
        }
        .navigationTitle("Meruru Settings")
        .padding()
        .frame(width: 500, height: 150)
    }

    private func checkConnection() async {
        do {
            let version = try await Mirakurun(baseURL: viewModel.mirakurunURL).fetchVersion()
            checkConnectionStatus = "OK (Version: \(version.current))"
        } catch {
            if let urlError = error as? URLError {
                checkConnectionStatus = "Fail: \(urlError.localizedDescription)"
            } else {
                checkConnectionStatus = "Fail: \(error)"
            }
        }
    }
}
