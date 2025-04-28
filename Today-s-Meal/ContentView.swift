//
//  ContentView.swift
//  Today-s-Meal
//
//  Created by musung on 2025/04/27.
//

import SwiftUI

struct ContentView: View {
    // 앱에서 전달된 위치 서비스 사용
    @EnvironmentObject var locationService: LocationService
    
    var body: some View {
        SearchView()
    }
}

#Preview {
    ContentView()
        .environmentObject(LocationService()) // 프리뷰에서도 위치 서비스 제공
}
