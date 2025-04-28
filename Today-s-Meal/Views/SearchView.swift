import SwiftUI
import CoreLocation
import UIKit

struct SearchView: View {
    // 환경 객체에서 위치 서비스 사용
    @EnvironmentObject var locationService: LocationService
    @StateObject private var viewModel = RestaurantViewModel()
    @State private var navigateToResults = false
    @State private var selectedRangeIndex = 2 // Default to 1000m
    @State private var showLocationPermissionAlert = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // App logo/header
                Image(systemName: "fork.knife.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .foregroundColor(.orange)
                
                Text("오늘의 식사")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                // ⭐️ 테스트용 권한 요청 버튼 ⭐️
                Button("!!! 위치 권한 수동 요청 테스트 !!!") {
                    print("--- SearchView: 수동 권한 요청 버튼 탭됨 --- ")
                    locationService.requestLocationPermission()
                }
                .padding()
                .background(Color.purple)
                .foregroundColor(.white)
                .cornerRadius(8)
                
                // Location status
                locationStatusView
                
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
                .disabled(locationService.currentLocation == nil)
                
                // Error message
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                }
                
                Spacer()
            }
            .padding()
            .navigationDestination(isPresented: $navigateToResults) {
                ResultsView(restaurants: viewModel.restaurants)
                    .environmentObject(locationService)
            }
            .onAppear {
                // 화면 표시 시 위치 권한을 다시 한번 요청
                locationService.requestLocationPermission()
                
                if let location = locationService.currentLocation {
                    viewModel.currentLocation = location
                }
            }
            .onChange(of: locationService.currentLocation) { newLocation in
                if let location = newLocation {
                    viewModel.currentLocation = location
                }
            }
            .onChange(of: selectedRangeIndex) { newValue in
                viewModel.searchRadius = Double(viewModel.rangeOptions[newValue].value)
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
            if let location = locationService.currentLocation {
                return "위치 확인됨: \(String(format: "%.6f", location.coordinate.latitude)), \(String(format: "%.6f", location.coordinate.longitude))"
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