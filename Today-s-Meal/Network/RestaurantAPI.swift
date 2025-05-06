import Foundation
import Combine
import CoreLocation

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
    private let baseURL = "https://webservice.recruit.co.jp/hotpepper/gourmet/v1"
    
    // 테마와 장르 코드 매핑 테이블
    private let themeToGenreCode: [String: String] = [
        "izakaya": "G001",                // 居酒屋
        "ダイニングバー・バル": "G002",        // ダイニングバー・バル
        "創作料理": "G003",                 // 創作料理
        "和食": "G004",                    // 和食
        "洋食": "G005",                    // 洋食
        "イタリアン・フレンチ": "G006",        // イタリアン・フレンチ
        "中華": "G007",                    // 中華
        "焼肉・ホルモン": "G008",           // 焼肉・ホルモン
        "韓国料理": "G017",                // 韓国料理
        "アジア・エスニック料理": "G009",     // アジア・エスニック料理
        "各国料理": "G010",                // 各国料理
        "カラオケ・パーティ": "G011",        // カラオケ・パーティ
        "バー・カクテル": "G012",           // バー・カクテル
        "ラーメン": "G013",                // ラーメン
        "お好み焼き・もんじゃ": "G016",      // お好み焼き・もんじゃ
        "カフェ・スイーツ": "G014",         // カフェ・スイーツ
        "その他グルメ": "G015"             // その他グルメ
    ]
    
    private init() {}
    
    // 실제 일본 지역에서만 동작하는 핫페퍼 API
    func searchRestaurants(lat: Double, lng: Double, range: Int, start: Int = 1, count: Int = 20) -> AnyPublisher<[HotPepperRestaurant], APIError> {
        let actualRangeMeters = getMetersFromRange(range)
        print("🔍 핫페퍼 API로 실제 식당 데이터 검색 중: 위도 \(lat), 경도 \(lng), 범위값 \(range) (약 \(actualRangeMeters)m)")
        
        // 모든 범위에서 최대 개수(100개)의 가게를 가져옵니다
        // HotPepper API는 한 번에 최대 100개까지만 응답을 반환합니다
        let maxCount = 100
        
        var components = URLComponents(string: baseURL)
        
        components?.queryItems = [
            URLQueryItem(name: "key", value: hotPepperApiKey),
            URLQueryItem(name: "lat", value: String(lat)),
            URLQueryItem(name: "lng", value: String(lng)),
            URLQueryItem(name: "range", value: String(range)),
            URLQueryItem(name: "start", value: String(start)),
            URLQueryItem(name: "count", value: String(maxCount)), // 항상 최대 개수 요청
            URLQueryItem(name: "format", value: "json")
        ]
        
        guard let url = components?.url else {
            #if DEBUG
            print("❌ API 오류: 잘못된 URL 생성")
            #endif
            return Fail(error: APIError.invalidURL).eraseToAnyPublisher()
        }
        
        #if DEBUG
        print("📡 API 요청 URL: \(url.absoluteString)")
        #endif
        
        return URLSession.shared.dataTaskPublisher(for: url)
            .map { data, response -> Data in
                #if DEBUG
                if let httpResponse = response as? HTTPURLResponse {
                    print("📡 API 응답 상태 코드: \(httpResponse.statusCode)")
                }
                
                // 데이터 확인 (디버깅용)
                if let jsonString = String(data: data, encoding: .utf8) {
                    let previewLength = min(1000, jsonString.count)
                    let preview = String(jsonString.prefix(previewLength))
                    print("📡 API 응답 데이터 미리보기: \(preview)\(jsonString.count > previewLength ? "..." : "")")
                    
                    // 전체 데이터 디버그 로그 파일에 저장 (옵션)
                    if let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                        let logFileURL = documentsDirectory.appendingPathComponent("api_response.json")
                        try? jsonString.write(to: logFileURL, atomically: true, encoding: .utf8)
                        print("📝 API 응답 전체 로그 저장됨: \(logFileURL.path)")
                    }
                } else {
                    print("❌ API 응답 데이터를 문자열로 변환할 수 없음")
                }
                #endif
                return data
            }
            .mapError { error -> APIError in
                #if DEBUG
                print("❌ API 네트워크 오류: \(error.localizedDescription)")
                #endif
                return APIError.networkError(error)
            }
            .flatMap { data -> AnyPublisher<HotPepperResponse, APIError> in
                // JSONDecoder 설정
                let decoder = JSONDecoder()
                
                // 디코딩 중 문제 발생 시 더 자세한 정보 제공
                do {
                    // 직접 디코딩 시도
                    let response = try decoder.decode(HotPepperResponse.self, from: data)
                    return Just(response)
                        .setFailureType(to: APIError.self)
                        .eraseToAnyPublisher()
                } catch {
                    #if DEBUG
                    // 디코딩 오류에 대한 자세한 정보 출력
                    print("❌ API 디코딩 오류: \(error)")
                    
                    // 에러 상세 정보 출력
                    if let decodingError = error as? DecodingError {
                        switch decodingError {
                        case .dataCorrupted(let context):
                            print("데이터 손상: \(context.debugDescription)")
                        case .keyNotFound(let key, let context):
                            print("키를 찾을 수 없음: \(key.stringValue) \(context.debugDescription)")
                        case .typeMismatch(let type, let context):
                            print("타입 불일치: \(type) \(context.debugDescription)")
                        case .valueNotFound(let type, let context):
                            print("값을 찾을 수 없음: \(type) \(context.debugDescription)")
                        @unknown default:
                            print("알 수 없는 디코딩 오류: \(decodingError)")
                        }
                    }
                    #endif
                    
                    // 디코딩 실패 시 빈 결과 반환 (대체 방안)
                    if let emptyResponseJson = """
                    {"results":{"api_version":"1.0","results_available":0,"results_returned":"0","results_start":1,"shop":[]}}
                    """.data(using: .utf8),
                       let emptyResponse = try? decoder.decode(HotPepperResponse.self, from: emptyResponseJson) {
                        #if DEBUG
                        print("⚠️ 디코딩 실패로 빈 결과 반환")
                        #endif
                        return Just(emptyResponse)
                            .setFailureType(to: APIError.self)
                            .eraseToAnyPublisher()
                    }
                    
                    return Fail(error: APIError.decodingError(error)).eraseToAnyPublisher()
                }
            }
            .map { response -> [HotPepperRestaurant] in
                #if DEBUG
                print("📡 API 응답 정보: 총 \(response.results.resultsAvailable)개, 반환된 결과 \(response.results.resultsReturned)")
                print("📍 API 응답: \(response.results.shop.count)개 음식점 데이터 수신 (검색 반경: \(actualRangeMeters)m)")
                print("🔍 필터링 결과: \(response.results.shop.count)개 중 \(response.results.shop.count)개 남음 (범위: \(actualRangeMeters)m)")
                #endif
                return response.results.shop
            }
            .eraseToAnyPublisher()
    }
    
    // API range 값에서 실제 미터 단위 반환
    private func getMetersFromRange(_ range: Int) -> Double {
        switch range {
        case 1: return 300.0
        case 2: return 500.0
        case 3: return 1000.0
        case 4: return 2000.0
        default: return 3000.0
        }
    }
    
    // 테마별 음식점 검색 (페이지네이션 지원)
    func searchRestaurantsByTheme(
        theme: String,
        lat: Double,
        lng: Double,
        range: Int,
        completion: @escaping ([HotPepperRestaurant]) -> Void
    ) {
        let actualRangeMeters = getMetersFromRange(range)
        print("🔍 테마별 음식점 검색 시작: 테마 \(theme), 위도 \(lat), 경도 \(lng), 범위값 \(range) (약 \(actualRangeMeters)m)")
        
        // 모든 페이지의 결과를 담을 배열
        var allRestaurants: [HotPepperRestaurant] = []
        
        // 재귀적으로 모든 페이지 로드
        func loadPage(start: Int) {
            var components = URLComponents(string: baseURL)
            
            // 기본 쿼리 파라미터 설정
            components?.queryItems = [
                URLQueryItem(name: "key", value: hotPepperApiKey),
                URLQueryItem(name: "lat", value: String(lat)),
                URLQueryItem(name: "lng", value: String(lng)),
                URLQueryItem(name: "range", value: String(range)),
                URLQueryItem(name: "start", value: String(start)),
                URLQueryItem(name: "count", value: "100"), // 최대 100개씩 요청
                URLQueryItem(name: "format", value: "json")
            ]
            
            // 테마를 장르 코드로 변환하여 사용
            if let genreCode = themeToGenreCode[theme] {
                components?.queryItems?.append(URLQueryItem(name: "genre", value: genreCode))
                print("🔍 장르 코드로 검색: \(theme) -> \(genreCode)")
            } else {
                // 매핑된 장르 코드가 없으면 키워드로 검색
                components?.queryItems?.append(URLQueryItem(name: "keyword", value: theme))
                print("⚠️ 장르 코드 미매핑: 키워드로 검색 '\(theme)'")
            }
            
            guard let url = components?.url else {
                print("❌ API 오류: 잘못된 URL 생성")
                completion([])
                return
            }
            
            print("📡 테마 API 요청 URL: \(url.absoluteString)")
            
            URLSession.shared.dataTask(with: url) { data, response, error in
                if let error = error {
                    print("❌ API 네트워크 오류: \(error.localizedDescription)")
                    completion(allRestaurants) // 에러 발생해도 지금까지 로드된 결과 반환
                    return
                }
                
                guard let data = data else {
                    print("❌ API 응답 데이터 없음")
                    completion(allRestaurants)
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    print("📡 테마 API 응답 상태 코드: \(httpResponse.statusCode)")
                }
                
                // 디버깅용 데이터 출력
                if let jsonString = String(data: data, encoding: .utf8) {
                    let previewLength = min(500, jsonString.count)
                    let preview = String(jsonString.prefix(previewLength))
                    print("📡 테마 API 응답 미리보기: \(preview)\(jsonString.count > previewLength ? "..." : "")")
                }
                
                do {
                    let decoder = JSONDecoder()
                    let response = try decoder.decode(HotPepperResponse.self, from: data)
                    
                    // 현재 페이지 결과 추가
                    allRestaurants.append(contentsOf: response.results.shop)
                    
                    // 로그 출력
                    print("📡 테마 API 응답 정보: 총 \(response.results.resultsAvailable)개, 반환된 결과 \(response.results.resultsReturned), 현재까지 로드: \(allRestaurants.count)개")
                    
                    // 더 많은 결과가 있고, 현재 페이지가 데이터를 반환했으면 다음 페이지 로드
                    let resultsReturned = Int(response.results.resultsReturned) ?? 0
                    let resultsAvailable = response.results.resultsAvailable
                    let nextStart = start + resultsReturned
                    
                    if resultsReturned > 0 && nextStart <= resultsAvailable && allRestaurants.count < resultsAvailable {
                        print("📄 다음 페이지 로드 중: \(nextStart)/\(resultsAvailable)")
                        loadPage(start: nextStart)
                    } else {
                        // 모든 페이지 로드 완료
                        print("✅ 테마 \(theme) 검색 완료: 총 \(allRestaurants.count)개 음식점 찾음 (총 가능: \(resultsAvailable)개)")
                        completion(allRestaurants)
                    }
                } catch {
                    print("❌ 테마 API 디코딩 오류: \(error)")
                    completion(allRestaurants) // 에러 발생해도 지금까지 로드된 결과 반환
                }
            }.resume()
        }
        
        // 첫 페이지부터 로드 시작
        loadPage(start: 1)
    }
    
    // 식당 ID로 상세 정보 조회
    func getRestaurantDetail(
        id: String,
        completion: @escaping (HotPepperRestaurant?) -> Void
    ) {
        print("🔍 식당 ID로 상세 정보 조회: \(id)")
        
        var components = URLComponents(string: baseURL)
        
        // 식당 ID로 검색
        components?.queryItems = [
            URLQueryItem(name: "key", value: hotPepperApiKey),
            URLQueryItem(name: "id", value: id),
            URLQueryItem(name: "format", value: "json")
        ]
        
        guard let url = components?.url else {
            print("❌ API 오류: 잘못된 URL 생성")
            completion(nil)
            return
        }
        
        print("📡 상세 정보 API 요청 URL: \(url.absoluteString)")
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("❌ API 네트워크 오류: \(error.localizedDescription)")
                completion(nil)
                return
            }
            
            guard let data = data else {
                print("❌ API 응답 데이터 없음")
                completion(nil)
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("📡 상세 정보 API 응답 상태 코드: \(httpResponse.statusCode)")
            }
            
            do {
                let decoder = JSONDecoder()
                let response = try decoder.decode(HotPepperResponse.self, from: data)
                
                if response.results.shop.isEmpty {
                    print("⚠️ 식당 ID에 해당하는 정보가 없음: \(id)")
                    completion(nil)
                } else {
                    let restaurant = response.results.shop[0]
                    print("✅ 식당 상세 정보 로드 완료: \(restaurant.name)")
                    completion(restaurant)
                }
            } catch {
                print("❌ 상세 정보 API 디코딩 오류: \(error)")
                completion(nil)
            }
        }.resume()
    }
} 