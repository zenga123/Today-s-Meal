import SwiftUI
import MapKit
import GoogleMaps
import WebKit

struct RestaurantDetailView: View {
    let restaurant: HotPepperRestaurant
    @Environment(\.presentationMode) var presentationMode
    @State private var showMap = false
    @State private var detailedRestaurant: HotPepperRestaurant?
    @State private var isLoading = true
    @EnvironmentObject var locationService: LocationService
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if isLoading {
                    loadingView
                } else {
                    // 헤더 이미지
                    headerImageSection
                    
                    // 식당 이름 및 기본 정보
                    restaurantInfoSectionWithoutMap
                    
                    // 구글 지도 직접 표시 (새로 추가)
                    GoogleMapsWebView(
                        userLatitude: locationService.currentLocation?.coordinate.latitude ?? 0,
                        userLongitude: locationService.currentLocation?.coordinate.longitude ?? 0,
                        destinationLatitude: currentRestaurant.lat,
                        destinationLongitude: currentRestaurant.lng,
                        destinationName: currentRestaurant.name
                    )
                    .frame(height: 200)
                    .cornerRadius(12)
                    .padding(.vertical, 8)
                    
                    Divider()
                        .background(Color.gray.opacity(0.5))
                    
                    // 영업시간 및 주소
                    businessInfoSection
                    
                    Divider()
                        .background(Color.gray.opacity(0.5))
                    
                    // 식당 특징 (Wi-Fi, 주차장, 카드 결제 등)
                    featuresSection
                    
                    Divider()
                        .background(Color.gray.opacity(0.5))
                    
                    // 외부 링크 (공식 웹사이트 등)
                    linksSection
                    
                    // 푸터 공간
                    Color.clear.frame(height: 50)
                }
            }
            .padding()
        }
        .background(Color.black)
        .navigationBarTitle("", displayMode: .inline)
        .navigationBarBackButtonHidden(true)
        .navigationBarItems(leading: backButton)
        .onAppear {
            loadRestaurantDetail()
        }
    }
    
    // 로딩 화면
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(.white)
            
            Text("詳細情報を読み込み中...")
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.vertical, 100)
    }
    
    // 상세 정보 로드
    private func loadRestaurantDetail() {
        isLoading = true
        
        // API에서 상세 정보 가져오기
        RestaurantAPI.shared.getRestaurantDetail(id: restaurant.id) { fetchedRestaurant in
            DispatchQueue.main.async {
                if let fetchedRestaurant = fetchedRestaurant {
                    self.detailedRestaurant = fetchedRestaurant
                    print("✅ 레스토랑 상세 정보 로드 완료: \(fetchedRestaurant.name)")
                } else {
                    // API에서 가져오지 못한 경우 기존 정보 사용
                    self.detailedRestaurant = self.restaurant
                    print("⚠️ API에서 상세 정보를 가져오지 못해 기존 정보 사용: \(self.restaurant.name)")
                }
                
                self.isLoading = false
            }
        }
    }
    
    // 현재 표시할 레스토랑 (상세 정보 또는 기본 정보)
    private var currentRestaurant: HotPepperRestaurant {
        return detailedRestaurant ?? restaurant
    }
    
    // 뒤로 가기 버튼
    private var backButton: some View {
        Button(action: {
            presentationMode.wrappedValue.dismiss()
        }) {
            HStack {
                Image(systemName: "arrow.left")
                    .foregroundColor(.white)
                Text("戻る")
                    .foregroundColor(.white)
            }
        }
    }
    
    // 헤더 이미지 섹션
    private var headerImageSection: some View {
        ZStack {
            // 기본 이미지
            Color.gray.opacity(0.3)
                .frame(height: 250)
                .cornerRadius(12)
            
            // 식당 이미지 (있는 경우)
            if let photoUrl = currentRestaurant.photo?.pc?.l {
                AsyncImage(url: URL(string: photoUrl)) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(height: 250)
                            .clipped()
                            .cornerRadius(12)
                    } else if phase.error != nil {
                        Image(systemName: "photo")
                            .font(.system(size: 40))
                            .foregroundColor(.white)
                    } else {
                        ProgressView()
                            .tint(.white)
                    }
                }
            } else {
                Image(systemName: "photo")
                    .font(.system(size: 40))
                    .foregroundColor(.white)
            }
        }
    }
    
    // 식당 정보 섹션 (지도 버튼 제거)
    private var restaurantInfoSectionWithoutMap: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(currentRestaurant.name)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            if let genre = currentRestaurant.genre?.name {
                Text(genre)
                    .font(.subheadline)
                    .foregroundColor(.orange)
            }
            
            if let catchPhrase = currentRestaurant.catchPhrase {
                Text(catchPhrase)
                    .font(.body)
                    .foregroundColor(.gray)
                    .padding(.top, 4)
            }
        }
    }
    
    // 영업시간 및 주소 섹션
    private var businessInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("営業情報")
                .font(.headline)
                .foregroundColor(.white)
            
            // 영업시간
            HStack(alignment: .top) {
                Image(systemName: "clock")
                    .foregroundColor(.gray)
                    .frame(width: 24)
                
                VStack(alignment: .leading) {
                    Text("営業時間")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    if let open = currentRestaurant.open, let close = currentRestaurant.close {
                        Text("\(open) - \(close)")
                            .foregroundColor(.white)
                    } else {
                        Text("情報なし")
                            .foregroundColor(.gray)
                    }
                }
            }
            
            // 주소
            HStack(alignment: .top) {
                Image(systemName: "location")
                    .foregroundColor(.gray)
                    .frame(width: 24)
                
                VStack(alignment: .leading) {
                    Text("住所")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    if let address = currentRestaurant.address {
                        Text(address)
                            .foregroundColor(.white)
                    } else {
                        Text("情報なし")
                            .foregroundColor(.gray)
                    }
                }
            }
            
            // 접근 정보
            HStack(alignment: .top) {
                Image(systemName: "tram")
                    .foregroundColor(.gray)
                    .frame(width: 24)
                
                VStack(alignment: .leading) {
                    Text("アクセス方法")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    if let access = currentRestaurant.access {
                        Text(access)
                            .foregroundColor(.white)
                    } else {
                        Text("情報なし")
                            .foregroundColor(.gray)
                    }
                }
            }
        }
    }
    
    // 식당 특징 섹션
    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("店舗の特徴")
                .font(.headline)
                .foregroundColor(.white)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                // Wi-Fi
                featureItem(icon: "wifi", title: "Wi-Fi", available: currentRestaurant.wifi == "あり" || currentRestaurant.wifi == "있음")
                
                // 주차
                featureItem(icon: "car", title: "駐車場", available: currentRestaurant.parking == "あり" || currentRestaurant.parking == "있음")
                
                // 카드 결제
                featureItem(icon: "creditcard", title: "カード決済", available: currentRestaurant.card == "利用可" || currentRestaurant.card == "가능")
                
                // 금연
                featureItem(icon: "nosign", title: "禁煙席", available: currentRestaurant.nonSmoking?.contains("禁煙") ?? false || currentRestaurant.nonSmoking?.contains("금연") ?? false)
                
                // 개인룸
                featureItem(icon: "door.right.hand.closed", title: "個室", available: currentRestaurant.privateRoom == "あり" || currentRestaurant.privateRoom == "있음")
                
                // 영어 서비스
                featureItem(icon: "person.wave.2", title: "英語対応", available: currentRestaurant.english == "あり" || currentRestaurant.english == "가능")
            }
        }
    }
    
    // 외부 링크 섹션
    private var linksSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("外部リンク")
                .font(.headline)
                .foregroundColor(.white)
            
            if let pcUrl = currentRestaurant.urls?.pc, !pcUrl.isEmpty {
                Link(destination: URL(string: pcUrl) ?? URL(string: "https://www.hotpepper.jp")!) {
                    HStack {
                        Image(systemName: "globe")
                        Text("公式サイトを訪問")
                        Spacer()
                        Image(systemName: "arrow.up.right.square")
                    }
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
            }
            
            if let mobileUrl = currentRestaurant.urls?.mobile, !mobileUrl.isEmpty, mobileUrl != currentRestaurant.urls?.pc {
                Link(destination: URL(string: mobileUrl) ?? URL(string: "https://www.hotpepper.jp")!) {
                    HStack {
                        Image(systemName: "iphone")
                        Text("モバイルサイトを訪問")
                        Spacer()
                        Image(systemName: "arrow.up.right.square")
                    }
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
            }
        }
    }
    
    // 특징 아이템 뷰
    private func featureItem(icon: String, title: String, available: Bool) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(available ? .green : .gray)
            
            Text(title)
                .foregroundColor(.white)
            
            Spacer()
            
            Text(available ? "あり" : "なし")
                .foregroundColor(available ? .green : .gray)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color.gray.opacity(0.2))
        .cornerRadius(8)
    }
}

// WebView를 사용하여 Google Maps 경로 표시
struct GoogleMapsWebView: UIViewRepresentable {
    let userLatitude: Double
    let userLongitude: Double
    let destinationLatitude: Double
    let destinationLongitude: Double
    let destinationName: String
    
    // 디버깅용 상태 표시
    @State private var debugMessage: String = ""
    
    func makeUIView(context: Context) -> WKWebView {
        // WKWebView 설정
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        
        // 자바스크립트 콘솔 로그를 Swift로 전달하는 핸들러 추가
        let contentController = WKUserContentController()
        contentController.add(context.coordinator, name: "iosNative")
        configuration.userContentController = contentController
        
        // 웹뷰 생성
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = false
        webView.scrollView.isScrollEnabled = false
        webView.backgroundColor = .white // 배경색을 흰색으로 변경
        
        // 디버깅용 콘솔 로그 노출
        #if DEBUG
        if #available(iOS 16.4, *) {
            webView.isInspectable = true
        }
        #endif
        
        // 웹뷰 참조 저장
        context.coordinator.currentWebView = webView
        
        // Google Maps JavaScript API를 사용하여 경로 표시
        loadMapsDirections(webView)
        
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        // 필요한 경우에만 다시 로드
        if context.coordinator.lastUserLat != userLatitude || 
           context.coordinator.lastUserLng != userLongitude ||
           context.coordinator.lastDestLat != destinationLatitude ||
           context.coordinator.lastDestLng != destinationLongitude {
            
            context.coordinator.lastUserLat = userLatitude
            context.coordinator.lastUserLng = userLongitude
            context.coordinator.lastDestLat = destinationLatitude
            context.coordinator.lastDestLng = destinationLongitude
            
            // 웹뷰 참조 업데이트
            context.coordinator.currentWebView = webView
            
            loadMapsDirections(webView)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        var parent: GoogleMapsWebView
        var lastUserLat: Double = 0
        var lastUserLng: Double = 0
        var lastDestLat: Double = 0
        var lastDestLng: Double = 0
        var retryCount = 0
        weak var currentWebView: WKWebView? // 현재 웹뷰 참조를 저장할 속성 추가
        
        init(_ parent: GoogleMapsWebView) {
            self.parent = parent
            self.lastUserLat = parent.userLatitude
            self.lastUserLng = parent.userLongitude
            self.lastDestLat = parent.destinationLatitude
            self.lastDestLng = parent.destinationLongitude
        }
        
        // 웹뷰 로딩 완료 처리
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            print("✅ 지도 로딩 완료")
            self.currentWebView = webView // 웹뷰 참조 저장
            
            // 지도 초기화 여부 확인
            webView.evaluateJavaScript("document.getElementById('map').innerHTML !== ''") { result, error in
                if let isMapInitialized = result as? Bool, isMapInitialized {
                    print("✅ 지도 요소가 초기화되었습니다")
                    self.retryCount = 0 // 성공하면 재시도 카운트 초기화
                } else {
                    print("❌ 지도 요소가 비어 있습니다")
                    // 지도 다시 로드 시도
                    self.reloadMap(webView)
                }
            }
        }
        
        // 웹뷰 로딩 실패 처리
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            print("❌ 지도 로딩 실패: \(error.localizedDescription)")
            self.currentWebView = webView // 웹뷰 참조 저장
            self.reloadMap(webView)
        }
        
        // JavaScript에서 전달한 메시지 처리
        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            if message.name == "iosNative", let messageBody = message.body as? String {
                print("📱 JavaScript 메시지: \(messageBody)")
                
                // 오류 메시지가 포함된 경우 지도 다시 로드 - 수정된 부분
                if messageBody.contains("ERROR:") || messageBody.contains("실패") {
                    // 저장된 웹뷰 참조 사용
                    if let webView = self.currentWebView {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            self.reloadMap(webView)
                        }
                    } else {
                        print("⚠️ 웹뷰 참조가 없습니다. 재로드할 수 없습니다.")
                    }
                }
            }
        }
        
        // 지도 다시 로드 시도
        private func reloadMap(_ webView: WKWebView) {
            // 최대 3번까지만 재시도
            if retryCount >= 3 {
                print("⚠️ 최대 재시도 횟수 초과, 직선 경로로 전환")
                webView.evaluateJavaScript("showStraightRoute();", completionHandler: nil)
                return
            }
            
            retryCount += 1
            print("🔄 지도 재로딩 시도 #\(retryCount)")
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                let reloadScript = """
                if (typeof google !== 'undefined' && typeof google.maps !== 'undefined') {
                    console.log('지도 다시 초기화 시도');
                    if (typeof initMap === 'function') {
                        initMap();
                    } else {
                        console.log('initMap 함수를 찾을 수 없음');
                        showStraightRoute();
                    }
                } else {
                    console.log('Google Maps API가 로드되지 않음');
                    location.reload();
                }
                """
                webView.evaluateJavaScript(reloadScript, completionHandler: nil)
            }
        }
    }
    
    private func loadMapsDirections(_ webView: WKWebView) {
        // Google Maps JavaScript API 키
        let apiKey = "AIzaSyCE5Ey4KQcU5d91JKIaVePni4WDouOE7j8"
        
        // HTML 컨텐츠 생성
        let htmlContent = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0, user-scalable=no">
            <style>
                body { 
                    margin: 0; 
                    padding: 0; 
                    background-color: #ffffff; 
                    color: black;
                    font-family: -apple-system, BlinkMacSystemFont, sans-serif;
                }
                #map { 
                    width: 100%; 
                    height: 100%; 
                    background-color: #f0f0f0;
                    position: absolute;
                    top: 0;
                    left: 0;
                    right: 0;
                    bottom: 0;
                }
                /* 구글 맵 정보창 크기 조절 */
                .gm-style .gm-style-iw-c {
                    max-width: 100px !important;
                    max-height: 70px !important;
                    padding: 5px !important;
                    transform: translate(-50%, -100%) !important;
                }
                .gm-style .gm-style-iw-d {
                    max-width: 90px !important;
                    max-height: 60px !important;
                    overflow: auto !important;
                    padding: 0 !important;
                }
                /* 정보창 텍스트 크기 조절 */
                .info-content {
                    font-size: 8px !important;
                    padding: 2px !important;
                    line-height: 1.1 !important;
                    color: black;
                }
                .info-content b {
                    font-size: 9px !important;
                }
                /* 꼬리 버튼 숨기기 */
                .gm-style .gm-style-iw-t::after {
                    display: none !important;
                }
                /* 닫기 버튼 크기 줄이기 */
                .gm-style .gm-style-iw-c button.gm-ui-hover-effect {
                    width: 12px !important;
                    height: 12px !important;
                    right: 0px !important;
                    top: 0px !important;
                    opacity: 0.5 !important;
                }
                .gm-style .gm-style-iw-c button.gm-ui-hover-effect img {
                    width: 10px !important;
                    height: 10px !important;
                }
                /* 상단 정보 패널 스타일 */
                #infoPanel {
                    position: absolute;
                    top: 10px;
                    left: 50%;
                    transform: translateX(-50%);
                    background-color: rgba(0, 0, 0, 0.7);
                    color: white;
                    padding: 5px 10px;
                    border-radius: 20px;
                    font-size: 11px;
                    z-index: 100;
                    text-align: center;
                    width: auto;
                    min-width: 100px;
                }
                /* 로딩 패널 스타일 */
                #loading {
                    position: absolute;
                    top: 0;
                    left: 0;
                    width: 100%;
                    height: 100%;
                    display: flex;
                    justify-content: center;
                    align-items: center;
                    background-color: #f0f0f0;
                    z-index: 100;
                }
                #error {
                    position: absolute;
                    top: 0;
                    left: 0;
                    width: 100%;
                    height: 100%;
                    display: none;
                    flex-direction: column;
                    justify-content: center;
                    align-items: center;
                    background-color: #f0f0f0;
                    z-index: 101;
                    padding: 20px;
                    text-align: center;
                }
                .spinner {
                    border: 4px solid rgba(0, 0, 0, 0.3);
                    border-radius: 50%;
                    border-top: 4px solid #3498db;
                    width: 30px;
                    height: 30px;
                    animation: spin 1s linear infinite;
                }
                @keyframes spin {
                    0% { transform: rotate(0deg); }
                    100% { transform: rotate(360deg); }
                }
            </style>
        </head>
        <body>
            <div id="map"></div>
            <div id="infoPanel" style="display: none;"></div>
            <div id="loading">
                <div class="spinner"></div>
            </div>
            <div id="error" style="display: none;">
                <p>길찾기 정보를 불러올 수 없습니다.<br>직선 거리로 표시합니다.</p>
            </div>
            
            <script>
            let map;
            let directionsService;
            let directionsRenderer;
            let mapInitialized = false;
            let infoWindowOpened = false;
            
            // iOS에 메시지 전송
            function sendToiOS(message) {
                try {
                    window.webkit.messageHandlers.iosNative.postMessage(message);
                } catch(err) {
                    console.log('iOS 메시지 전송 실패: ' + err);
                }
            }
            
            // 콘솔 로그 캡처
            const originalConsoleLog = console.log;
            console.log = function() {
                originalConsoleLog.apply(console, arguments);
                const message = Array.from(arguments).join(' ');
                sendToiOS("LOG: " + message);
            };
            
            // 에러 처리
            console.error = function() {
                originalConsoleLog.apply(console, arguments);
                const message = Array.from(arguments).join(' ');
                sendToiOS("ERROR: " + message);
                showError();
            };
            
            // 직선 경로 표시 (오류 발생 시 대체 방법)
            function showStraightRoute() {
                try {
                    document.getElementById('loading').style.display = 'none';
                    
                    const userLocation = { lat: \(userLatitude), lng: \(userLongitude) };
                    const destination = { lat: \(destinationLatitude), lng: \(destinationLongitude) };
                    
                    if (!mapInitialized) {
                        // Google Maps API가 로딩되었는지 확인
                        if (typeof google === 'undefined' || typeof google.maps === 'undefined') {
                            sendToiOS("ERROR: Google Maps API가 로딩되지 않았습니다. 직선 경로를 표시할 수 없습니다.");
                            document.getElementById('error').style.display = 'flex';
                            return;
                        }
                        
                        map = new google.maps.Map(document.getElementById("map"), {
                            zoom: 14,
                            center: destination,
                            disableDefaultUI: false,
                            zoomControl: true,
                            mapTypeControl: false,
                            streetViewControl: false,
                            fullscreenControl: false
                        });
                        mapInitialized = true;
                        
                        // 지도 로드 확인
                        sendToiOS("직선 경로 지도 초기화됨");
                    }
                    
                    // 직선 경로 그리기
                    const lineCoordinates = [userLocation, destination];
                    const line = new google.maps.Polyline({
                        path: lineCoordinates,
                        geodesic: true,
                        strokeColor: '#FF6D00',
                        strokeOpacity: 1.0,
                        strokeWeight: 4
                    });
                    
                    line.setMap(map);
                    
                    // 마커 추가
                    const marker = new google.maps.Marker({
                        position: destination,
                        map: map,
                        title: "\(destinationName)",
                        animation: google.maps.Animation.DROP
                    });
                    
                    const startMarker = new google.maps.Marker({
                        position: userLocation,
                        map: map,
                        title: "현재 위치",
                        icon: {
                            path: google.maps.SymbolPath.CIRCLE,
                            fillColor: '#4285F4',
                            fillOpacity: 1,
                            strokeColor: '#FFFFFF',
                            strokeWeight: 2,
                            scale: 8
                        }
                    });
                    
                    // 두 지점이 모두 보이도록 카메라 조정
                    const bounds = new google.maps.LatLngBounds();
                    bounds.extend(userLocation);
                    bounds.extend(destination);
                    map.fitBounds(bounds);
                    
                    // 직선 거리 계산
                    const distance = google.maps.geometry.spherical.computeDistanceBetween(
                        new google.maps.LatLng(userLocation.lat, userLocation.lng),
                        new google.maps.LatLng(destination.lat, destination.lng)
                    );
                    
                    // 도보 속도 (약 5km/h = 1.4m/s)
                    const walkingSpeed = 1.4; // 초당 미터
                    const timeInSeconds = distance / walkingSpeed;
                    const minutes = Math.floor(timeInSeconds / 60);
                    
                    // 거리 포맷팅
                    let distanceText;
                    if (distance < 1000) {
                        distanceText = Math.round(distance) + 'm';
                    } else {
                        distanceText = (distance / 1000).toFixed(1) + 'km';
                    }
                    
                    // 정보창 대신 상단 패널에 정보 표시
                    const infoPanel = document.getElementById("infoPanel");
                    infoPanel.innerHTML = `<b>거리:</b> ${distanceText} <b>예상:</b> 약 ${minutes}분`;
                    infoPanel.style.display = "block";
                    
                    // 지도 강제 리사이즈 (렌더링 문제 해결)
                    setTimeout(() => {
                        google.maps.event.trigger(map, 'resize');
                        map.fitBounds(bounds);
                        
                        // 지도 요소 디버깅
                        const mapElement = document.getElementById('map');
                        sendToiOS(`지도 요소 크기: ${mapElement.offsetWidth}x${mapElement.offsetHeight}`);
                    }, 500);
                    
                    sendToiOS("직선 경로 표시 완료");
                } catch (e) {
                    console.error("직선 경로 표시 오류:", e.message);
                    document.getElementById('error').style.display = 'flex';
                }
            }
            
            // 오류 표시
            function showError() {
                document.getElementById('loading').style.display = 'none';
                document.getElementById('error').style.display = 'flex';
                setTimeout(showStraightRoute, 1500);
            }
            
            // 지도 초기화
            function initMap() {
                try {
                    sendToiOS("지도 초기화 시작");
                    
                    const userLocation = { lat: \(userLatitude), lng: \(userLongitude) };
                    const destination = { lat: \(destinationLatitude), lng: \(destinationLongitude) };
                    
                    // 좌표 유효성 검사
                    if (isNaN(userLocation.lat) || isNaN(userLocation.lng) || 
                        isNaN(destination.lat) || isNaN(destination.lng)) {
                        sendToiOS("ERROR: 유효하지 않은 좌표 값");
                        showStraightRoute();
                        return;
                    }
                    
                    // 지도 요소 디버깅
                    const mapElement = document.getElementById('map');
                    sendToiOS(`지도 초기화 전 요소 크기: ${mapElement.offsetWidth}x${mapElement.offsetHeight}`);
                    
                    // 지도 초기화 - 스타일 단순화
                    map = new google.maps.Map(document.getElementById("map"), {
                        zoom: 15,
                        center: destination,
                        disableDefaultUI: false,
                        zoomControl: true,
                        mapTypeControl: false,
                        streetViewControl: false,
                        fullscreenControl: false
                    });
                    
                    mapInitialized = true;
                    sendToiOS("지도 객체 생성됨");
                    
                    // 경로 서비스 및 렌더러 초기화
                    directionsService = new google.maps.DirectionsService();
                    directionsRenderer = new google.maps.DirectionsRenderer({
                        map: map,
                        suppressMarkers: true,  // 기본 마커 표시 안 함
                        polylineOptions: {
                            strokeColor: '#4285F4',
                            strokeWeight: 5
                        }
                    });
                    
                    // 목적지 마커 추가
                    const marker = new google.maps.Marker({
                        position: destination,
                        map: map,
                        title: "\(destinationName)",
                        animation: google.maps.Animation.DROP
                    });
                    
                    // 경로 요청
                    if (Math.abs(userLocation.lat) < 0.001 && Math.abs(userLocation.lng) < 0.001) {
                        sendToiOS("유효하지 않은 사용자 위치: " + JSON.stringify(userLocation));
                        showStraightRoute();
                        return;
                    }
                    
                    const request = {
                        origin: userLocation,
                        destination: destination,
                        travelMode: 'WALKING'
                    };
                    
                    sendToiOS("경로 요청 시작: " + JSON.stringify(request));
                    
                    directionsService.route(request, function(response, status) {
                        if (status === 'OK') {
                            document.getElementById('loading').style.display = 'none';
                            
                            directionsRenderer.setDirections(response);
                            
                            // 경로 정보 표시
                            const route = response.routes[0];
                            const leg = route.legs[0];
                            const distance = leg.distance.text;
                            const duration = leg.duration.text;
                            
                            // 사용자 위치에 A 마커 추가
                            const startMarker = new google.maps.Marker({
                                position: userLocation,
                                map: map,
                                title: "현재 위치",
                                icon: {
                                    path: google.maps.SymbolPath.CIRCLE,
                                    fillColor: '#4285F4',
                                    fillOpacity: 1,
                                    strokeColor: '#FFFFFF',
                                    strokeWeight: 2,
                                    scale: 8
                                }
                            });
                            
                            sendToiOS(`경로 계산 성공: 거리 ${distance}, 소요 시간 ${duration}`);
                            
                            // 정보창 대신 상단 패널에 정보 표시
                            const infoPanel = document.getElementById("infoPanel");
                            infoPanel.innerHTML = `<b>거리:</b> ${distance} <b>소요:</b> ${duration}`;
                            infoPanel.style.display = "block";
                            
                            // 지도 강제 리사이즈 (렌더링 문제 해결)
                            setTimeout(() => {
                                google.maps.event.trigger(map, 'resize');
                                const bounds = new google.maps.LatLngBounds();
                                route.legs[0].steps.forEach(step => {
                                    bounds.extend(step.start_location);
                                });
                                bounds.extend(destination);
                                map.fitBounds(bounds);
                                
                                // 지도 요소 디버깅
                                const mapElement = document.getElementById('map');
                                sendToiOS(`지도 요소 최종 크기: ${mapElement.offsetWidth}x${mapElement.offsetHeight}`);
                                sendToiOS(`지도 타일 로드 상태: ${map.getTilt ? "로드됨" : "로드안됨"}`);
                            }, 500);
                        } else {
                            sendToiOS("경로 계산 실패: " + status);
                            showStraightRoute();
                        }
                    });
                } catch (e) {
                    console.error("지도 초기화 오류:", e.message);
                    showStraightRoute();
                }
            }
            
            // 1초 후 Maps API 로드 여부 확인
            setTimeout(function() {
                if (typeof google === 'undefined' || typeof google.maps === 'undefined') {
                    sendToiOS("ERROR: Google Maps API 로드 실패");
                    showError();
                } else {
                    sendToiOS("Google Maps API 로드 완료");
                    
                    // DOM 디버깅
                    const mapElement = document.getElementById('map');
                    sendToiOS(`초기 지도 요소 크기: ${mapElement.offsetWidth}x${mapElement.offsetHeight}`);
                    
                    if (!mapInitialized && typeof initMap === 'function') {
                        sendToiOS("1초 후 initMap 수동 호출");
                        initMap();
                    }
                }
            }, 1000);
            </script>
            <script src="https://maps.googleapis.com/maps/api/js?key=\(apiKey)&libraries=geometry&callback=initMap" async defer onerror="console.error('Google Maps API 로딩 오류 발생')"></script>
        </body>
        </html>
        """
        
        webView.loadHTMLString(htmlContent, baseURL: nil)
    }
}

#Preview {
    // 미리보기용 샘플 데이터
    let previewRestaurant = HotPepperRestaurant(
        id: "preview_id",
        name: "오이시 이자카야",
        logoImage: nil,
        nameKana: "オイシイザカヤ",
        address: "도쿄 신주쿠 2-5-1",
        stationName: "신주쿠역",
        ktaiCoupon: 0,
        largeServiceArea: nil,
        serviceArea: nil,
        largeArea: nil,
        middleArea: nil,
        smallArea: nil,
        lat: 35.689722,
        lng: 139.692222,
        genre: Genre(code: "G001", name: "이자카야", catchPhrase: "맛있는 일본 술과 안주"),
        subGenre: nil,
        budget: Budget(code: "B001", name: "2,000엔 ~ 3,000엔", average: "2500"),
        budgetMemo: "1인당 평균 2,500엔",
        catchPhrase: "신선한 해산물과 다양한 사케를 즐길 수 있는 전통 이자카야",
        capacity: 50,
        access: "신주쿠역 동쪽 출구에서 도보 5분",
        mobileAccess: "신주쿠역에서 도보 5분",
        urls: URLS(pc: "https://www.hotpepper.jp", mobile: "https://m.hotpepper.jp"),
        photo: Photo(
            pc: PC(l: "https://imgfp.hotp.jp/IMGH/30/31/P038183031/P038183031_480.jpg", m: nil, s: nil),
            mobile: nil
        ),
        open: "17:00",
        close: "23:30",
        wifi: "있음",
        wedding: "가능",
        course: "있음",
        freeDrink: "있음",
        freeFood: "없음",
        privateRoom: "있음",
        horigotatsu: "없음",
        tatami: "있음",
        card: "가능",
        nonSmoking: "일부 금연석 있음",
        charter: "가능",
        parking: "있음",
        barrierFree: "있음",
        otherMemo: "",
        sommelier: "없음",
        openAir: "있음",
        show: "없음",
        karaoke: "없음",
        band: "없음",
        tv: "있음",
        english: "가능",
        pet: "불가",
        child: "환영"
    )
    
    return NavigationView {
        RestaurantDetailView(restaurant: previewRestaurant)
    }
} 