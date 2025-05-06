import SwiftUI
import GoogleMaps
import CoreLocation

struct GoogleMapsView: UIViewRepresentable {
    @Binding var selectedRestaurant: Restaurant?
    var restaurants: [Restaurant]
    @Binding var mapLocation: CLLocation?
    var markers: [GMSMarker] = []
    
    func makeUIView(context: Context) -> GMSMapView {
        // API 키가 제대로 설정되었는지 확인 -> AppDelegate에서 이미 초기화하므로 여기서는 호출 불필요
        // GMSServices.provideAPIKey(googleApiKey) // 전역 상수 사용
        
        // 기본 위치 (서울)
        let defaultLocation = CLLocationCoordinate2D(latitude: 37.5665, longitude: 126.9780)
        let camera = GMSCameraPosition.camera(withTarget: defaultLocation, zoom: 15.0)
        
        // 지도 생성
        let mapView = GMSMapView(frame: .zero, camera: camera)
        
        // 지도 설정
        mapView.isMyLocationEnabled = true
        mapView.settings.myLocationButton = true
        mapView.settings.compassButton = true
        mapView.settings.zoomGestures = true
        
        // 다크 모드에 맞는 지도 스타일 적용
        mapView.mapStyle = nil  // 기본 스타일로 리셋
        
        return mapView
    }
    
    func updateUIView(_ mapView: GMSMapView, context: Context) {
        // 위치가 업데이트되면 카메라 이동
        if let location = mapLocation {
            let position = CLLocationCoordinate2D(
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude
            )
            
            // 카메라 애니메이션으로 이동
            let camera = GMSCameraPosition.camera(withTarget: position, zoom: 15.0)
            mapView.animate(to: camera)
            
            // 마커 모두 제거
            mapView.clear()
            
            // 현재 위치에 마커 추가
            let marker = GMSMarker()
            marker.position = position
            marker.title = "현재 위치"
            marker.snippet = "여기에 있습니다"
            marker.map = mapView
            
            // 추가 마커들 표시
            for marker in markers {
                marker.map = mapView
            }
        }
    }
} 
