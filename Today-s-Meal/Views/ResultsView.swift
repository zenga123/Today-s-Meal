import SwiftUI
import MapKit

struct ResultsView: View {
    let restaurants: [HotPepperRestaurant]
    let searchRadius: Double
    let theme: String?
    @State private var selectedRestaurant: HotPepperRestaurant?
    @State private var navigateToDetail = false
    @State private var showMapView = false
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var locationService: LocationService
    
    init(restaurants: [HotPepperRestaurant], searchRadius: Double = 1000, theme: String? = nil) {
        self.restaurants = restaurants
        self.searchRadius = searchRadius
        self.theme = theme
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 지도/목록 토글 버튼
            HStack {
                Spacer()
                
                Button(action: {
                    withAnimation {
                        showMapView.toggle()
                    }
                }) {
                    HStack {
                        Image(systemName: showMapView ? "list.bullet" : "map")
                        Text(showMapView ? "목록으로 보기" : "지도로 보기")
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.orange.opacity(0.2))
                    .foregroundColor(.orange)
                    .cornerRadius(20)
                }
                .padding(.trailing)
                .padding(.vertical, 8)
            }
            
            if restaurants.isEmpty {
                emptyResultsView
            } else {
                if showMapView {
                    // 지도 뷰
                    MainRestaurantMapView(
                        restaurants: restaurants, 
                        userLocation: locationService.currentLocation,
                        searchRadius: searchRadius
                    )
                    .edgesIgnoringSafeArea(.bottom)
                } else {
                    // 리스트 뷰
                    restaurantListView
                }
            }
        }
        .navigationTitle(getNavigationTitle())
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $navigateToDetail) {
            if let restaurant = selectedRestaurant {
                DetailView(restaurant: restaurant)
                    .environmentObject(locationService)
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    dismiss()
                }) {
                    HStack {
                        Image(systemName: "arrow.left")
                        Text("뒤로")
                    }
                }
            }
        }
    }
    
    private var emptyResultsView: some View {
        VStack(spacing: 20) {
            Image(systemName: "magnifyingglass")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .foregroundColor(.gray)
            
            Text("음식점을 찾을 수 없습니다")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("검색 조건을 변경해 보세요")
                .foregroundColor(.gray)
            
            Button(action: {
                dismiss()
            }) {
                Text("검색으로 돌아가기")
                    .padding()
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.top, 20)
        }
        .padding()
    }
    
    private var restaurantListView: some View {
        List {
            ForEach(restaurants) { restaurant in
                SearchResultRow(restaurant: restaurant)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedRestaurant = restaurant
                        navigateToDetail = true
                    }
            }
        }
        .listStyle(PlainListStyle())
    }
    
    private func getNavigationTitle() -> String {
        let baseTitle = "검색 결과 (\(restaurants.count))"
        if let theme = theme {
            return "\(baseTitle) - \(theme)"
        } else {
            return baseTitle
        }
    }
}

struct SearchResultRow: View {
    let restaurant: HotPepperRestaurant
    
    var body: some View {
        HStack(spacing: 16) {
            // Thumbnail image
            AsyncImage(url: URL(string: {
                if let photo = restaurant.photo, let mobile = photo.mobile, let l = mobile.l {
                    return l
                }
                return ""
            }())) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                        .frame(width: 80, height: 80)
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 80, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                case .failure:
                    Image(systemName: "photo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 80, height: 80)
                        .foregroundColor(.gray)
                @unknown default:
                    EmptyView()
                }
            }
            .frame(width: 80, height: 80)
            
            // Restaurant info
            VStack(alignment: .leading, spacing: 4) {
                Text(restaurant.name)
                    .font(.headline)
                    .lineLimit(1)
                
                Text(restaurant.genre?.name ?? "장르 정보 없음")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                Text(restaurant.access ?? "위치 정보 없음")
                    .font(.caption)
                    .lineLimit(2)
                    .foregroundColor(.secondary)
                
                HStack {
                    Image(systemName: "yen.circle.fill")
                    Text(restaurant.budget?.name ?? "가격 정보 없음")
                    
                    if let distance = restaurant.distance {
                        Spacer()
                        HStack(spacing: 2) {
                            Image(systemName: "location.circle")
                            Text(formatDistance(distance))
                        }
                        .foregroundColor(.blue)
                    }
                }
                .font(.caption)
                .foregroundColor(.orange)
            }
        }
        .padding(.vertical, 8)
    }
    
    private func formatDistance(_ distance: Int) -> String {
        if distance < 1000 {
            return "\(distance)m"
        } else {
            let distanceKm = Double(distance) / 1000.0
            return String(format: "%.1f km", distanceKm)
        }
    }
} 