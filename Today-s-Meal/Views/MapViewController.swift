import UIKit
import GoogleMaps
import SwiftUI
import CoreLocation

// UIKit 기반 지도 뷰 컨트롤러
class MapViewController: UIViewController, GMSMapViewDelegate {
    // 현재 위치
    var currentLocation: CLLocation?
    
    // 검색 반경 (미터 단위)
    var searchRadius: Double = 1000 {
        didSet {
            // 반경이 변경되면 즉시 업데이트
            updateRadiusCircle()
            updateRadiusLabel()
        }
    }
    
    // 지도 뷰 참조
    private var mapView: GMSMapView!
    
    // 반경 원 오버레이
    private var radiusCircle: GMSCircle?
    
    // 반경 표시 레이블
    private var radiusLabel: PaddingLabel!
    
    override func loadView() {
        // Google Maps API 키 설정 (코드로 직접 설정)
        GMSServices.provideAPIKey("AIzaSyCE5Ey4KQcU5d91JKIaVePni4WDouOE7j8")
        
        // 기본 위치 - 서울
        let defaultLocation = CLLocationCoordinate2D(latitude: 37.5665, longitude: 126.9780)
        
        // 지도 옵션 설정
        let camera = GMSCameraPosition.camera(withTarget: defaultLocation, zoom: 15)
        
        // 지도 생성 (로드뷰에서 직접 생성)
        let mapView = GMSMapView.map(withFrame: .zero, camera: camera)
        self.mapView = mapView
        self.view = mapView
        
        // 지도 설정
        mapView.mapType = .normal
        mapView.settings.compassButton = true
        mapView.settings.myLocationButton = true
        mapView.isMyLocationEnabled = true
        
        // 지도 델리게이트 설정
        mapView.delegate = self
        
        // 반경 레이블 추가
        setupRadiusLabel()
        
        // 디버깅용 로그
        print("✅ MapViewController loadView 완료")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("✅ MapViewController viewDidLoad 호출됨")
        
        // 현재 위치로 이동 (있는 경우)
        moveToCurrentLocation()
        
        // 테스트용 마커 추가
        addTestMarker()
    }
    
    // 반경 레이블 설정
    private func setupRadiusLabel() {
        radiusLabel = PaddingLabel(padding: UIEdgeInsets(top: 4, left: 8, bottom: 4, right: 8))
        radiusLabel.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        radiusLabel.textColor = .white
        radiusLabel.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        radiusLabel.textAlignment = .center
        radiusLabel.layer.cornerRadius = 8
        radiusLabel.clipsToBounds = true
        
        // 기본 반경 텍스트 설정
        updateRadiusLabel()
        
        // 지도 뷰에 추가
        mapView.addSubview(radiusLabel)
        
        // 레이블 위치 조정 (왼쪽 하단)
        radiusLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            radiusLabel.leadingAnchor.constraint(equalTo: mapView.leadingAnchor, constant: 16),
            radiusLabel.bottomAnchor.constraint(equalTo: mapView.bottomAnchor, constant: -32)
        ])
    }
    
    // 반경 레이블 업데이트
    private func updateRadiusLabel() {
        let radiusText: String
        if searchRadius >= 1000 {
            let kmRadius = searchRadius / 1000.0
            radiusText = String(format: "검색 반경: %.1f km", kmRadius)
        } else {
            radiusText = String(format: "검색 반경: %.0f m", searchRadius)
        }
        
        // UI 업데이트는 메인 스레드에서
        DispatchQueue.main.async { [weak self] in
            self?.radiusLabel.text = radiusText
        }
    }
    
    // 테스트용 마커
    private func addTestMarker() {
        // 서울 시청 위치에 마커 추가
        let seoulCityHall = CLLocationCoordinate2D(latitude: 37.5662, longitude: 126.9785)
        let marker = GMSMarker()
        marker.position = seoulCityHall
        marker.title = "서울시청"
        marker.snippet = "Seoul City Hall"
        marker.icon = GMSMarker.markerImage(with: .blue)
        marker.map = mapView
        
        print("✅ 테스트 마커 추가됨")
    }
    
    // 위치 업데이트 메서드
    func updateLocation(_ location: CLLocation) {
        self.currentLocation = location
        moveToCurrentLocation()
    }
    
    // 검색 반경 변경 메서드
    func updateSearchRadius(_ radius: Double) {
        self.searchRadius = radius
    }
    
    // 반경 원 업데이트
    private func updateRadiusCircle() {
        // 기존 원 제거
        radiusCircle?.map = nil
        
        // 보라색 원을 표시하지 않음 - 원하는 경우 아래 주석을 해제하여 다시 활성화 가능
        /*
        guard let location = currentLocation else { return }
        
        // 새 원 생성
        let circle = GMSCircle(position: location.coordinate, radius: searchRadius)
        circle.fillColor = UIColor.blue.withAlphaComponent(0.1)
        circle.strokeColor = UIColor.blue.withAlphaComponent(0.5)
        circle.strokeWidth = 1
        circle.map = mapView
        
        self.radiusCircle = circle
        */
    }
    
    // 현재 위치로 지도 이동
    private func moveToCurrentLocation() {
        guard let location = currentLocation else { 
            print("❌ 현재 위치 정보 없음")
            return 
        }
        
        let position = CLLocationCoordinate2D(
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude
        )
        
        // 카메라 이동
        let camera = GMSCameraPosition.camera(withTarget: position, zoom: 15)
        mapView.animate(to: camera)
        
        // 현재 위치에 마커 추가
        let marker = GMSMarker()
        marker.position = position
        marker.title = "현재 위치"
        marker.snippet = "여기에 있습니다"
        marker.map = mapView
        
        // 반경 원 업데이트
        updateRadiusCircle()
        
        print("✅ 지도 위치 업데이트: \(position.latitude), \(position.longitude)")
    }
    
    // MARK: - GMSMapViewDelegate
    
    // 카메라 이동이 완료된 후 호출 - 메서드 이름 수정
    func mapView(_ mapView: GMSMapView, didChange position: GMSCameraPosition) {
        // 줌 레벨에 따라 검색 반경 조정
        let zoomLevel = position.zoom
        
        // 줌 레벨에 따른 반경 업데이트 (한 번만 호출)
        updateRadiusBasedOnZoom(zoomLevel)
        
        // 디버깅용
        print("📏 줌 레벨: \(zoomLevel), 계산된 반경: \(calculateRadiusFromZoom(zoomLevel))")
    }
    
    // 줌 레벨에 따라 반경 업데이트
    private func updateRadiusBasedOnZoom(_ zoomLevel: Float) {
        if zoomLevel >= 10 && zoomLevel <= 18 {
            let newRadius = calculateRadiusFromZoom(zoomLevel)
            // 민감도 임계값을 작게 설정하여 작은 변화도 반영되도록 함
            if abs(newRadius - searchRadius) > 0.1 { 
                searchRadius = newRadius
                print("🔄 반경 업데이트: \(searchRadius)")
            }
        }
    }
    
    // 줌 레벨에 따른 반경 계산 함수
    private func calculateRadiusFromZoom(_ zoom: Float) -> Double {
        // 줌 레벨에 따른 반경 계산 (18: 300m, 10: 3000m 사이의 값)
        // zoom이 18일 때 300, 10일 때 3000이 되도록 선형 계산
        let zoomRange: Double = 8.0 // 18 - 10
        let radiusRange: Double = 2700.0 // 3000 - 300
        
        let zoomFactor = Double(18.0 - zoom) / zoomRange
        let radius = 300.0 + (zoomFactor * radiusRange)
        
        // 소수점 아래 1자리까지만 사용하여 안정성 향상
        return Double(round(radius * 10) / 10)
    }
}

// 패딩이 있는 라벨 클래스 (UILabel 확장 대신 서브클래스 사용)
class PaddingLabel: UILabel {
    private var insets: UIEdgeInsets
    
    init(padding: UIEdgeInsets) {
        self.insets = padding
        super.init(frame: .zero)
    }
    
    required init?(coder aDecoder: NSCoder) {
        self.insets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        super.init(coder: aDecoder)
    }
    
    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: insets))
    }
    
    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(
            width: size.width + insets.left + insets.right,
            height: size.height + insets.top + insets.bottom
        )
    }
}

// SwiftUI에서 사용할 수 있는 MapView
struct NativeMapView: UIViewControllerRepresentable {
    // 위치 바인딩
    @Binding var mapLocation: CLLocation?
    // 선택된 반경 바인딩
    @Binding var selectedRadius: Double
    
    func makeUIViewController(context: Context) -> MapViewController {
        let viewController = MapViewController()
        viewController.currentLocation = mapLocation
        viewController.searchRadius = selectedRadius
        return viewController
    }
    
    func updateUIViewController(_ uiViewController: MapViewController, context: Context) {
        if let location = mapLocation {
            uiViewController.updateLocation(location)
        }
        
        // 선택된 반경 업데이트
        if uiViewController.searchRadius != selectedRadius {
            uiViewController.updateSearchRadius(selectedRadius)
        }
    }
} 