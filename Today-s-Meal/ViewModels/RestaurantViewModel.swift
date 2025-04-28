import Foundation
import Combine
import CoreLocation

class RestaurantViewModel: ObservableObject {
    // Published properties
    @Published var restaurants: [Restaurant] = []
    @Published var selectedRestaurant: Restaurant?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var searchRadius: Double = 3
    
    // Search range options (in kilometers) as defined by API
    let rangeOptions = [
        (label: "300m", value: 1),
        (label: "500m", value: 2),
        (label: "1000m", value: 3),
        (label: "2000m", value: 4),
        (label: "3000m", value: 5)
    ]
    
    // Current location
    var currentLocation: CLLocation?
    
    private var cancellables = Set<AnyCancellable>()
    
    func searchRestaurants(lat: Double, lng: Double) {
        isLoading = true
        errorMessage = nil
        
        // Get range value from selected radius
        let rangeValue = rangeOptions.first { $0.label == "\(Int(searchRadius))km" }?.value ?? 3
        
        RestaurantAPI.shared.searchRestaurants(lat: lat, lng: lng, range: rangeValue)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.errorMessage = "오류: \(error.description)"
                }
            }, receiveValue: { [weak self] restaurants in
                self?.restaurants = restaurants
            })
            .store(in: &cancellables)
    }
    
    func searchWithCurrentLocation() {
        guard let location = currentLocation else {
            errorMessage = "위치를 확인할 수 없습니다. 다시 시도해주세요."
            return
        }
        
        searchRestaurants(lat: location.coordinate.latitude, lng: location.coordinate.longitude)
    }
    
    func selectRestaurant(_ restaurant: Restaurant) {
        selectedRestaurant = restaurant
    }
} 