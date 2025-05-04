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
    private let apiKey = "de225a444baab66f"
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
    func searchRestaurantsJapan(lat: Double, lng: Double, range: Int, start: Int = 1, count: Int = 20) -> AnyPublisher<[HotPepperRestaurant], APIError> {
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
            print("❌ API 오류: 잘못된 URL 생성")
            return Fail(error: APIError.invalidURL).eraseToAnyPublisher()
        }
        
        print("📡 API 요청 URL: \(url.absoluteString)")
        
        return URLSession.shared.dataTaskPublisher(for: url)
            .map { data, response -> Data in
                if let httpResponse = response as? HTTPURLResponse {
                    print("📡 API 응답 상태 코드: \(httpResponse.statusCode)")
                }
                
                // 데이터 확인 (디버깅용)
                if let jsonString = String(data: data, encoding: .utf8) {
                    let previewLength = min(500, jsonString.count)
                    let preview = String(jsonString.prefix(previewLength))
                    print("📡 API 응답 데이터 미리보기: \(preview)\(jsonString.count > previewLength ? "..." : "")")
                } else {
                    print("❌ API 응답 데이터를 문자열로 변환할 수 없음")
                }
                
                return data
            }
            .mapError { error -> APIError in
                print("❌ API 네트워크 오류: \(error.localizedDescription)")
                return APIError.networkError(error)
            }
            .flatMap { data -> AnyPublisher<HotPepperResponse, APIError> in
                let decoder = JSONDecoder()
                return Just(data)
                    .decode(type: HotPepperResponse.self, decoder: decoder)
                    .mapError { error -> APIError in
                        print("❌ API 디코딩 오류: \(error.localizedDescription)")
                        return APIError.decodingError(error)
                    }
                    .eraseToAnyPublisher()
            }
            .map { response -> [HotPepperRestaurant] in
                print("📡 API 응답 정보: 총 \(response.results.resultsAvailable)개, 반환된 결과 \(response.results.resultsReturned)")
                return response.results.shop
            }
            .eraseToAnyPublisher()
    }
    
    // 현재 위치 기반 가상 식당 데이터 생성 (실제 API 호출 없음)
    func generateMockRestaurants(lat: Double, lng: Double, range: Int, start: Int = 1, count: Int = 20) -> AnyPublisher<[HotPepperRestaurant], APIError> {
        print("🔍 현재 위치 주변 가상 식당 데이터 생성 중: 위도 \(lat), 경도 \(lng), 범위 \(range)m")
        
        // 반경에 따라 식당 수 조정 (범위가 넓을수록 더 많은 식당)
        let restaurantCount: Int
        switch range {
        case 1: restaurantCount = min(count, 20)  // 300m
        case 2: restaurantCount = min(count, 30) // 500m
        case 3: restaurantCount = min(count, 50) // 1km
        case 4: restaurantCount = min(count, 70) // 2km
        default: restaurantCount = min(count, 100) // 3km 이상
        }
        
        // 지정된 범위(미터) 내에서 무작위로 좌표 생성
        let rangeInMeters = getMetersFromRange(range)
        let restaurants = generateRandomRestaurants(
            baseLatitude: lat,
            baseLongitude: lng,
            rangeInMeters: rangeInMeters,
            count: restaurantCount
        )
        
        print("✅ \(restaurants.count)개의 가상 식당 데이터 생성 완료")
        
        // 비동기로 데이터를 약간 지연시켜 반환 (네트워크 호출 느낌 주기)
        return Just(restaurants)
            .delay(for: .seconds(1), scheduler: DispatchQueue.global())
            .setFailureType(to: APIError.self)
            .eraseToAnyPublisher()
    }
    
    // 실제 일본 지역에서만 동작하는 핫페퍼 API
    func searchRestaurants(lat: Double, lng: Double, range: Int, start: Int = 1, count: Int = 20) -> AnyPublisher<[HotPepperRestaurant], APIError> {
        let actualRangeMeters = getMetersFromRange(range)
        print("🔍 핫페퍼 API로 실제 식당 데이터 검색 중: 위도 \(lat), 경도 \(lng), 범위값 \(range) (약 \(actualRangeMeters)m)")
        
        // 모든 범위에서 최대 개수(100개)의 가게를 가져옵니다
        // HotPepper API는 한 번에 최대 100개까지만 응답을 반환합니다
        let maxCount = 100
        
        var components = URLComponents(string: baseURL)
        
        components?.queryItems = [
            URLQueryItem(name: "key", value: apiKey),
            URLQueryItem(name: "lat", value: String(lat)),
            URLQueryItem(name: "lng", value: String(lng)),
            URLQueryItem(name: "range", value: String(range)),
            URLQueryItem(name: "start", value: String(start)),
            URLQueryItem(name: "count", value: String(maxCount)), // 항상 최대 개수 요청
            URLQueryItem(name: "format", value: "json")
        ]
        
        guard let url = components?.url else {
            print("❌ API 오류: 잘못된 URL 생성")
            return Fail(error: APIError.invalidURL).eraseToAnyPublisher()
        }
        
        print("📡 API 요청 URL: \(url.absoluteString)")
        
        return URLSession.shared.dataTaskPublisher(for: url)
            .map { data, response -> Data in
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
                
                return data
            }
            .mapError { error -> APIError in
                print("❌ API 네트워크 오류: \(error.localizedDescription)")
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
                    
                    // 디코딩 실패 시 빈 결과 반환 (대체 방안)
                    if let emptyResponseJson = """
                    {"results":{"api_version":"1.0","results_available":0,"results_returned":"0","results_start":1,"shop":[]}}
                    """.data(using: .utf8),
                       let emptyResponse = try? decoder.decode(HotPepperResponse.self, from: emptyResponseJson) {
                        print("⚠️ 디코딩 실패로 빈 결과 반환")
                        return Just(emptyResponse)
                            .setFailureType(to: APIError.self)
                            .eraseToAnyPublisher()
                    }
                    
                    return Fail(error: APIError.decodingError(error)).eraseToAnyPublisher()
                }
            }
            .map { response -> [HotPepperRestaurant] in
                print("📡 API 응답 정보: 총 \(response.results.resultsAvailable)개, 반환된 결과 \(response.results.resultsReturned)")
                print("📍 API 응답: \(response.results.shop.count)개 음식점 데이터 수신 (검색 반경: \(actualRangeMeters)m)")
                print("🔍 필터링 결과: \(response.results.shop.count)개 중 \(response.results.shop.count)개 남음 (범위: \(actualRangeMeters)m)")
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
    
    // 랜덤 식당 생성
    private func generateRandomRestaurants(baseLatitude: Double, baseLongitude: Double, rangeInMeters: Double, count: Int) -> [HotPepperRestaurant] {
        let foodCategories = ["일식", "한식", "중식", "양식", "카페", "베이커리", "분식", "치킨", "피자", "패스트푸드"]
        let restaurantNamePrefixes = ["맛있는", "행복한", "즐거운", "신선한", "정성가득", "고소한", "달콤한", "향긋한", "편안한", "특별한"]
        let restaurantNameSuffixes = ["식당", "레스토랑", "주방", "가게", "다이닝", "키친", "하우스", "홀", "밥집", "포차"]
        
        var restaurants: [HotPepperRestaurant] = []
        
        for i in 0..<count {
            // 1. 랜덤 좌표 생성 (기준 좌표에서 지정된 범위 내)
            let randomCoordinate = generateRandomCoordinate(
                baseLatitude: baseLatitude,
                baseLongitude: baseLongitude,
                rangeInMeters: rangeInMeters
            )
            
            // 2. 랜덤 카테고리 선택
            let randomCategory = foodCategories.randomElement() ?? "일식"
            
            // 3. 랜덤 이름 생성
            let namePrefix = restaurantNamePrefixes.randomElement() ?? "맛있는"
            let nameSuffix = restaurantNameSuffixes.randomElement() ?? "식당"
            let restaurantName = "\(namePrefix) \(randomCategory) \(nameSuffix)"
            
            // 4. 식당 데이터 생성
            let restaurant = createMockRestaurant(
                id: "mock_\(i)",
                name: restaurantName,
                category: randomCategory,
                latitude: randomCoordinate.latitude,
                longitude: randomCoordinate.longitude
            )
            
            restaurants.append(restaurant)
        }
        
        return restaurants
    }
    
    // 주어진 기준 좌표에서 지정된 범위(미터) 내 랜덤 좌표 생성
    private func generateRandomCoordinate(baseLatitude: Double, baseLongitude: Double, rangeInMeters: Double) -> CLLocationCoordinate2D {
        // 1도의 위도/경도당 거리 (미터)
        let metersPerLatitude = 111320.0 // 적도 기준 1도의 위도 거리(m)
        
        // 경도의 경우 위도에 따라 거리가 달라짐 (위도가 높을수록 같은 경도 차이의 거리는 짧아짐)
        let metersPerLongitude = 111320.0 * cos(baseLatitude * Double.pi / 180.0)
        
        // 위도/경도의 최대 변화량 (범위 내에서)
        let latitudeDelta = rangeInMeters / metersPerLatitude
        let longitudeDelta = rangeInMeters / metersPerLongitude
        
        // 랜덤 변화량 생성 (-maxDelta ~ +maxDelta)
        let randomLatOffset = Double.random(in: -latitudeDelta...latitudeDelta)
        let randomLngOffset = Double.random(in: -longitudeDelta...longitudeDelta)
        
        // 원점으로부터의 거리가 반경 내에 있는지 확인하고, 필요하면 조정
        let newLatitude = baseLatitude + randomLatOffset
        let newLongitude = baseLongitude + randomLngOffset
        
        return CLLocationCoordinate2D(latitude: newLatitude, longitude: newLongitude)
    }
    
    // 가상 식당 데이터 생성
    private func createMockRestaurant(id: String, name: String, category: String, latitude: Double, longitude: Double) -> HotPepperRestaurant {
        // 카테고리에 따른 이미지 선택
        let logoImage: String
        switch category {
        case "일식": logoImage = "https://example.com/japanese.jpg"
        case "한식": logoImage = "https://example.com/korean.jpg"
        case "중식": logoImage = "https://example.com/chinese.jpg"
        case "양식": logoImage = "https://example.com/western.jpg"
        default: logoImage = "https://example.com/restaurant.jpg"
        }
        
        // 카테고리에 따른 캐치프레이즈 생성
        let catchPhrase: String
        switch category {
        case "일식": catchPhrase = "신선한 사시미와 정통 일식"
        case "한식": catchPhrase = "정성 가득한 한국 전통 요리"
        case "중식": catchPhrase = "풍미 가득한 정통 중화요리"
        case "양식": catchPhrase = "품격 있는 서양식 코스 요리"
        case "카페": catchPhrase = "여유로운 휴식과 함께하는 커피"
        case "베이커리": catchPhrase = "매일 아침 구워내는 신선한 빵"
        case "분식": catchPhrase = "추억의 맛이 담긴 분식 요리"
        case "치킨": catchPhrase = "바삭하고 육즙 가득한 치킨"
        case "피자": catchPhrase = "화덕에서 구워낸 정통 피자"
        case "패스트푸드": catchPhrase = "빠르고 맛있는 즐거운 식사"
        default: catchPhrase = "특별한 맛을 선사합니다"
        }
        
        // 예시 지역 데이터
        let area = Area(code: "mock_area", name: "주변지역")
        
        // 장르 데이터 생성
        let genre = Genre(code: "mock_genre", name: category, catchPhrase: catchPhrase)
        
        // 예산 정보
        let budget = Budget(code: "mock_budget", name: "1만원 ~ 2만원", average: "15000")
        
        // URL 정보
        let urls = URLS(pc: "https://example.com", mobile: "https://m.example.com")
        
        // 사진 정보
        let pc = PC(l: "https://example.com/large.jpg", m: "https://example.com/medium.jpg", s: "https://example.com/small.jpg")
        let mobile = Mobile(l: "https://example.com/mobile_large.jpg", s: "https://example.com/mobile_small.jpg")
        let photo = Photo(pc: pc, mobile: mobile)
        
        // 식당 객체 생성
        return HotPepperRestaurant(
            id: id,
            name: name,
            logoImage: logoImage,
            nameKana: name,
            address: "서울시 어딘가",
            stationName: "가까운역",
            ktaiCoupon: 0,
            largeServiceArea: area,
            serviceArea: area,
            largeArea: area,
            middleArea: area,
            smallArea: area,
            lat: latitude,
            lng: longitude,
            genre: genre,
            subGenre: genre,
            budget: budget,
            budgetMemo: "1인당 평균 1만원~2만원",
            catchPhrase: catchPhrase,
            capacity: Int.random(in: 20...100),
            access: "가까운역에서 도보 5분",
            mobileAccess: "가까운역에서 도보 5분",
            urls: urls,
            photo: photo,
            open: "11:00",
            close: "22:00",
            wifi: "있음",
            wedding: "가능",
            course: "있음",
            freeDrink: "있음",
            freeFood: "없음",
            privateRoom: "있음",
            horigotatsu: "없음",
            tatami: "없음",
            card: "가능",
            nonSmoking: "전석 금연",
            charter: "가능",
            parking: "있음",
            barrierFree: "있음",
            otherMemo: "",
            sommelier: "없음",
            openAir: "없음",
            show: "없음",
            karaoke: "없음",
            band: "없음",
            tv: "있음",
            english: "가능",
            pet: "불가",
            child: "환영"
        )
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
                URLQueryItem(name: "key", value: apiKey),
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
} 