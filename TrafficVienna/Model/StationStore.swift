//
//  StationStore.swift
//  TrafficVienna
//
//  Created by Ivan Dovhosheia on 08.11.25.
//

import Foundation

struct Station: Decodable, Identifiable {
    let id: String
    let diva: String
    let name: String
    let lat: Double
    let lon: Double

    enum CodingKeys: String, CodingKey {
        case id   = "HALTESTELLEN_ID"
        case diva = "DIVA"
        case name = "NAME"
        case lat  = "WGS84_LAT"
        case lon  = "WGS84_LON"
    }
}


protocol StationStoring {
    var stations: [Station] { get }
    func diva(forExact name: String) -> String?
}


final class StationStore: StationStoring {

    
    private(set) var stations: [Station] = []
    
    init() { loadStations() }
    
    private func loadStations() {
        guard let url = Bundle.main.url(
            forResource: "wienerlinien-ogd-haltestellen", withExtension: "json") else { print("Json was not found");
        return}
        
        do {
            let data = try Data(contentsOf: url)
            stations = try JSONDecoder().decode([Station].self, from: data)
            print("loaded stations: \(stations.count)")
        } catch {
            print("decode error:", error)
        }
    }
    
    
    func diva(forExact name: String) -> String? {
        let q = normalize(name)
        
        return stations.first { normalize($0.name) == q }?.diva
    }
    
    private func normalize(_ s: String) -> String {
        s.folding(options: .diacriticInsensitive, locale: .current)
         .replacingOccurrences(of: "ß", with: "ss")
         .lowercased()
         .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
