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
    
    init() { }
    
    private func loadStations() {

    }
    
    
    func diva(forExact name: String) -> String? {
        <#code#>
    }
}
