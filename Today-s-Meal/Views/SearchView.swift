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
    @State private var showDebugActions = false // 디버그 액션 상태
    
    var body: some View {
        NavigationStack {
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
                    
                    // 디버그 버튼 (3번 탭하면 표시)
                    Button(action: {
                        showDebugActions.toggle()
                        print("디버그 모드: \(showDebugActions ? "활성화" : "비활성화")")
                    }) {
                        Image(systemName: "ellipsis.circle")
                            .font(.title2)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 10)
                
                // 디버그 액션 패널
                if showDebugActions {
                    VStack(spacing: 8) {
                        Text("디버그 패널")
                            .font(.subheadline.bold())
                        
                        Button("Google Maps 재초기화") {
                            // Google Maps 직접 초기화
                            let apiKey = "AIzaSyCE5Ey4KQcU5d91JKIaVePni4WDouOE7j8"
                            GMSServices.provideAPIKey(apiKey)
                            print("🗺️ Google Maps API 키 재설정: \(apiKey)")
                        }
                        .buttonStyle(.bordered)
                        
                        Button("위치 서비스 강제 갱신") {
                            locationService.requestLocationPermission()
                            print("위치 서비스 강제 갱신 요청")
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(8)
                    .padding(.horizontal)
                }
                
                // 지도 표시 - 전체 화면 너비로 설정
                ZStack {
                    // 새로운 네이티브 지도 뷰 사용
                    NativeMapView(
                        mapLocation: $locationService.currentLocation,
                        selectedRadius: $searchRadius
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
                
                // Location status
                locationStatusView
                    .padding(.top, 16)
                
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
                
                // Search button
                Button(action: {
                    searchRestaurants()
                }) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                        Text("주변 맛집 검색")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .padding(.horizontal)
                .padding(.top, 16)
                .disabled(locationService.currentLocation == nil)
                
                // Error message
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                }
                
                Spacer()
            }
            .preferredColorScheme(.dark) // 다크 모드 강제 적용
            .navigationDestination(isPresented: $navigateToResults) {
                ResultsView(restaurants: viewModel.restaurants)
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
    
    private var locationStatusView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("위치 상태")
                .font(.headline)
            
            HStack {
                Image(systemName: locationSymbol)
                    .foregroundColor(locationColor)
                
                Text(locationStatusText)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
        }
        .padding(.horizontal)
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
    
    private var locationStatusText: String {
        switch locationService.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            if locationService.currentLocation != nil {
                return "위치 확인됨"
            } else {
                return "위치 확인 중..."
            }
        case .denied, .restricted:
            return "위치 접근 거부됨. 설정에서 권한을 활성화해주세요."
        case .notDetermined:
            return "위치 권한이 결정되지 않았습니다."
        @unknown default:
            return "알 수 없는 위치 상태."
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