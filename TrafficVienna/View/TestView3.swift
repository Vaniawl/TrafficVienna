//
//  TestView3.swift
//  TrafficVienna
//
//  Created by Ivan Dovhosheia on 15.11.25.
//

import SwiftUI

struct TestView3: View {
    let line: Lines

    var body: some View {
        List {
            ForEach(line.departures.departure.indices, id: \.self) { idx in
                let dep = line.departures.departure[idx]
                VStack(alignment: .leading) {
                    Text("in \(dep.departureTime.countdown) хв")
                        .font(.title3.bold())

                    Text("planned: \(dep.departureTime.timePlanned)")
                        .font(.subheadline)

                    if let real = dep.departureTime.timeReal {
                        Text("reaaaaal : \(real)")
                            .font(.subheadline)
                    }
                }
            }
        }
        .navigationTitle("\(line.name) → \(line.towards)")
    }
}

#Preview {
    TestView3(line:
        Lines(
            name: "O",
            towards: "Praterstern",
            departures: Departures(
                departure: [
                    Departure(
                        departureTime: DepartureTime(
                            countdown: 2,
                            timePlanned: "15:24",
                            timeReal: "15:25"
                        )
                    ),
                    Departure(
                        departureTime: DepartureTime(
                            countdown: 7,
                            timePlanned: "15:29",
                            timeReal: nil
                        )
                    )
                ]
            )
        )
    )
}
