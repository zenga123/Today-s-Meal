import Foundation
import Combine

enum APIError: Error {
    case invalidURL
    case invalidResponse
    case networkError(Error)
    case decodingError(Error)
    
    var description: String {
        switch self {
        case .invalidURL:
            return "잘못된 URL"
        case .invalidResponse:
            return "잘못된 응답"
        case .networkError(let error):
            return "네트워크 오류: \(error.localizedDescription)"
        case .decodingError(let error):
            return "데이터 변환 오류: \(error.localizedDescription)"
        }
    }
}

class RestaurantAPI {
    static let shared = RestaurantAPI()
    private let apiKey = "de225a444baab66f"
    private let baseURL = "https://webservice.recruit.co.jp/hotpepper/gourmet/v1"
    
    private init() {}
    
    func searchRestaurants(lat: Double, lng: Double, range: Int, start: Int = 1, count: Int = 20) -> AnyPublisher<[Restaurant], APIError> {
        var components = URLComponents(string: baseURL)
        
        components?.queryItems = [
            URLQueryItem(name: "key", value: apiKey),
            URLQueryItem(name: "lat", value: String(lat)),
            URLQueryItem(name: "lng", value: String(lng)),
            URLQueryItem(name: "range", value: String(range)),
            URLQueryItem(name: "start", value: String(start)),
            URLQueryItem(name: "count", value: String(count)),
            URLQueryItem(name: "format", value: "json")
        ]
        
        guard let url = components?.url else {
            return Fail(error: APIError.invalidURL).eraseToAnyPublisher()
        }
        
        return URLSession.shared.dataTaskPublisher(for: url)
            .map { $0.data }
            .mapError { APIError.networkError($0) }
            .flatMap { data -> AnyPublisher<HotPepperResponse, APIError> in
                let decoder = JSONDecoder()
                return Just(data)
                    .decode(type: HotPepperResponse.self, decoder: decoder)
                    .mapError { APIError.decodingError($0) }
                    .eraseToAnyPublisher()
            }
            .map { $0.results.shop }
            .eraseToAnyPublisher()
    }
} 