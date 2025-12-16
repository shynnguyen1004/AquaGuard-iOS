//
//  MapViewModel.swift
//  AquaGuard
//
//  Created by Shyn Nguyễn on 15/12/25.
//

import Foundation
import MapKit
import Combine // FIX: Import Combine
import SwiftUI

@MainActor
class MapViewModel: ObservableObject {
    @Published var zones: [FloodZone] = MockData.floodZones
    @Published var selectedZone: FloodZone?
    @Published var cameraPosition: MapCameraPosition = .region(MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 10.7769, longitude: 106.7009),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    ))
}
