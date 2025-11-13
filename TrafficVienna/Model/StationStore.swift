//
//  StationStore.swift
//  TrafficVienna
//
//  Created by Ivan Dovhosheia on 08.11.25.
//

import Foundation
import Combine

struct Station: Decodable, Identifiable {
    let id: Int
    let diva: Int?
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


final class StationStore: ObservableObject ,StationStoring {

    
    @Published private(set) var stations: [Station] = []
    
    init() {
        print("Init StationStore")
        loadStations() }
    
    private func loadStations() {
        print("loadStations called")
        guard let url = Bundle.main.url(
            forResource: "wienerlinien-ogd-haltestellen",
            withExtension: "json") else {
            print(" JSON file NOT FOUND in bundle")
            return
        }
        print("✅ JSON file found at: \(url)")

        do {
            let data = try Data(contentsOf: url)
            print("✅ Loaded raw data, size: \(data.count) bytes")

            let decoded = try JSONDecoder().decode([Station].self, from: data)
            print("loaded stations: \(decoded.count)")
            
            stations = decoded
        } catch {
            print("Failed to decode stations:", error)
        }
    }
    
    
    func diva(forExact name: String) -> String? {
        let q = normalize(name)
        if let exact = stations.first(where: { normalize($0.name) == q }),
           let diva = exact.diva {
            return String(diva)
        }
        return nil
    }
    
    private func normalize(_ s: String) -> String {
        s.folding(options: .diacriticInsensitive, locale: .current)
         .replacingOccurrences(of: "ß", with: "ss")
         .lowercased()
         .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
