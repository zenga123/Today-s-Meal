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
    @Published var showMapView = false // 지도 보기/목록 보기 토글
    
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
                guard let self = self, let userLocation = self.currentLocation else {
                    self?.restaurants = restaurants
                    return
                }
                
                // 사용자 위치 정보와 각 음식점까지의 거리 계산
                var updatedRestaurants = restaurants
                updatedRestaurants = updatedRestaurants.map { restaurant in
                    var updatedRestaurant = restaurant
                    
                    // 음식점 위치 설정
                    let restaurantLocation = CLLocation(latitude: restaurant.lat, longitude: restaurant.lng)
                    
                    // 거리 계산 (미터 단위)
                    let distanceInMeters = Int(userLocation.distance(from: restaurantLocation))
                    updatedRestaurant.distance = distanceInMeters
                    updatedRestaurant.userLocation = userLocation
                    
                    return updatedRestaurant
                }
                
                // 거리순으로 정렬
                updatedRestaurants.sort { ($0.distance ?? 0) < ($1.distance ?? 0) }
                
                self.restaurants = updatedRestaurants
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
    
    // 지도/목록 보기 토글
    func toggleMapView() {
        showMapView.toggle()
    }
} 