//
//  NetworkManager.swift
//  TrafficVienna
//
//  Created by Ivan Dovhosheia on 07.11.25.
//

import Foundation

protocol NetworkManaging {
    func fetchMonitorData(for stopId: Int) async throws -> MonitorResponse
    func fetchMonitorData(diva: Int, includeArea: Bool) async throws -> MonitorResponse

}
final class NetworkManager: NetworkManaging {

    //for Rbl/StopID (to find one station with one direction)
    func fetchMonitorData(for stopId: Int) async throws -> MonitorResponse {
        let urlString = "https://www.wienerlinien.at/ogd_realtime/monitor?stopId=\(stopId)"
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        let decoded = try JSONDecoder().decode(MonitorResponse.self, from: data)
        return decoded
    }
    
    //for Diva (to show all directions at one station)
    func fetchMonitorData(diva: Int, includeArea: Bool) async throws -> MonitorResponse {
        var urlString = "https://www.wienerlinien.at/ogd_realtime/monitor?diva=\(diva)"
        if includeArea { urlString += "&aArea=1" }
        guard let url = URL(string: urlString) else { throw URLError(.badURL) }
        
        let (data, responce) = try await URLSession.shared.data(from: url)
        guard let http = responce as? HTTPURLResponse, http.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        return try JSONDecoder().decode(MonitorResponse.self, from: data)
    }
}

