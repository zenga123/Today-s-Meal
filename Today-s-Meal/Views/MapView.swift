import SwiftUI
import GoogleMaps

struct MainRestaurantMapView: View {
    var restaurants: [HotPepperRestaurant]
    var searchRadius: Double = 1000 // 기본값 1000m 
    @State private var selectedRestaurant: HotPepperRestaurant?
    @State private var selectedRestaurantID: String? = nil
    
    // 맵 뷰를 위한 Coordinator
    @StateObject private var mapViewCoordinator = MapViewCoordinator()
    
    // 초기 위치 설정
    init(restaurants: [HotPepperRestaurant], userLocation: CLLocation?, searchRadius: Double = 1000) {
        self.restaurants = restaurants
        self.searchRadius = searchRadius
        
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
            mapViewCoordinator.searchRadius = searchRadius
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
    var restaurants: [HotPepperRestaurant]
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
        
        // 중요: 마커 탭 시 정보창이 표시되지 않도록 설정
        mapView.settings.consumesGesturesInView = false
        // 기본 인포윈도우 표시 방지
        mapView.settings.allowScrollGesturesDuringRotateOrZoom = true
        
        // 인포윈도우 타일 레이어 비활성화
        mapView.settings.compassButton = true  // 불필요한 설정이지만 타일 레이어 리프레시 유도
        
        // 기본 인포윈도우 숨기기 위한 투명 오버레이 추가
        let overlay = UIView(frame: .zero)
        overlay.backgroundColor = .clear
        overlay.isUserInteractionEnabled = false
        overlay.translatesAutoresizingMaskIntoConstraints = false
        mapView.addSubview(overlay)
        NSLayoutConstraint.activate([
            overlay.topAnchor.constraint(equalTo: mapView.topAnchor),
            overlay.leadingAnchor.constraint(equalTo: mapView.leadingAnchor),
            overlay.trailingAnchor.constraint(equalTo: mapView.trailingAnchor),
            overlay.bottomAnchor.constraint(equalTo: mapView.bottomAnchor)
        ])
        
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
    var restaurants: [HotPepperRestaurant] = []
    var centerLocation: CLLocation = CLLocation(latitude: 35.6812, longitude: 139.7671) // 도쿄 기본값
    var updateMapCenter: Bool = false
    var selectedRestaurantID: String?
    var searchRadius: Double = 1000 // 기본값 1000m
    var onMarkerTapped: ((String) -> Void)?
    private var markers: [String: GMSMarker] = [:]
    private var radiusCircle: GMSCircle?
    private var infoWindow: UIView? // 커스텀 인포윈도우
    private var infoMarker: GMSMarker? // 인포윈도우가 표시된 마커
    
    // 마커 업데이트
    func updateMarkers() {
        guard let mapView = mapView else { return }
        
        // 기존 마커 제거
        mapView.clear()
        markers.removeAll()
        
        // 커스텀 인포윈도우 제거
        infoWindow?.removeFromSuperview()
        infoWindow = nil
        infoMarker = nil
        
        // 검색 반경 원 추가
        let circle = GMSCircle(position: centerLocation.coordinate, radius: CLLocationDistance(searchRadius))
        circle.fillColor = UIColor(red: 0, green: 0, blue: 1, alpha: 0.1)
        circle.strokeColor = UIColor(red: 0, green: 0, blue: 1, alpha: 0.5)
        circle.strokeWidth = 1
        circle.map = mapView
        radiusCircle = circle
        
        // 각 음식점에 마커 추가
        for restaurant in restaurants {
            let marker = GMSMarker()
            marker.position = CLLocationCoordinate2D(latitude: restaurant.lat, longitude: restaurant.lng)
            
            // 중요: 모든 마커 텍스트 속성 완전히 제거
            marker.title = nil
            marker.snippet = nil
            
            // 기본 인포윈도우 작동 방지 (마커 위에 인포윈도우 표시되지 않게)
            marker.infoWindowAnchor = CGPoint(x: 0, y: 0)
            marker.appearAnimation = .none
            
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
        
        // 선택된 마커가 있으면 인포윈도우 표시
        if let selectedID = selectedRestaurantID, 
           let marker = markers[selectedID],
           let restaurant = restaurants.first(where: { $0.id == selectedID }) {
            showInfoWindow(for: marker, restaurant: restaurant)
        }
    }
    
    // 마커 인포윈도우 미표시 설정
    func mapView(_ mapView: GMSMapView, didTapInfoWindowOf marker: GMSMarker) -> Bool {
        // 기본 인포윈도우 탭 이벤트 가로채기 (표시하지 않음)
        return true
    }
    
    // 마커 탭 시 인포윈도우 표시 여부 결정
    func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool {
        guard let restaurantID = marker.userData as? String,
              let restaurant = restaurants.first(where: { $0.id == restaurantID }) else { 
            return false 
        }
        
        // 이미 선택된 마커라면 인포윈도우 숨기기
        if selectedRestaurantID == restaurantID {
            hideInfoWindow()
            selectedRestaurantID = nil
            onMarkerTapped?(restaurantID)
            updateMarkers()
            return true
        }
        
        selectedRestaurantID = restaurantID
        
        // 선택된 마커 중심으로 카메라 이동
        mapView.animate(toLocation: marker.position)
        
        // 커스텀 인포윈도우 표시
        showInfoWindow(for: marker, restaurant: restaurant)
        
        // 콜백 호출
        onMarkerTapped?(restaurantID)
        
        // 마커 업데이트
        updateMarkers()
        
        // 중요: 기본 인포윈도우가 표시되지 않도록 true 반환
        return true
    }
    
    // 인포윈도우 표시 막기 (빈 뷰 반환)
    func mapView(_ mapView: GMSMapView, markerInfoWindow marker: GMSMarker) -> UIView? {
        // 완전히 투명한 뷰 반환 (화면에 표시되지 않음)
        let emptyView = UIView(frame: CGRect.zero)
        emptyView.backgroundColor = UIColor.clear
        emptyView.isHidden = true
        return emptyView
    }
    
    // 인포윈도우 표시 시도 시 가로채기
    func mapView(_ mapView: GMSMapView, willHandle boolValue: Bool) -> Bool {
        // 기본 처리 차단
        return true
    }
    
    // 맵 탭 시 인포윈도우 숨기기
    func mapView(_ mapView: GMSMapView, didTapAt coordinate: CLLocationCoordinate2D) {
        hideInfoWindow()
        selectedRestaurantID = nil
        onMarkerTapped?("")
        updateMarkers()
    }
    
    // 커스텀 인포윈도우 표시
    private func showInfoWindow(for marker: GMSMarker, restaurant: HotPepperRestaurant) {
        // 기존 인포윈도우 제거
        hideInfoWindow()
        
        guard let mapView = self.mapView else { return }
        
        // 커스텀 인포윈도우 생성
        let infoWindow = UIView(frame: CGRect(x: 0, y: 0, width: 250, height: 70))
        infoWindow.backgroundColor = UIColor.white
        infoWindow.layer.cornerRadius = 8
        infoWindow.layer.shadowColor = UIColor.black.cgColor
        infoWindow.layer.shadowOpacity = 0.3
        infoWindow.layer.shadowOffset = CGSize(width: 0, height: 2)
        infoWindow.layer.shadowRadius = 3
        infoWindow.layer.borderWidth = 1
        infoWindow.layer.borderColor = UIColor.lightGray.cgColor
        
        // 삼각형 표시기 추가 (마커와 인포윈도우 연결)
        let triangleView = UIView(frame: CGRect(x: infoWindow.frame.width/2 - 10, y: infoWindow.frame.height - 1, width: 20, height: 10))
        triangleView.backgroundColor = .clear
        
        let trianglePath = UIBezierPath()
        trianglePath.move(to: CGPoint(x: 0, y: 0))
        trianglePath.addLine(to: CGPoint(x: 20, y: 0))
        trianglePath.addLine(to: CGPoint(x: 10, y: 10))
        trianglePath.close()
        
        let triangleLayer = CAShapeLayer()
        triangleLayer.path = trianglePath.cgPath
        triangleLayer.fillColor = UIColor.white.cgColor
        triangleView.layer.addSublayer(triangleLayer)
        
        infoWindow.addSubview(triangleView)
        
        // 레스토랑 이름 레이블
        let nameLabel = UILabel(frame: CGRect(x: 15, y: 10, width: 220, height: 25))
        nameLabel.text = restaurant.name
        nameLabel.font = UIFont.systemFont(ofSize: 14, weight: .bold)
        nameLabel.textColor = UIColor.black
        nameLabel.adjustsFontSizeToFitWidth = true
        nameLabel.minimumScaleFactor = 0.75
        
        // 접근 정보 레이블
        let accessLabel = UILabel(frame: CGRect(x: 15, y: 35, width: 220, height: 25))
        accessLabel.text = restaurant.access ?? "정보 없음"
        accessLabel.font = UIFont.systemFont(ofSize: 12)
        accessLabel.textColor = UIColor.darkGray
        accessLabel.adjustsFontSizeToFitWidth = true
        accessLabel.minimumScaleFactor = 0.75
        
        infoWindow.addSubview(nameLabel)
        infoWindow.addSubview(accessLabel)
        
        // 애니메이션 효과 추가
        infoWindow.alpha = 0
        infoWindow.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        
        // 인포윈도우 위치 계산 (마커 위에 표시)
        let point = mapView.projection.point(for: marker.position)
        let infoWindowPoint = CGPoint(
            x: point.x - infoWindow.frame.width / 2,
            y: point.y - infoWindow.frame.height - 15 // 마커 위에 표시하도록 조정
        )
        infoWindow.frame.origin = infoWindowPoint
        
        // 맵뷰에 추가
        mapView.addSubview(infoWindow)
        
        // 애니메이션으로 표시
        UIView.animate(withDuration: 0.3) {
            infoWindow.alpha = 1
            infoWindow.transform = .identity
        }
        
        // 참조 저장
        self.infoWindow = infoWindow
        self.infoMarker = marker
        
        print("커스텀 인포윈도우 표시: \(restaurant.name)")
    }
    
    // 인포윈도우 숨기기
    private func hideInfoWindow() {
        if let infoWindow = self.infoWindow {
            // 애니메이션으로 숨기기
            UIView.animate(withDuration: 0.2, animations: {
                infoWindow.alpha = 0
                infoWindow.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
            }) { _ in
                infoWindow.removeFromSuperview()
                self.infoWindow = nil
                self.infoMarker = nil
            }
        } else {
            infoWindow?.removeFromSuperview()
            infoWindow = nil
            infoMarker = nil
        }
    }
    
    // 카메라 위치 변경 시 인포윈도우 위치 업데이트
    func mapView(_ mapView: GMSMapView, didChange position: GMSCameraPosition) {
        if let marker = infoMarker, let restaurant = restaurants.first(where: { $0.id == selectedRestaurantID }) {
            // 기존 인포윈도우 제거 후 다시 표시 (위치 재계산)
            infoWindow?.removeFromSuperview()
            showInfoWindow(for: marker, restaurant: restaurant)
        }
    }
}

// 음식점 정보 카드 컴포넌트
struct RestaurantInfoCard: View {
    let restaurant: HotPepperRestaurant
    
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