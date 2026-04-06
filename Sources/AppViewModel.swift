import SwiftUI

@MainActor
class AppViewModel: ObservableObject {
    @AppStorage("mirakurunUrl") var mirakurunURL: String = "http://mirakurun:40772"
    // Persist last selected Service ID
    @AppStorage("lastServiceId") var lastServiceID: Int = 0
    @AppStorage("volume") var volume: Double = 1.0
    @Published var selectedService: Service? {
        didSet {
            onServiceChanged(service: selectedService)
        }
    }

    @Published var services: [Service] = []
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
            await fetchServices()
            if let service = services.first(where: { $0.id == lastServiceID }) {
                selectedService = service
            } else if services.count > 0 {
                selectedService = services.first
            }
        }
    }

    private func fetchServices() async {
        guard let mirakurun = mirakurun else { return }

        do {
            statusMessage = "fetching services..."
            services = try await mirakurun.fetchServices()
            statusMessage = "service fetch OK"

        } catch {
            if let urlError = error as? URLError {
                statusMessage = "failed to fetch services: \(urlError.localizedDescription)"
            } else {
                statusMessage = "failed to fetch services: \(error)"
            }
        }
    }

    private func onServiceChanged(service: Service?) {
        guard let service = service else {
            stopUpdateTimer()
            return
        }

        lastServiceID = service.id
        statusMessage = ""
        Task {
            await updateNowOnAirProgram()
            await setupUpdateTimer()
        }
    }

    func getSelectedChannelStreamURL() -> URL? {
        guard let mirakurun = mirakurun, let selectedService = selectedService else { return nil }
        // Deprecated method name retained for compatibility with the view.
        return mirakurun.getStreamURL(service: selectedService)
    }

    func updateNowOnAirProgram() async {
        guard let mirakurun = mirakurun, let selectedService = selectedService else { return }

        do {
            currentPrograms = try await mirakurun.fetchPrograms(service: selectedService)
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
