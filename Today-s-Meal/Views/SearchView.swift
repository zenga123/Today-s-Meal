import SwiftUI
import CoreLocation
import UIKit
import GoogleMaps

struct SearchView: View {
    // 환경 객체에서 위치 서비스 사용
    @EnvironmentObject var locationService: LocationService
    @StateObject private var viewModel = RestaurantViewModel()
    @StateObject private var themeViewModel = RestaurantListViewModel()
    @State private var navigateToResults = false
    @State private var selectedRangeIndex = 2 // Default to 1000m
    @State private var searchRadius: Double = 1000 // 기본 반경 1000m
    @State private var showLocationPermissionAlert = false
    @State private var selectedTheme: String? = nil // 선택된 테마
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // 각 섹션을 별도의 뷰로 분리
                    HeaderSection(
                        locationService: locationService,
                        locationSymbol: locationSymbol,
                        locationColor: locationColor,
                        locationStatusCompact: locationStatusCompact
                    )
                    
                    MapSection(
                        locationService: locationService,
                        viewModel: viewModel, 
                        searchRadius: $searchRadius,
                        selectedTheme: $selectedTheme
                    )
                    
                    if locationService.authorizationStatus == .notDetermined || 
                       locationService.authorizationStatus == .denied || 
                       locationService.authorizationStatus == .restricted {
                        LocationPermissionSection(locationService: locationService, showAlert: $showLocationPermissionAlert)
                    }
                    
                    SearchRadiusSection(
                        selectedRangeIndex: $selectedRangeIndex,
                        viewModel: viewModel
                    )
                    
                    FoodThemeSection(selectedTheme: $selectedTheme, searchRadius: searchRadius)
                    
                    // 선택된 테마가 있으면 음식점 목록 표시
                    if let theme = selectedTheme {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("\(theme == "izakaya" ? "居酒屋" : theme) 음식점")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                
                                Spacer()
                                
                                Text("\(searchRadius/1000, specifier: "%.1f")km 이내")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 16)
                            
                            if themeViewModel.isLoading && themeViewModel.restaurants.isEmpty {
                                // 처음 로딩할 때만 전체 로딩 뷰 표시
                                HStack {
                                    Spacer()
                                    VStack(spacing: 12) {
                                        ProgressView()
                                            .tint(.white)
                                        Text("실제 음식점 검색 중...")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                    Spacer()
                                }
                                .padding(.vertical, 32)
                            } else if themeViewModel.restaurants.isEmpty {
                                VStack(spacing: 16) {
                                    Image(systemName: "magnifyingglass")
                                        .font(.system(size: 40))
                                        .foregroundColor(.gray)
                                    
                                    Text("검색 결과가 없습니다")
                                        .font(.headline)
                                        .foregroundColor(.gray)
                                    
                                    Text("다른 테마나 검색 반경을 변경해보세요")
                                        .font(.caption)
                                        .foregroundColor(.gray.opacity(0.8))
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 40)
                            } else {
                                // 레스토랑 리스트
                                ScrollViewReader { scrollProxy in
                                    LazyVStack(spacing: 0) {
                                        // 식당 목록 로딩 중 상태 표시 (헤더)
                                        if themeViewModel.isLoading {
                                            HStack {
                                                Spacer()
                                                Text("더 많은 음식점 검색 중...")
                                                    .font(.caption)
                                                    .foregroundColor(.gray.opacity(0.7))
                                                Spacer()
                                            }
                                            .padding(.vertical, 8)
                                        }
                                        
                                        ForEach(themeViewModel.restaurants) { restaurant in
                                            RestaurantRow(
                                                restaurant: restaurant, 
                                                distance: restaurant.distance(from: CLLocation(
                                                    latitude: locationService.currentLocation?.coordinate.latitude ?? 0,
                                                    longitude: locationService.currentLocation?.coordinate.longitude ?? 0
                                                ))
                                            )
                                            .id(restaurant.id) // 명시적 ID 설정
                                            .onAppear {
                                                // 마지막 항목에서 5개 앞에 도달하면 다음 페이지 로드 시작
                                                // 이렇게 하면 사용자가 마지막 항목에 도달하기 전에 미리 로딩
                                                if let lastIndex = themeViewModel.restaurants.indices.last,
                                                   let currentIndex = themeViewModel.restaurants.firstIndex(where: { $0.id == restaurant.id }),
                                                   currentIndex >= lastIndex - 5 {
                                                    // 현재 보고 있는 항목의 ID 기억
                                                    let currentVisibleID = restaurant.id
                                                    let oldCount = themeViewModel.restaurants.count
                                                    
                                                    themeViewModel.loadMoreIfNeeded()
                                                    
                                                    // 데이터가 추가된 경우 스크롤 위치 유지
                                                    if oldCount < themeViewModel.restaurants.count {
                                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                                            withAnimation {
                                                                scrollProxy.scrollTo(currentVisibleID, anchor: .center)
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                        
                                        // 식당 목록 로딩 중 상태 표시 (푸터)
                                        if themeViewModel.isLoading {
                                            HStack {
                                                Spacer()
                                                ProgressView()
                                                    .frame(maxWidth: .infinity, maxHeight: 40)
                                                    .tint(.white)
                                                Spacer()
                                            }
                                        }
                                        
                                        // 마지막 페이지 도달 시 더 이상 결과가 없음을 표시
                                        if !themeViewModel.isLoading && !themeViewModel.hasMorePages && !themeViewModel.restaurants.isEmpty {
                                            HStack {
                                                Spacer()
                                                Text("모든 결과를 불러왔습니다")
                                                    .font(.caption)
                                                    .foregroundColor(.gray.opacity(0.7))
                                                    .padding(.vertical, 16)
                                                Spacer()
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.bottom, 20)
                    }
                    
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
                    
                    // 테마가 선택되어 있으면 음식점 검색
                    if let theme = selectedTheme {
                        themeViewModel.searchRestaurants(
                            theme: theme,
                            latitude: location.coordinate.latitude,
                            longitude: location.coordinate.longitude,
                            radius: searchRadius
                        )
                    }
                }
            }
            .onChange(of: selectedRangeIndex) { newValue in
                // 선택된 범위 옵션에 따라 거리 값 설정
                let newRadius = Double(viewModel.rangeOptions[newValue].value)
                viewModel.searchRadius = newRadius
                searchRadius = newRadius // 지도에 표시될 반경 업데이트
                print("🔄 검색 반경 변경: \(newRadius)m (인덱스: \(newValue))")
                
                // 검색 반경이 변경되면 새로운 API 요청 실행
                if let location = locationService.currentLocation {
                    viewModel.searchRestaurants(
                        lat: location.coordinate.latitude,
                        lng: location.coordinate.longitude,
                        selectedTheme: selectedTheme
                    )
                    
                    // 테마가 선택되어 있으면 테마별 음식점도 검색
                    if let theme = selectedTheme {
                        print("🔄 반경 변경으로 \(theme) 테마 음식점 재검색: \(newRadius)m")
                        themeViewModel.searchRestaurants(
                            theme: theme,
                            latitude: location.coordinate.latitude,
                            longitude: location.coordinate.longitude,
                            radius: newRadius
                        )
                    }
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
            .onChange(of: selectedTheme) { newTheme in
                if let theme = newTheme, let location = locationService.currentLocation {
                    // 테마가 선택되면 해당 테마의 음식점 검색
                    themeViewModel.searchRestaurants(
                        theme: theme,
                        latitude: location.coordinate.latitude,
                        longitude: location.coordinate.longitude,
                        radius: searchRadius
                    )
                    
                    // 지도에 테마를 전달하여 검색 실행
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        viewModel.searchRestaurants(
                            lat: location.coordinate.latitude,
                            lng: location.coordinate.longitude,
                            selectedTheme: theme
                        )
                    }
                } else if newTheme == nil, let location = locationService.currentLocation {
                    // 테마 선택이 해제되면 빈 배열로 설정 (마커 표시 안 함)
                    themeViewModel.clearRestaurants()
                    
                    // 지도에도 반영되도록 검색 실행 (테마가 nil이므로 마커가 표시되지 않음)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        viewModel.searchRestaurants(
                            lat: location.coordinate.latitude,
                            lng: location.coordinate.longitude,
                            selectedTheme: nil
                        )
                    }
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

// MARK: - 서브뷰들

// 헤더 섹션
struct HeaderSection: View {
    @ObservedObject var locationService: LocationService
    let locationSymbol: String
    let locationColor: Color
    let locationStatusCompact: String
    
    var body: some View {
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
    }
}

// 지도 섹션
struct MapSection: View {
    @ObservedObject var locationService: LocationService
    let viewModel: RestaurantViewModel
    @Binding var searchRadius: Double
    @Binding var selectedTheme: String?  // 선택된 테마 바인딩 추가
    
    var body: some View {
        ZStack {
            // 새로운 네이티브 지도 뷰 사용
            NativeMapView(
                mapLocation: $locationService.currentLocation,
                selectedRadius: $searchRadius,
                selectedTheme: selectedTheme,  // 선택된 테마 전달
                autoSearch: true,
                onSearchResults: { restaurants in
                    // 지도에서 검색된 식당 결과를 뷰모델에 설정
                    viewModel.restaurants = restaurants
                    
                    // 로딩 상태 업데이트
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
    }
}

// 위치 권한 섹션
struct LocationPermissionSection: View {
    @ObservedObject var locationService: LocationService
    @Binding var showAlert: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            Button(action: {
                // 권한 요청
                locationService.requestLocationPermission()
                showAlert = true
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
        }
    }
}

// 검색 반경 섹션
struct SearchRadiusSection: View {
    @Binding var selectedRangeIndex: Int
    let viewModel: RestaurantViewModel
    
    var body: some View {
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
    }
}

// FoodThemeSection은 별도 파일로 이동되었습니다

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
// 이 정의는 EmptyCirclePlaceholder.swift 파일로 이동되었습니다.
// struct EmptyCirclePlaceholder: View {
//    let label: String
//    let useCustomImage: Bool
//    
//    var body: some View {
//        VStack(spacing: 8) {
//            // 원형 배경
//            Circle()
//                .fill(Color.orange.opacity(0.2))
//                .frame(width: 60, height: 60)
//                .overlay(
//                    // 사용자가 여기에 이미지를 추가할 수 있습니다
//                    Text("+")
//                        .font(.system(size: 20))
//                        .foregroundColor(.gray.opacity(0.7))
//                )
//            
//            // 카테고리 이름
//            Text(label)
//                .font(.caption)
//                .fontWeight(.medium)
//                .foregroundColor(.gray)
//        }
//        .frame(width: 80, height: 80)
//    }
// } 