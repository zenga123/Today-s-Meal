import Foundation
import CoreLocation
import Combine
import UIKit

enum LocationError: Error {
    case notAuthorized
    case locationUnknown
    case monitoringFailed
    case other(Error)
}

class LocationService: NSObject, ObservableObject {
    private let locationManager = CLLocationManager()
    private let geoCoder = CLGeocoder()
    
    // 발행자
    private let locationSubject = PassthroughSubject<CLLocation, LocationError>()
    
    // 현재 위치 정보
    @Published var currentLocation: CLLocation?
    @Published var currentAddress: String?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var locationError: LocationError?
    
    // 위치 업데이트 타이머
    private var locationUpdateTimer: Timer?
    
    var locationPublisher: AnyPublisher<CLLocation, LocationError> {
        return locationSubject.eraseToAnyPublisher()
    }
    
    override init() {
        super.init()
        setupLocationManager()
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters // 정확도 낮춤 (배터리 최적화)
        locationManager.distanceFilter = 200 // 200미터 이동 시에만 업데이트 (배터리 최적화)
        
        // iOS 버전에 따라 적절한 방법으로 권한 상태 확인
        if #available(iOS 14.0, *) {
            authorizationStatus = locationManager.authorizationStatus
        } else {
            authorizationStatus = CLLocationManager.authorizationStatus()
        }
        
        // ⭐️ NotificationCenter 등록 임시 주석 처리 ⭐️
        // NotificationCenter.default.addObserver(self, 
        //                                       selector: #selector(applicationDidBecomeActive),
        //                                       name: UIApplication.didBecomeActiveNotification, 
        //                                       object: nil)
    }
    
    // ⭐️ applicationDidBecomeActive 메서드 임시 주석 처리 ⭐️
    // @objc private func applicationDidBecomeActive() {
    //     print("✅✅✅ LocationService (Services 폴더): applicationDidBecomeActive 호출됨")
    //     // ⭐️ 여기서는 자동으로 권한 요청 안 함 (테스트 목적) ⭐️
    //     print("✅✅✅ LocationService (Services 폴더): applicationDidBecomeActive - 자동 요청 비활성화 상태")
    // }
    
    // ⭐️ deinit 에서 옵저버 제거 임시 주석 처리 ⭐️
    // deinit {
    //     NotificationCenter.default.removeObserver(self)
    // }
    
    func requestLocationPermission() {
        guard locationManager.authorizationStatus == .notDetermined else {
            return
        }
        
        DispatchQueue.main.async { [weak self] in
            self?.locationManager.requestWhenInUseAuthorization()
        }
    }
    
    func requestLocation() {
        // 권한 상태 재확인
        let currentStatus = locationManager.authorizationStatus
        guard currentStatus == .authorizedWhenInUse || currentStatus == .authorizedAlways else {
            if currentStatus == .notDetermined {
                requestLocationPermission() // 만약 아직 미결정이면 다시 요청
            }
            return
        }
        
        locationManager.requestLocation()
    }
    
    func startUpdatingLocation() {
        if authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways {
            // 주기적 위치 업데이트 설정 (30초마다)
            stopUpdateTimer()
            
            // 초기 위치 요청
            locationManager.requestLocation()
            
            // 타이머 설정 (30초마다 위치 업데이트)
            locationUpdateTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
                self?.locationManager.requestLocation()
            }
        } else if authorizationStatus == .notDetermined {
            requestLocationPermission()
        } else {
            locationError = .notAuthorized
        }
    }
    
    func stopUpdatingLocation() {
        locationManager.stopUpdatingLocation()
        stopUpdateTimer()
    }
    
    private func stopUpdateTimer() {
        locationUpdateTimer?.invalidate()
        locationUpdateTimer = nil
    }
    
    deinit {
        stopUpdateTimer()
    }
    
    private func geocodeLocation(_ location: CLLocation) {
        geoCoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            guard let self = self else { return }
            
            if let error = error {
                self.locationError = .other(error)
                return
            }
            
            if let placemark = placemarks?.first {
                let address = [
                    placemark.country,
                    placemark.administrativeArea,
                    placemark.locality,
                    placemark.thoroughfare,
                    placemark.subThoroughfare
                ]
                .compactMap { $0 }
                .joined(separator: " ")
                
                DispatchQueue.main.async {
                    self.currentAddress = address
                }
            }
        }
    }
}

extension LocationService: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        DispatchQueue.main.async {
            self.authorizationStatus = manager.authorizationStatus
            
            switch manager.authorizationStatus {
            case .authorizedWhenInUse, .authorizedAlways:
                self.locationError = nil
                self.requestLocation() // 권한이 승인되면 한 번만 위치 요청
            case .denied, .restricted:
                self.locationError = .notAuthorized
            case .notDetermined:
                // 여기서 별도 처리 불필요
                break
            @unknown default:
                break
            }
        }
    }
    
     func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        DispatchQueue.main.async {
            self.currentLocation = location
            self.locationError = nil
        }
        
        locationSubject.send(location)
        geocodeLocation(location)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        let locationError: LocationError
        
        if let error = error as? CLError {
            switch error.code {
            case .denied:
                locationError = .notAuthorized
            case .locationUnknown:
                locationError = .locationUnknown
            default:
                locationError = .other(error)
            }
        } else {
            locationError = .other(error)
        }
        
        DispatchQueue.main.async {
            self.locationError = locationError
        }
        
        self.locationSubject.send(completion: .failure(locationError))
    }
} 