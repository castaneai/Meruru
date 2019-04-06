//
//  MirakurunApi.swift
//  Meruru
//
//  Created by castaneai on 2019/04/06.
//  Copyright © 2019 castaneai. All rights reserved.
//

import Foundation

public struct Service: Codable {
    let id: Int
    let serviceId: Int
    let networkId: Int
    let name: String
    let channel: Channel
}

public struct Channel: Codable {
    let type: String
    let channel: String
}

public class MirakurunAPI {
    
    init(baseURL: URL) {
        self.baseURL = baseURL
    }
    private let baseURL: URL
    private let jsonDecoder: JSONDecoder = JSONDecoder()
    
    public func getStreamURL(service: Service) -> URL {
        return self.baseURL
            .appendingPathComponent("channels")
            .appendingPathComponent(service.channel.type)
            .appendingPathComponent(service.channel.channel)
            .appendingPathComponent("services")
            .appendingPathComponent(String(service.serviceId))
            .appendingPathComponent("stream")
    }
    
    public func fetchServices(completion: @escaping (Result<[Service], Error>) -> Void) {
        let url = self.baseURL.appendingPathComponent("services")
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, let _ = response as? HTTPURLResponse else {
                debugPrint("error")
                return
            }
            do {
                let services: [Service] = try self.jsonDecoder.decode([Service].self, from: data)
                completion(.success(services))
            } catch {
                // error
            }
        }.resume()
    }

}
