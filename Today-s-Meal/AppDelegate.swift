import UIKit
import GoogleMaps

// 전역 Google Maps API 키
let googleApiKey = "ここにGoogle Maps APIキーを入力してください"

// 전역 Hot Pepper API 키
let hotPepperApiKey = "ここにホットペッパーAPIキーを入力してください"

class AppDelegate: UIResponder, UIApplicationDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // 1. 현재 언어 설정 저장
        let currentLanguageSettings = UserDefaults.standard.array(forKey: "AppleLanguages")
        
        // 2. 임시로 일본어로 설정
        UserDefaults.standard.set(["ja"], forKey: "AppleLanguages")
        
        // 3. Google Maps 초기화 (일본어 설정이 적용된 상태)
        GMSServices.provideAPIKey(googleApiKey) // 전역 상수 googleApiKey 사용
        
        // 4. 원래 언어 설정 복원
        if let originalSettings = currentLanguageSettings {
            UserDefaults.standard.set(originalSettings, forKey: "AppleLanguages")
        } else {
            UserDefaults.standard.removeObject(forKey: "AppleLanguages")
        }
        
        // 네트워크 및 API 키 설정 확인
        print("🌐 앱 번들 ID: \(Bundle.main.bundleIdentifier ?? "알 수 없음")")
        
        // Info.plist에서 필요한 설정 확인
        let keysToCheck = ["NSLocationWhenInUseUsageDescription", "NSLocationAlwaysUsageDescription"]
        for key in keysToCheck {
            if Bundle.main.object(forInfoDictionaryKey: key) != nil {
                print("✅ \(key) 설정 확인됨")
            } else {
                print("⚠️ \(key) 설정 없음 - 문제 발생 가능")
            }
        }
        
        return true
    }
} 
