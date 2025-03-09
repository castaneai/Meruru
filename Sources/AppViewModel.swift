import SwiftUI

@MainActor
class AppViewModel: ObservableObject {
    @AppStorage("mirakurunUrl") var mirakurunURL: String = "http://mirakurun:40772"
    @AppStorage("lastChannelId") var lastChannelID: String = ""
    @Published var selectedChannel: Channel? {
        didSet {
            onChannelChanged(channel: selectedChannel)
        }
    }

    @Published var channels: [Channel] = []
    @Published var nowOnAirProgram: String?
    @Published var statusMessage: String?

    private var mirakurun: Mirakurun?

    func initMirakurun() {
        if mirakurunURL == "" {
            statusMessage = "mirakurun URL is missing"
            return
        }
        mirakurun = Mirakurun(baseURL: mirakurunURL)
        Task {
            await fetchChannels()
            if let channel = channels.first(where: { $0.id == lastChannelID }) {
                selectedChannel = channel
            } else if channels.count > 0 {
                selectedChannel = channels.first
            }
        }
    }

    private func fetchChannels() async {
        guard let mirakurun = mirakurun else { return }

        do {
            statusMessage = "fetching channels..."
            channels = try await mirakurun.fetchChannels()
            statusMessage = "channel fetch OK"

        } catch {
            if let urlError = error as? URLError {
                statusMessage = "failed to fetch channels: \(urlError.localizedDescription)"
            } else {
                statusMessage = "failed to fetch channels: \(error)"
            }
        }
    }

    private func onChannelChanged(channel: Channel?) {
        guard let channel = channel else { return }

        lastChannelID = channel.id
        statusMessage = ""
    }

    func getSelectedChannelStreamURL() -> URL? {
        guard let mirakurun = mirakurun, let selectedChannel = selectedChannel else { return nil }

        return mirakurun.getStreamURL(channel: selectedChannel)
    }

    func updateNowOnAirProgram() async {
        let old = nowOnAirProgram
        if let mirakurun = mirakurun, let selectedChannel = selectedChannel {
            do {
                let program = try await mirakurun.fetchNowOnAirProgram(channel: selectedChannel)
                print("program: \(String(describing: program))")
                nowOnAirProgram = program?.name
                if let newVal = nowOnAirProgram, newVal != old {
                    statusMessage = "on air: \(newVal)"
                }
            } catch {
                statusMessage = "failed to fetch now on air: \(error)"
            }
        }
    }
}
