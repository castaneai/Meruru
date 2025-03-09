import SwiftUI
import VLCKit

@main
struct MyApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    @StateObject private var viewModel = AppViewModel()
    @Environment(\.openSettings) private var openSettings

    var body: some Scene {
        WindowGroup {
            AppView(viewModel: viewModel)
                .task { onAppStart() }
                .navigationTitle(windowTitle())
        }
        Settings {
            SettingsView(viewModel: viewModel)
        }
    }

    private func windowTitle() -> String {
        if let onAir = viewModel.nowOnAirProgramTitle {
            return "\(onAir) | Meruru"
        }
        return "Meruru"
    }

    private func onAppStart() {
        if viewModel.mirakurunURL == "" {
            openSettings()
        } else {
            viewModel.initMirakurun()
        }
    }
}

struct AppView: View {
    @ObservedObject var viewModel: AppViewModel

    var body: some View {
        VStack {
            VLCPlayerView(mediaURL: viewModel.getSelectedChannelStreamURL())
                .background(Color.black)
            HStack {
                Picker("channel", selection: $viewModel.selectedChannel) {
                    ForEach(viewModel.channels) { item in
                        Text(item.name).tag(item as Channel?)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                SettingsLink {
                    Label("Settings", systemImage: "gear")
                }
                Button("Connect") {
                    viewModel.initMirakurun()
                }
            }.padding(.horizontal, 10).padding(.vertical, 6)
            Text(viewModel.statusMessage ?? "")
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 10).padding(.vertical, 6)
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApplication.shared.setActivationPolicy(.regular)
        NSApplication.shared.activate(ignoringOtherApps: true)
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}
