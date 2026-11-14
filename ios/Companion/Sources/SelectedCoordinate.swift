import Foundation

struct SelectedCoordinate: Equatable {
    let latitude: Double
    let longitude: Double

    var isValid: Bool {
        latitude.isFinite &&
        longitude.isFinite &&
        (-90.0...90.0).contains(latitude) &&
        (-180.0...180.0).contains(longitude)
    }

    init?(latitude: Double, longitude: Double) {
        guard latitude.isFinite,
              longitude.isFinite,
              (-90.0...90.0).contains(latitude),
              (-180.0...180.0).contains(longitude) else {
            return nil
        }
        self.latitude = latitude
        self.longitude = longitude
    }
}
