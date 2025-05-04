import Foundation
import Combine
import CoreLocation

class RestaurantViewModel: ObservableObject {
    // Published properties
    @Published var restaurants: [HotPepperRestaurant] = []
    @Published var selectedRestaurant: HotPepperRestaurant?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var searchRadius: Double = 1000 // 기본값 1000m
    @Published var showMapView = false // 지도 보기/목록 보기 토글
    
    // Search range options with actual meter values
    let rangeOptions = [
        (label: "300m", value: 300),
        (label: "500m", value: 500),
        (label: "1000m", value: 1000),
        (label: "2000m", value: 2000),
        (label: "3000m", value: 3000)
    ]
    
    // API range values mapping
    private func getAPIRangeValue(forMeters meters: Double) -> Int {
        switch meters {
        case ...300: return 1
        case ...500: return 2
        case ...1000: return 3
        case ...2000: return 4
        default: return 5
        }
    }
    
    // Current location
    var currentLocation: CLLocation?
    
    private var cancellables = Set<AnyCancellable>()
    
    func searchRestaurants(lat: Double, lng: Double, selectedTheme: String? = nil) {
        isLoading = true
        errorMessage = nil
        
        // Get API range value from selected radius
        let rangeValue = getAPIRangeValue(forMeters: searchRadius)
        
        print("🔍 API 검색 요청: 반경 \(searchRadius)m (API 값: \(rangeValue))")
        
        // 테마가 선택된 경우, 테마별 검색 사용
        if let theme = selectedTheme {
            print("🔍 테마 검색 사용: \(theme)")
            
            // 선택된 테마로 검색 시작
            RestaurantAPI.shared.searchRestaurantsByTheme(
                theme: theme,
                lat: lat,
                lng: lng,
                range: rangeValue // 사용자가 선택한 반경 사용
            ) { [weak self] restaurants in
                guard let self = self else { return }
                
                DispatchQueue.main.async {
                    self.isLoading = false
                    print("📡 테마 API 응답 수신: \(restaurants.count)개 항목")
                    
                    if restaurants.isEmpty {
                        print("⚠️ 테마 검색 결과가 없습니다.")
                        self.restaurants = []
                        return
                    }
                    
                    // 사용자 위치 정보와 각 음식점까지의 거리 계산
                    var updatedRestaurants = restaurants
                    
                    if let userLocation = self.currentLocation {
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
                    }
                    
                    print("✅ 테마 검색 완료: \(updatedRestaurants.count)개 음식점 찾음")
                    self.restaurants = updatedRestaurants
                }
            }
            return
        }
        
        // 테마가 선택되지 않은 경우, 빈 결과 반환
        if selectedTheme == nil {
            print("⚠️ 테마가 선택되지 않아 결과 없음")
            self.isLoading = false
            self.restaurants = []
            return
        }
        
        // 테마가 없을 때 기존 검색 사용 (필요한 경우)
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
                
                print("📍 API 응답: \(restaurants.count)개 음식점 데이터 수신 (검색 반경: \(self.searchRadius)m)")
                
                // API 응답이 너무 적을 경우 (10개 미만), 1km 이상인 경우에 대해서는 강제로 모든 식당을 포함시킴
                let shouldIgnoreFiltering = self.searchRadius >= 1000 && restaurants.count < 10
                
                if shouldIgnoreFiltering {
                    print("⚠️ API 응답이 적어 필터링을 건너뜁니다. 모든 식당을 표시합니다.")
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
                
                // 선택한 검색 반경 내의 식당만 필터링
                let beforeFilterCount = updatedRestaurants.count
                
                // 결과가 너무 적거나 범위가 큰 경우 필터링 건너뜀
                if !shouldIgnoreFiltering {
                    updatedRestaurants = updatedRestaurants.filter { restaurant in
                        guard let distance = restaurant.distance else { return false }
                        return Double(distance) <= self.searchRadius
                    }
                }
                
                let afterFilterCount = updatedRestaurants.count
                
                print("🔍 필터링 결과: \(beforeFilterCount)개 중 \(afterFilterCount)개 남음 (범위: \(self.searchRadius)m)")
                
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
        
        // 검색 시작 상태 설정
        isLoading = true
        errorMessage = nil
        
        print("📍 현재 위치로 검색 시작: \(location.coordinate.latitude), \(location.coordinate.longitude)")
        searchRestaurants(lat: location.coordinate.latitude, lng: location.coordinate.longitude)
    }
    
    func selectRestaurant(_ restaurant: HotPepperRestaurant) {
        selectedRestaurant = restaurant
    }
    
    // 지도/목록 보기 토글
    func toggleMapView() {
        showMapView.toggle()
    }
} 