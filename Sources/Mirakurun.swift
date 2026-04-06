import Foundation

struct Version: Codable, Sendable {
    let current: String
    let latest: String
}

// NOTE: Channel model kept for backward compatibility.
struct Channel: Codable, Sendable, Identifiable, Hashable {
    // Use `channel` as legacy identifier when channels API is used.
    var id: String { self.channel }
    let type: String
    let channel: String
    let name: String
    let services: [Service]
}

struct Service: Codable, Sendable, Identifiable, Hashable {
    let id: Int
    let serviceId: Int
    let name: String
}

struct Program: Codable, Sendable, Identifiable, Hashable {
    let id: Int
    let name: String
    let serviceId: Int
    let startAt: Int64
    let duration: Int64

    var startedAt: Date {
        Date(timeIntervalSince1970: TimeInterval(self.startAt) / 1000)
    }

    var endedAt: Date {
        Date(timeIntervalSince1970: TimeInterval(self.startAt + self.duration) / 1000)
    }

    func isOnAir(now: Date) -> Bool {
        return now >= self.startedAt && now < self.endedAt
    }
}

final class Mirakurun: Sendable {
    private let baseURL: String
    init(baseURL: String) {
        self.baseURL = baseURL
    }

    func fetchVersion() async throws -> Version {
        let url = URL(string: "\(self.baseURL)/api/version")!
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode(Version.self, from: data)
    }

    func fetchChannels() async throws -> [Channel] {
        let url = URL(string: "\(self.baseURL)/api/channels")!
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode([Channel].self, from: data)
    }

    // Fetch list of services from Mirakurun `/api/services`.
    func fetchServices() async throws -> [Service] {
        let url = URL(string: "\(self.baseURL)/api/services")!
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode([Service].self, from: data)
    }

    // Fetch programs by Service.
    func fetchPrograms(service: Service) async throws -> [Program] {
        let url = URL(string: "\(self.baseURL)/api/services/\(service.id)/programs")!
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode([Program].self, from: data)
    }

    // Build stream URL by Service.
    func getStreamURL(service: Service) -> URL {
        URL(string: "\(self.baseURL)/api/services/\(service.id)/stream")!
    }

    func fetchNowOnAirProgram(service: Service) async throws -> Program? {
        try await self.fetchPrograms(service: service).first(where: { $0.isOnAir(now: Date.now) })
    }
}
