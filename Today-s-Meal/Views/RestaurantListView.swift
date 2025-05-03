import SwiftUI
import CoreLocation
import Combine

struct RestaurantListView: View {
    let theme: String
    let searchRadius: Double
    @ObservedObject var locationService: LocationService
    
    @StateObject private var viewModel = RestaurantListViewModel()
    @State private var scrollOffset: CGFloat = 0
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack(spacing: 0) {
            // 헤더
            HStack {
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "arrow.left")
                        .font(.title2)
                        .foregroundColor(.white)
                }
                
                Text(theme == "izakaya" ? "居酒屋" : theme)
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.leading, 8)
                
                Spacer()
                
                Text("\(searchRadius/1000, specifier: "%.1f")km 이내")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.black.opacity(0.9))
            
            // 레스토랑 리스트
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(viewModel.restaurants) { restaurant in
                        RestaurantRow(
                            restaurant: restaurant, 
                            distance: restaurant.distance(from: CLLocation(
                                latitude: locationService.currentLocation?.coordinate.latitude ?? 0,
                                longitude: locationService.currentLocation?.coordinate.longitude ?? 0
                            ))
                        )
                        .onAppear {
                            // 마지막 항목에서 2개 앞에 도달하면 다음 페이지 로드
                            if let lastIndex = viewModel.restaurants.indices.last,
                               let currentIndex = viewModel.restaurants.firstIndex(where: { $0.id == restaurant.id }),
                               currentIndex >= lastIndex - 2 {
                                viewModel.loadMoreIfNeeded()
                            }
                        }
                    }
                    
                    if viewModel.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity, maxHeight: 50)
                            .tint(.white)
                    }
                    
                    if !viewModel.isLoading && viewModel.restaurants.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 50))
                                .foregroundColor(.gray)
                            
                            Text("검색 결과가 없습니다")
                                .font(.headline)
                                .foregroundColor(.gray)
                            
                            Text("다른 테마나 검색 반경을 변경해보세요")
                                .font(.subheadline)
                                .foregroundColor(.gray.opacity(0.8))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 100)
                    }
                    
                    // 마지막 페이지 도달 시 더 이상 결과가 없음을 표시
                    if !viewModel.isLoading && !viewModel.hasMorePages && !viewModel.restaurants.isEmpty {
                        HStack {
                            Spacer()
                            Text("모든 결과를 불러왔습니다")
                                .font(.caption)
                                .foregroundColor(.gray.opacity(0.7))
                                .padding(.vertical, 16)
                            Spacer()
                        }
                    }
                }
            }
            .background(Color.black)
        }
        .navigationBarHidden(true)
        .background(Color.black)
        .onAppear {
            if let location = locationService.currentLocation {
                viewModel.searchRestaurants(
                    theme: theme,
                    latitude: location.coordinate.latitude,
                    longitude: location.coordinate.longitude,
                    radius: searchRadius
                )
            }
        }
    }
}

class RestaurantListViewModel: ObservableObject {
    @Published var restaurants: [Today_s_Meal.Restaurant] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var hasMorePages = true
    
    private var currentPage = 1
    private var isLoadingPage = false
    private var currentTheme = ""
    private var currentLat = 0.0
    private var currentLng = 0.0
    private var currentRadius = 0.0
    private var cancellables = Set<AnyCancellable>()
    
    // 테마와 관련된 실제 API 검색 키워드 매핑
    private let themeToAPIKeyword: [String: String] = [
        "izakaya": "居酒屋",
        "ダイニングバー・バル": "ダイニングバー",
        "創作料理": "創作料理",
        "和食": "和食",
        "洋食": "洋食",
        "イタリアン・フレンチ": "イタリアン",
        "中華": "中華",
        "焼肉・ホルモン": "焼肉",
        "韓国料理": "韓国料理",
        "アジア・エスニック料理": "アジア・エスニック",
        "各国料理": "各国料理",
        "カラオケ・パーティ": "カラオケ",
        "バー・カクテル": "バー",
        "ラーメン": "ラーメン",
        "お好み焼き・もんじゃ": "お好み焼き",
        "カフェ・スイーツ": "カフェ",
        "その他グルメ": "その他"
    ]
    
    func searchRestaurants(theme: String, latitude: Double, longitude: Double, radius: Double) {
        // 새 검색 시작
        restaurants = []
        currentPage = 1
        hasMorePages = true
        currentTheme = theme
        currentLat = latitude
        currentLng = longitude
        currentRadius = radius
        isLoadingPage = false
        
        // 첫 페이지 로딩
        loadPage(page: 1)
    }
    
    func loadMoreIfNeeded() {
        guard !isLoading && !isLoadingPage && hasMorePages else { return }
        loadPage(page: currentPage + 1)
    }
    
    private func loadPage(page: Int) {
        guard !isLoading && !isLoadingPage && hasMorePages else { return }
        
        isLoading = true
        isLoadingPage = true
        errorMessage = nil
        
        print("🔄 \(currentTheme) 테마 \(page) 페이지 실제 API 검색 시작")
        
        // API 호출에 필요한 준비
        let apiRangeValue = getAPIRangeValue(forMeters: currentRadius)
        let keyword = themeToAPIKeyword[currentTheme] ?? currentTheme
        
        // 실제 API 호출 (핫페퍼 API)
        fetchRealRestaurants(
            keyword: keyword,
            lat: currentLat,
            lng: currentLng,
            range: apiRangeValue,
            start: (page - 1) * 10 + 1
        )
    }
    
    // 실제 API를 통해 음식점 데이터 가져오기
    private func fetchRealRestaurants(keyword: String, lat: Double, lng: Double, range: Int, start: Int) {
        print("🔍 실제 API 호출 시작: \(keyword), 위치(\(lat), \(lng)), 범위: \(range), 시작: \(start)")
        
        // 핫페퍼 API 호출
        RestaurantAPI.shared.searchRestaurants(
            lat: lat,
            lng: lng,
            range: range,
            start: start,
            count: 10
        )
        .receive(on: DispatchQueue.main)
        .sink(
            receiveCompletion: { [weak self] completion in
                guard let self = self else { return }
                
                switch completion {
                case .finished:
                    print("✅ API 호출 완료")
                    break
                case .failure(let error):
                    self.errorMessage = "API 오류: \(error.description)"
                    print("❌ API 호출 실패: \(error.description)")
                    
                    // 오류 발생 시에도 로딩 상태 해제
                    self.isLoading = false
                    self.isLoadingPage = false
                    
                    // 오류가 발생했지만 이미 일부 데이터가 있다면 더 이상 페이지가 없는 것으로 처리
                    if !self.restaurants.isEmpty {
                        self.hasMorePages = false
                    }
                }
            },
            receiveValue: { [weak self] hotPepperRestaurants in
                guard let self = self else { return }
                
                print("📡 API 응답 수신: \(hotPepperRestaurants.count)개 항목")
                
                // HotPepperRestaurant을 Restaurant 모델로 변환
                let newRestaurants = self.convertToRestaurants(
                    hotPepperRestaurants: hotPepperRestaurants,
                    theme: self.currentTheme
                )
                
                // 테마에 맞는 식당 필터링
                let filteredRestaurants = self.filterRestaurantsByTheme(
                    restaurants: newRestaurants,
                    theme: self.currentTheme
                )
                
                print("✅ API 응답: \(hotPepperRestaurants.count)개, 필터링 후: \(filteredRestaurants.count)개")
                
                // 결과 업데이트
                if start == 1 {
                    self.restaurants = filteredRestaurants
                } else {
                    self.restaurants.append(contentsOf: filteredRestaurants)
                }
                
                // 페이지 상태 업데이트
                self.currentPage = (start - 1) / 10 + 1
                
                // 10개 미만이면 마지막 페이지로 간주
                // 또는 API 응답이 0개면 더 이상 데이터가 없는 것으로 간주
                self.hasMorePages = filteredRestaurants.count >= 10 && filteredRestaurants.count > 0
                
                // 상태 업데이트
                self.isLoading = false
                self.isLoadingPage = false
            }
        )
        .store(in: &cancellables)
    }
    
    // HotPepperRestaurant를 우리 앱의 Restaurant 모델로 변환
    private func convertToRestaurants(hotPepperRestaurants: [HotPepperRestaurant], theme: String) -> [Today_s_Meal.Restaurant] {
        return hotPepperRestaurants.map { hotPepperRest in
            // 옵셔널 값들을 안전하게 처리
            let category = hotPepperRest.genre?.name ?? theme
            let imageUrl = hotPepperRest.photo?.mobile?.l
            let address = hotPepperRest.address ?? "주소 정보 없음"
            
            // 핫페퍼 API는 평점을 제공하지 않으므로 더미 평점 생성
            // 실제 앱에서는 다른 API(Google Places 등)를 추가로 사용하여 평점 정보 보완 가능
            let rating = Double.random(in: 3.0...5.0).rounded(to: 1)
            let reviewCount = Int.random(in: 10...200)
            
            return Today_s_Meal.Restaurant(
                id: hotPepperRest.id,
                name: hotPepperRest.name,
                address: address,
                rating: rating,
                reviewCount: reviewCount,
                category: category,
                latitude: hotPepperRest.lat,
                longitude: hotPepperRest.lng,
                imageUrl: imageUrl
            )
        }
    }
    
    // 테마에 맞는 식당만 필터링
    private func filterRestaurantsByTheme(restaurants: [Today_s_Meal.Restaurant], theme: String) -> [Today_s_Meal.Restaurant] {
        let keyword = themeToAPIKeyword[theme] ?? theme
        
        // 이미 API에서 키워드로 필터링되어 왔을 가능성이 높지만,
        // 추가적인 필터링이 필요하면 여기서 수행
        return restaurants.filter { restaurant in
            // 필터링 키워드가 빈 문자열이면 모든 식당 포함
            if keyword.isEmpty {
                return true
            }
            
            // 카테고리 기반 필터링 (정확히 일치하거나 부분 문자열 포함)
            let categoryMatches = restaurant.category.contains(keyword) || 
                                  (theme == "izakaya" && restaurant.category.contains("居酒屋"))
            
            // 이름 기반 필터링 (선택적)
            let nameMatches = restaurant.name.contains(keyword) ||
                              (theme == "izakaya" && restaurant.name.contains("居酒屋"))
            
            return categoryMatches || nameMatches
        }
    }
    
    // API range 값 변환 (미터 -> API 사용 범위 값)
    private func getAPIRangeValue(forMeters meters: Double) -> Int {
        switch meters {
        case ...300: return 1
        case ...500: return 2
        case ...1000: return 3
        case ...2000: return 4
        default: return 5
        }
    }
}

extension Double {
    func rounded(to places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}

#Preview {
    RestaurantListView(
        theme: "izakaya",
        searchRadius: 1000,
        locationService: LocationService()
    )
} 