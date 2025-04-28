import UIKit
import GoogleMaps
import GooglePlaces

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // Google Maps API 키 직접 설정 (하드코딩)
        let apiKey = "AIzaSyCE5Ey4KQcU5d91JKIaVePni4WDouOE7j8"
        
        // Google Maps Services 초기화
        GMSServices.provideAPIKey(apiKey)
        
        // Google Places 초기화
        GMSPlacesClient.provideAPIKey(apiKey)
        
        // 초기화 확인
        if GMSServices.sharedServices() != nil {
            print("🗺️ Google Maps 서비스 초기화 성공. 키: \(apiKey)")
        } else {
            print("⚠️ Google Maps 서비스 초기화 실패")
        }
        
        // 네트워크 및 API 키 설정 확인
        print("🌐 앱 번들 ID: \(Bundle.main.bundleIdentifier ?? "알 수 없음")")
        
        // Info.plist에서 필요한 설정 확인
        let requiredKeys = ["NSLocationWhenInUseUsageDescription", "NSAppTransportSecurity", "GMSApiKey"]
        for key in requiredKeys {
            if let _ = Bundle.main.object(forInfoDictionaryKey: key) {
                print("✅ \(key) 설정 확인됨")
            } else {
                print("⚠️ \(key) 설정 없음 - 문제 발생 가능")
            }
        }
        
        // 네트워크 상태 확인
        print("네트워크 연결 확인을 권장합니다...")
        
        return true
    }
} 