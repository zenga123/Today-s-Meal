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
                
                // Search button
                Button(action: {
                    navigateToResults = true  // 결과 화면으로 바로 이동
                }) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                        Text("검색 결과 보기")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .padding(.horizontal)
                .padding(.top, 16)
                .disabled(locationService.currentLocation == nil || viewModel.restaurants.isEmpty)
                
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