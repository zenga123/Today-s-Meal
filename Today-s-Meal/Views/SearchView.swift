import SwiftUI
import CoreLocation
import UIKit
import GoogleMaps

struct SearchView: View {
    // 환경 객체에서 위치 서비스 사용
    @EnvironmentObject var locationService: LocationService
    @StateObject private var viewModel = RestaurantViewModel()
    @State private var navigateToResults = false
    @State private var selectedRangeIndex = 2 // Default to 1000m
    @State private var searchRadius: Double = 1000 // 기본 반경 1000m
    @State private var showLocationPermissionAlert = false
    @State private var selectedTheme: String? = nil // 선택된 테마
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // App logo/header
                    HStack {
                        Image(systemName: "fork.knife.circle.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 60, height: 60)
                            .foregroundColor(.orange)
                        
                        Text("오늘의 식사")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Spacer()
                        
                        // 위치 상태 컴팩트 표시
                        HStack(spacing: 4) {
                            Image(systemName: locationSymbol)
                                .foregroundColor(locationColor)
                            Text(locationStatusCompact)
                                .font(.caption)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(10)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 10)
                    
                    // 지도 표시 - 전체 화면 너비로 설정
                    ZStack {
                        // 새로운 네이티브 지도 뷰 사용
                        NativeMapView(
                            mapLocation: $locationService.currentLocation,
                            selectedRadius: $searchRadius,
                            autoSearch: true,  // 자동 검색 활성화
                            onSearchResults: { restaurants in
                                // 지도에서 검색된 식당 결과를 뷰모델에 설정
                                viewModel.restaurants = restaurants
                                
                                // 로딩 상태 업데이트 (만약 로딩 UI가 있다면)
                                viewModel.isLoading = false
                                
                                print("🔍 지도에서 식당 \(restaurants.count)개 검색됨")
                            }
                        )
                        .frame(height: 250)
                        .clipped()
                        .overlay(
                            RoundedRectangle(cornerRadius: 0)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )
                        
                        if locationService.currentLocation == nil {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                .scaleEffect(1.5)
                        }
                    }
                    .edgesIgnoringSafeArea(.horizontal)
                    
                    // 위치 권한 요청 버튼 (위치 권한이 없을 때만 표시)
                    if locationService.authorizationStatus == .notDetermined || 
                       locationService.authorizationStatus == .denied || 
                       locationService.authorizationStatus == .restricted {
                        Button(action: {
                            // 권한 요청
                            locationService.requestLocationPermission()
                            showLocationPermissionAlert = true
                        }) {
                            HStack {
                                Image(systemName: "location.circle.fill")
                                Text("위치 권한 요청하기")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)
                        
                        Button(action: {
                            // 설정으로 바로 이동
                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(url)
                            }
                        }) {
                            HStack {
                                Image(systemName: "gear")
                                Text("설정에서 위치 권한 활성화")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.gray)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)
                    }
                    
                    // Search radius picker
                    VStack(alignment: .leading, spacing: 8) {
                        Text("검색 반경")
                            .font(.headline)
                        
                        Picker("검색 반경", selection: $selectedRangeIndex) {
                            ForEach(0..<viewModel.rangeOptions.count, id: \.self) { index in
                                Text(viewModel.rangeOptions[index].label)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                    .padding(.horizontal)
                    .padding(.top, 16)
                    
                    // 음식 테마 그리드
                    VStack(alignment: .leading, spacing: 8) {
                        // 제목 및 설명
                        Text("음식 테마")
                            .font(.headline)
                        
                        Text("아래 영역에 이미지를 적용할 수 있습니다")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .padding(.bottom, 8)
                        
                        // 첫 번째 줄 (1-4)
                        HStack(spacing: 12) {
                            EmptyCirclePlaceholder(label: "居酒屋")
                            EmptyCirclePlaceholder(label: "ダイニングバー・バル")
                            EmptyCirclePlaceholder(label: "創作料理")
                            EmptyCirclePlaceholder(label: "和食")
                        }
                        .padding(.bottom, 12)
                        
                        // 두 번째 줄 (5-8)
                        HStack(spacing: 12) {
                            EmptyCirclePlaceholder(label: "洋食")
                            EmptyCirclePlaceholder(label: "イタリアン・フレンチ")
                            EmptyCirclePlaceholder(label: "中華")
                            EmptyCirclePlaceholder(label: "焼肉・ホルモン")
                        }
                        .padding(.bottom, 12)
                        
                        // 세 번째 줄 (9-12)
                        HStack(spacing: 12) {
                            EmptyCirclePlaceholder(label: "韓国料理")
                            EmptyCirclePlaceholder(label: "アジア・エスニック料理")
                            EmptyCirclePlaceholder(label: "各国料理")
                            EmptyCirclePlaceholder(label: "カラオケ・パーティ")
                        }
                        .padding(.bottom, 12)
                        
                        // 네 번째 줄 (13-16)
                        HStack(spacing: 12) {
                            EmptyCirclePlaceholder(label: "バー・カクテル")
                            EmptyCirclePlaceholder(label: "ラーメン")
                            EmptyCirclePlaceholder(label: "お好み焼き・もんじゃ")
                            EmptyCirclePlaceholder(label: "カフェ・スイーツ")
                        }
                        .padding(.bottom, 12)
                        
                        // 다섯 번째 줄 (17)
                        HStack(spacing: 12) {
                            EmptyCirclePlaceholder(label: "その他グルメ")
                            Spacer() // 빈 공간
                            Spacer() // 빈 공간
                            Spacer() // 빈 공간
                        }
                        
                        // 사용 방법 안내
                        Text("* 이미지 추가 방법: Assets.xcassets에 이미지를 추가한 후, 코드에서 useCustomImage: true 옵션을 추가하면 됩니다.")
                            .font(.caption2)
                            .foregroundColor(.gray)
                            .padding(.top, 8)
                    }
                    .padding(.horizontal)
                    .padding(.top, 16)
                    
                    // Error message
                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .padding()
                    }
                    
                    // 하단에 여백 추가
                    Spacer(minLength: 30)
                }
            }
            .preferredColorScheme(.dark) // 다크 모드 강제 적용
            .navigationDestination(isPresented: $navigateToResults) {
                ResultsView(restaurants: viewModel.restaurants, searchRadius: searchRadius, theme: selectedTheme)
                    .environmentObject(locationService)
            }
            .onAppear {
                // 화면 표시 시 위치 권한을 다시 한번 요청
                print("SearchView 화면 나타남, 위치 권한 요청")
                locationService.requestLocationPermission()
                
                if let location = locationService.currentLocation {
                    viewModel.currentLocation = location
                    print("현재 위치가 있음: \(location.coordinate.latitude), \(location.coordinate.longitude)")
                } else {
                    print("현재 위치 정보 없음")
                }
            }
            .onChange(of: locationService.currentLocation) { newLocation in
                if let location = newLocation {
                    viewModel.currentLocation = location
                    print("위치 업데이트: \(location.coordinate.latitude), \(location.coordinate.longitude)")
                }
            }
            .onChange(of: selectedRangeIndex) { newValue in
                // 선택된 범위 옵션에 따라 거리 값 설정
                let newRadius = Double(viewModel.rangeOptions[newValue].value)
                viewModel.searchRadius = newRadius
                searchRadius = newRadius // 지도에 표시될 반경 업데이트
                print("🔄 검색 반경 버튼 클릭: \(newRadius)m (인덱스: \(newValue))")
                
                // 검색 반경이 변경되면 새로운 API 요청 실행
                if let location = locationService.currentLocation {
                    viewModel.searchRestaurants(
                        lat: location.coordinate.latitude,
                        lng: location.coordinate.longitude
                    )
                }
            }
            .onChange(of: searchRadius) { newRadius in
                // 지도에서 변경된 반경에 따라 선택 영역 업데이트
                let closestIndex = viewModel.rangeOptions.indices.min(by: {
                    abs(Double(viewModel.rangeOptions[$0].value) - newRadius) <
                    abs(Double(viewModel.rangeOptions[$1].value) - newRadius)
                }) ?? 2 // 기본값 1000m (인덱스 2)
                
                if selectedRangeIndex != closestIndex {
                    selectedRangeIndex = closestIndex
                    viewModel.searchRadius = Double(viewModel.rangeOptions[closestIndex].value)
                }
            }
            .alert("위치 권한 필요", isPresented: $showLocationPermissionAlert) {
                Button("설정으로 이동") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                Button("취소", role: .cancel) {}
            } message: {
                Text("주변 맛집을 찾기 위해서는 위치 정보 접근 권한이 필요합니다. 설정에서 권한을 허용해 주세요.")
            }
        }
    }
    
    private var locationSymbol: String {
        switch locationService.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            return locationService.currentLocation != nil ? "location.fill" : "location.circle"
        case .denied, .restricted:
            return "location.slash"
        default:
            return "location.circle"
        }
    }
    
    private var locationColor: Color {
        switch locationService.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            return locationService.currentLocation != nil ? .green : .yellow
        case .denied, .restricted:
            return .red
        default:
            return .gray
        }
    }
    
    private var locationStatusCompact: String {
        switch locationService.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            if locationService.currentLocation != nil {
                return "위치 확인됨"
            } else {
                return "확인 중"
            }
        case .denied, .restricted:
            return "권한 필요"
        case .notDetermined:
            return "권한 필요"
        @unknown default:
            return "오류"
        }
    }
    
    private func searchRestaurants() {
        guard let location = locationService.currentLocation else {
            viewModel.errorMessage = "위치를 확인할 수 없습니다. 다시 시도해주세요."
            return
        }
        
        viewModel.searchRestaurants(
            lat: location.coordinate.latitude,
            lng: location.coordinate.longitude
        )
        
        navigateToResults = true
    }
}

// 음식 테마 버튼 컴포넌트
struct FoodThemeButton: View {
    let image: String
    let text: String
    let color: Color
    @Binding var selectedTheme: String?
    
    var isSelected: Bool {
        selectedTheme == text
    }
    
    var body: some View {
        Button(action: {
            // 이미 선택된 테마를 다시 누르면 선택 해제
            if isSelected {
                selectedTheme = nil
            } else {
                selectedTheme = text
            }
            print("선택된 테마: \(selectedTheme ?? "없음")")
        }) {
            VStack {
                Image(systemName: image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 36, height: 36)
                    .foregroundColor(.white)
                    .padding(8)
                
                Text(text)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.bottom, 8)
            }
            .frame(maxWidth: .infinity)
            .background(isSelected ? color : color.opacity(0.7))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.white : Color.clear, lineWidth: 2)
            )
            .cornerRadius(12)
            .scaleEffect(isSelected ? 1.05 : 1.0)
            .shadow(color: isSelected ? Color.black.opacity(0.3) : Color.clear, radius: 3, x: 0, y: 2)
            .animation(.spring(), value: isSelected)
        }
    }
}

// 음식 테마 이미지 플레이스홀더 컴포넌트
struct FoodCategoryImagePlaceholder: View {
    var body: some View {
        ZStack {
            Rectangle()
                .frame(width: 80, height: 80)
                .foregroundColor(Color.gray.opacity(0.15))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
            
            VStack(spacing: 4) {
                Image(systemName: "photo")
                    .font(.system(size: 24))
                    .foregroundColor(Color.gray.opacity(0.7))
                
                Text("이미지")
                    .font(.caption2)
                    .foregroundColor(Color.gray.opacity(0.7))
            }
        }
        .frame(width: 80, height: 80)
    }
}

// 실제 음식 카테고리 아이템 (이미지가 있는 경우)
struct FoodCategoryItem: View {
    let imageName: String
    let label: String
    let useCustomImage: Bool
    
    init(imageName: String, label: String, useCustomImage: Bool = false) {
        self.imageName = imageName
        self.label = label
        self.useCustomImage = useCustomImage
    }
    
    var body: some View {
        VStack(spacing: 4) {
            if useCustomImage {
                // 사용자 제공 이미지 표시 (Assets에서 불러옴)
                // 실제 앱에서는 사용자가 추가한 이미지 파일을 사용
                Image(imageName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            } else {
                // 임시 시스템 이미지 사용
                Image(systemName: imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
                    .padding(10)
                    .background(Circle().fill(Color.orange.opacity(0.2)))
                    .foregroundColor(.orange)
            }
            
            // 카테고리 이름
            Text(label)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.gray)
        }
        .frame(width: 80, height: 80)
    }
}

// 원형 배경은 유지하고 아이콘은 제거하여 사용자가 직접 이미지를 추가할 수 있게 합니다.
struct EmptyCirclePlaceholder: View {
    let label: String
    
    var body: some View {
        VStack(spacing: 8) {
            // 원형 배경
            Circle()
                .fill(Color.orange.opacity(0.2))
                .frame(width: 60, height: 60)
                .overlay(
                    // 사용자가 여기에 이미지를 추가할 수 있습니다
                    Text("+")
                        .font(.system(size: 20))
                        .foregroundColor(.gray.opacity(0.7))
                )
            
            // 카테고리 이름
            Text(label)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.gray)
        }
        .frame(width: 80, height: 80)
    }
} 