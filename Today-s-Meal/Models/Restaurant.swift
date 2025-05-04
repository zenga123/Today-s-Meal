import Foundation
import CoreLocation

struct Restaurant: Identifiable {
    let id: String
    let name: String
    let address: String
    let rating: Double
    let reviewCount: Int
    let category: String
    let latitude: Double
    let longitude: Double
    let imageUrl: String?
    let access: String?  // 오시는 길 정보 추가
    
    // 식당의 좌표를 CLLocationCoordinate2D로 반환
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    // 두 지점 사이의 거리 계산 (미터 단위)
    func distance(from location: CLLocation) -> CLLocationDistance {
        let restaurantLocation = CLLocation(latitude: latitude, longitude: longitude)
        return location.distance(from: restaurantLocation)
    }
}

// API 응답을 파싱하기 위한 디코더블 모델
struct RestaurantsResponse: Decodable {
    let restaurants: [RestaurantData]
    
    struct RestaurantData: Decodable {
        let id: String
        let name: String
        let address: String
        let rating: Double
        let reviewCount: Int
        let category: String
        let latitude: Double
        let longitude: Double
        let imageUrl: String?
        let access: String?  // 오시는 길 정보 추가
        
        // Restaurant 모델로 변환
        func toRestaurant() -> Restaurant {
            Restaurant(
                id: id,
                name: name,
                address: address,
                rating: rating,
                reviewCount: reviewCount,
                category: category,
                latitude: latitude,
                longitude: longitude,
                imageUrl: imageUrl,
                access: access  // 오시는 길 정보 추가
            )
        }
    }
} 