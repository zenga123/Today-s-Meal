import SwiftUI
import GoogleMaps

struct RestaurantMapView: View {
    var restaurants: [Restaurant]
    @State private var selectedRestaurant: Restaurant?
    @State private var selectedRestaurantID: String? = nil
    
    // 맵 뷰를 위한 Coordinator
    @StateObject private var mapViewCoordinator = MapViewCoordinator()
    
    // 초기 위치 설정
    init(restaurants: [Restaurant], userLocation: CLLocation?) {
        self.restaurants = restaurants
        
        // 사용자 위치 또는 기본 위치 설정
        if let userLocation = userLocation {
            mapViewCoordinator.centerLocation = userLocation
        } else if let firstRestaurant = restaurants.first {
            mapViewCoordinator.centerLocation = CLLocation(
                latitude: firstRestaurant.lat,
                longitude: firstRestaurant.lng
            )
        } else {
            // 기본 위치 (도쿄)
            mapViewCoordinator.centerLocation = CLLocation(
                latitude: 35.6812,
                longitude: 139.7671
            )
        }
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            GoogleMapView(
                restaurants: restaurants,
                coordinator: mapViewCoordinator,
                selectedRestaurantID: $selectedRestaurantID
            )
            .edgesIgnoringSafeArea(.all)
            
            // 현재 위치로 이동 버튼
            VStack {
                HStack {
                    Spacer()
                    Button(action: centerUserLocation) {
                        Image(systemName: "location.fill")
                            .padding()
                            .background(Color.white)
                            .foregroundColor(.blue)
                            .clipShape(Circle())
                            .shadow(radius: 2)
                    }
                    .padding(.trailing)
                }
                Spacer()
            }
            .padding(.top)
            
            // 선택된 음식점 정보 카드
            if let restaurant = selectedRestaurant {
                RestaurantInfoCard(restaurant: restaurant)
                    .padding()
                    .transition(.move(edge: .bottom))
                    .animation(.spring(), value: selectedRestaurant?.id)
            }
        }
        .onAppear {
            // 모든 음식점 마커 추가
            mapViewCoordinator.restaurants = restaurants
        }
        .onChange(of: selectedRestaurantID) { newID in
            // ID가 변경되면 해당 Restaurant 객체를 찾아 업데이트
            if let id = newID {
                selectedRestaurant = restaurants.first(where: { $0.id == id })
            } else {
                selectedRestaurant = nil
            }
        }
    }
    
    private func centerUserLocation() {
        if let userLocation = restaurants.first?.userLocation {
            mapViewCoordinator.centerLocation = userLocation
            mapViewCoordinator.updateMapCenter = true
        }
    }
}

// Google Maps 뷰 래퍼
struct GoogleMapView: UIViewRepresentable {
    var restaurants: [Restaurant]
    var coordinator: MapViewCoordinator
    @Binding var selectedRestaurantID: String?
    
    func makeUIView(context: Context) -> GMSMapView {
        // 초기 카메라 위치 설정
        let camera = GMSCameraPosition.camera(
            withLatitude: coordinator.centerLocation.coordinate.latitude,
            longitude: coordinator.centerLocation.coordinate.longitude,
            zoom: 15
        )
        
        // 맵 뷰 생성
        let mapView = GMSMapView.map(withFrame: .zero, camera: camera)
        mapView.isMyLocationEnabled = true
        mapView.settings.myLocationButton = true
        
        // 뷰 컨트롤러 연결
        coordinator.mapView = mapView
        coordinator.onMarkerTapped = { id in
            selectedRestaurantID = id
        }
        mapView.delegate = coordinator
        
        return mapView
    }
    
    func updateUIView(_ mapView: GMSMapView, context: Context) {
        // 선택된 음식점 ID 업데이트
        coordinator.selectedRestaurantID = selectedRestaurantID
        
        // 맵 중심 업데이트가 필요한 경우
        if coordinator.updateMapCenter {
            let camera = GMSCameraPosition.camera(
                withLatitude: coordinator.centerLocation.coordinate.latitude,
                longitude: coordinator.centerLocation.coordinate.longitude,
                zoom: 15
            )
            mapView.animate(to: camera)
            coordinator.updateMapCenter = false
        }
        
        // 마커 업데이트
        coordinator.updateMarkers()
    }
    
    func makeCoordinator() -> MapViewCoordinator {
        return coordinator
    }
}

// 맵 뷰 코디네이터 (마커 관리 및 이벤트 처리)
class MapViewCoordinator: NSObject, GMSMapViewDelegate, ObservableObject {
    var mapView: GMSMapView?
    var restaurants: [Restaurant] = []
    var centerLocation: CLLocation = CLLocation(latitude: 35.6812, longitude: 139.7671) // 도쿄 기본값
    var updateMapCenter: Bool = false
    var selectedRestaurantID: String?
    var onMarkerTapped: ((String) -> Void)?
    private var markers: [String: GMSMarker] = [:]
    
    // 마커 업데이트
    func updateMarkers() {
        guard let mapView = mapView else { return }
        
        // 기존 마커 제거
        mapView.clear()
        markers.removeAll()
        
        // 각 음식점에 마커 추가
        for restaurant in restaurants {
            let marker = GMSMarker()
            marker.position = CLLocationCoordinate2D(latitude: restaurant.lat, longitude: restaurant.lng)
            marker.title = restaurant.name
            marker.snippet = restaurant.access
            marker.userData = restaurant.id
            
            // 선택된 음식점 강조 표시
            if restaurant.id == selectedRestaurantID {
                marker.icon = GMSMarker.markerImage(with: .blue)
                marker.zIndex = 1
            } else {
                marker.icon = GMSMarker.markerImage(with: .red)
                marker.zIndex = 0
            }
            
            marker.map = mapView
            markers[restaurant.id] = marker
        }
    }
    
    // 마커 탭 이벤트 처리
    func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool {
        guard let restaurantID = marker.userData as? String else { return false }
        selectedRestaurantID = restaurantID
        
        // 선택된 마커 중심으로 카메라 이동
        mapView.animate(toLocation: marker.position)
        
        // 콜백 호출
        onMarkerTapped?(restaurantID)
        
        // 마커 업데이트
        updateMarkers()
        
        return true
    }
}

// 음식점 정보 카드 컴포넌트
struct RestaurantInfoCard: View {
    var restaurant: Restaurant
    
    var body: some View {
        NavigationLink(destination: DetailView(restaurant: restaurant)) {
            HStack {
                // 옵셔널 체이닝 적용
                AsyncImage(url: URL(string: {
                    if let photo = restaurant.photo, let mobile = photo.mobile, let l = mobile.l {
                        return l
                    }
                    return ""
                }())) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 80, height: 80)
                        .cornerRadius(10)
                } placeholder: {
                    ProgressView()
                        .frame(width: 80, height: 80)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(restaurant.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(restaurant.access ?? "정보 없음")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                    
                    HStack {
                        Image(systemName: "mappin.and.ellipse")
                        Text(formatDistance(restaurant.distance))
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
                .padding(.leading, 8)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
            }
            .padding()
            .background(Color.white)
            .cornerRadius(12)
            .shadow(radius: 3)
        }
    }
    
    private func formatDistance(_ distance: Int?) -> String {
        guard let distance = distance else { return "거리 정보 없음" }
        
        if distance < 1000 {
            return "\(distance)m"
        } else {
            let distanceKm = Double(distance) / 1000.0
            return String(format: "%.1f km", distanceKm)
        }
    }
} 