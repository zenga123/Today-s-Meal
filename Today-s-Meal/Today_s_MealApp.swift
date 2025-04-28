//
//  Today_s_MealApp.swift
//  Today-s-Meal
//
//  Created by musung on 2025/04/27.
//

import SwiftUI
import CoreLocation

// 앱 정보 확인용 익스텐션 추가
extension Bundle {
    static func printInfoPlistContents() {
        print("=== Info.plist 내용 확인 ===")
        
        guard let path = Bundle.main.path(forResource: "Info", ofType: "plist"),
              let dict = NSDictionary(contentsOfFile: path) else {
            print("Info.plist 파일을 찾을 수 없음")
            
            // 주요 키 직접 확인
            let keys = [
                "NSLocationWhenInUseUsageDescription",
                "CFBundleIdentifier",
                "CFBundleDisplayName"
            ]
            
            for key in keys {
                let value = Bundle.main.object(forInfoDictionaryKey: key)
                print("\(key): \(value ?? "없음")")
            }
            
            return
        }
        
        for (key, value) in dict {
            print("\(key): \(value)")
        }
        
        print("=========================")
    }
}

@main
struct Today_s_MealApp: App {
    // 앱 시작 시 위치 서비스 초기화 및 권한 요청
    @StateObject private var locationService = LocationService()
    
    init() {
        print("🟢🟢🟢 Today_s_MealApp: init 시작 🟢🟢🟢")
        // Info.plist 내용 출력
        Bundle.printInfoPlistContents()
        
        // 앱 설정 출력
        if let bundleId = Bundle.main.bundleIdentifier {
            print("앱 번들 ID: \(bundleId)")
        }
        
        // 위치 사용 설명 직접 등록 (Info.plist가 정상 동작하지 않을 경우)
        if Bundle.main.object(forInfoDictionaryKey: "NSLocationWhenInUseUsageDescription") == nil {
            print("경고: Info.plist에 위치 권한 설명이 없음")
        }
        print("🟢🟢🟢 Today_s_MealApp: init 완료 🟢🟢🟢")
    }
    
    var body: some Scene {
        WindowGroup {
            // ContentView를 사용하고 locationService를 주입
            ContentView()
                .environmentObject(locationService)
        }
    }
}
