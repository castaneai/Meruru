import SwiftUI

@MainActor
class AppViewModel: ObservableObject {
    @AppStorage("mirakurunUrl") var mirakurunURL: String = "http://mirakurun:40772"
    @AppStorage("lastChannelId") var lastChannelID: String = ""
    @AppStorage("volume") var volume: Double = 1.0
    @Published var selectedChannel: Channel? {
        didSet {
            onChannelChanged(channel: selectedChannel)
        }
    }

    @Published var channels: [Channel] = []
    @Published var nowOnAirProgramTitle: String?
    @Published var statusMessage: String?

    private var mirakurun: Mirakurun?
    private var updateTimer: Timer?
    private var currentPrograms: [Program] = []

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
        guard let channel = channel else {
            stopUpdateTimer()
            return
        }

        lastChannelID = channel.id
        statusMessage = ""
        Task {
            await updateNowOnAirProgram()
            await setupUpdateTimer()
        }
    }

    func getSelectedChannelStreamURL() -> URL? {
        guard let mirakurun = mirakurun, let selectedChannel = selectedChannel else { return nil }

        return mirakurun.getStreamURL(channel: selectedChannel)
    }

    func updateNowOnAirProgram() async {
        guard let mirakurun = mirakurun, let selectedChannel = selectedChannel else { return }

        do {
            currentPrograms = try await mirakurun.fetchPrograms(channel: selectedChannel)
            if let program = currentPrograms.first(where: { $0.isOnAir(now: Date.now) }) {
                nowOnAirProgramTitle = program.name
            }
        } catch {
            statusMessage = "failed to fetch now on air: \(error)"
        }
    }

    private func setupUpdateTimer() async {
        stopUpdateTimer()

        guard !currentPrograms.isEmpty else { return }

        let now = Date.now
        var nextUpdateTime: Date?

        for program in currentPrograms {
            if program.startedAt > now {
                if nextUpdateTime == nil || program.startedAt < nextUpdateTime! {
                    nextUpdateTime = program.startedAt
                }
            } else if program.isOnAir(now: now) {
                if nextUpdateTime == nil || program.endedAt < nextUpdateTime! {
                    nextUpdateTime = program.endedAt
                }
            }
        }

        guard let updateTime = nextUpdateTime else { return }

        let timeInterval = updateTime.timeIntervalSince(now)
        if timeInterval > 0 {
            updateTimer = Timer.scheduledTimer(withTimeInterval: timeInterval, repeats: false) { [weak self] _ in
                Task { @MainActor in
                    await self?.updateNowOnAirProgram()
                    await self?.setupUpdateTimer()
                }
            }
        }
    }

    private func stopUpdateTimer() {
        updateTimer?.invalidate()
        updateTimer = nil
    }
}
