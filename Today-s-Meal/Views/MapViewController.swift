import UIKit
import GoogleMaps
import SwiftUI
import CoreLocation

// UIKit 기반 지도 뷰 컨트롤러
class MapViewController: UIViewController {
    // 현재 위치
    var currentLocation: CLLocation?
    
    // 지도 뷰 참조
    private var mapView: GMSMapView!
    
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
        
        print("✅ 지도 위치 업데이트: \(position.latitude), \(position.longitude)")
    }
}

// SwiftUI에서 사용할 수 있는 MapView
struct NativeMapView: UIViewControllerRepresentable {
    // 위치 바인딩
    @Binding var mapLocation: CLLocation?
    
    func makeUIViewController(context: Context) -> MapViewController {
        let viewController = MapViewController()
        viewController.currentLocation = mapLocation
        return viewController
    }
    
    func updateUIViewController(_ uiViewController: MapViewController, context: Context) {
        if let location = mapLocation {
            uiViewController.updateLocation(location)
        }
    }
} 