import SwiftUI
import MapKit

struct RestaurantDetailView: View {
    let restaurant: HotPepperRestaurant
    @Environment(\.presentationMode) var presentationMode
    @State private var showMap = false
    @State private var detailedRestaurant: HotPepperRestaurant?
    @State private var isLoading = true
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if isLoading {
                    loadingView
                } else {
                    // 헤더 이미지
                    headerImageSection
                    
                    // 식당 이름 및 기본 정보
                    restaurantInfoSection
                    
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
        .sheet(isPresented: $showMap) {
            RestaurantMapView(restaurant: detailedRestaurant ?? restaurant)
        }
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
            
            Text("상세 정보를 불러오는 중...")
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
                Text("뒤로")
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
    
    // 식당 정보 섹션
    private var restaurantInfoSection: some View {
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
            
            // 지도 보기 버튼
            Button(action: {
                showMap = true
            }) {
                HStack {
                    Image(systemName: "map")
                    Text("지도에서 보기")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
                .padding(.top, 8)
            }
        }
    }
    
    // 영업시간 및 주소 섹션
    private var businessInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("영업 정보")
                .font(.headline)
                .foregroundColor(.white)
            
            // 영업시간
            HStack(alignment: .top) {
                Image(systemName: "clock")
                    .foregroundColor(.gray)
                    .frame(width: 24)
                
                VStack(alignment: .leading) {
                    Text("영업시간")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    if let open = currentRestaurant.open, let close = currentRestaurant.close {
                        Text("\(open) - \(close)")
                            .foregroundColor(.white)
                    } else {
                        Text("정보 없음")
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
                    Text("주소")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    if let address = currentRestaurant.address {
                        Text(address)
                            .foregroundColor(.white)
                    } else {
                        Text("정보 없음")
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
                    Text("접근 방법")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    if let access = currentRestaurant.access {
                        Text(access)
                            .foregroundColor(.white)
                    } else {
                        Text("정보 없음")
                            .foregroundColor(.gray)
                    }
                }
            }
        }
    }
    
    // 식당 특징 섹션
    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("식당 특징")
                .font(.headline)
                .foregroundColor(.white)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                // Wi-Fi
                featureItem(icon: "wifi", title: "Wi-Fi", available: currentRestaurant.wifi == "あり" || currentRestaurant.wifi == "있음")
                
                // 주차
                featureItem(icon: "car", title: "주차", available: currentRestaurant.parking == "あり" || currentRestaurant.parking == "있음")
                
                // 카드 결제
                featureItem(icon: "creditcard", title: "카드 결제", available: currentRestaurant.card == "利用可" || currentRestaurant.card == "가능")
                
                // 금연
                featureItem(icon: "nosign", title: "금연석", available: currentRestaurant.nonSmoking?.contains("禁煙") ?? false || currentRestaurant.nonSmoking?.contains("금연") ?? false)
                
                // 개인룸
                featureItem(icon: "door.right.hand.closed", title: "개인룸", available: currentRestaurant.privateRoom == "あり" || currentRestaurant.privateRoom == "있음")
                
                // 영어 서비스
                featureItem(icon: "person.wave.2", title: "영어 가능", available: currentRestaurant.english == "あり" || currentRestaurant.english == "가능")
            }
        }
    }
    
    // 외부 링크 섹션
    private var linksSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("외부 링크")
                .font(.headline)
                .foregroundColor(.white)
            
            if let pcUrl = currentRestaurant.urls?.pc, !pcUrl.isEmpty {
                Link(destination: URL(string: pcUrl) ?? URL(string: "https://www.hotpepper.jp")!) {
                    HStack {
                        Image(systemName: "globe")
                        Text("공식 웹사이트 방문하기")
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
                        Text("모바일 사이트 방문하기")
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
            
            Text(available ? "있음" : "없음")
                .foregroundColor(available ? .green : .gray)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color.gray.opacity(0.2))
        .cornerRadius(8)
    }
}

// 지도 보기 뷰
struct RestaurantMapView: View {
    let restaurant: HotPepperRestaurant
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            // 지도
            Map(initialPosition: .region(region)) {
                Marker(restaurant.name, coordinate: CLLocationCoordinate2D(latitude: restaurant.lat, longitude: restaurant.lng))
                    .tint(.red)
            }
            .ignoresSafeArea()
            
            // 닫기 버튼
            Button(action: {
                presentationMode.wrappedValue.dismiss()
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title)
                    .foregroundColor(.white)
                    .shadow(radius: 2)
                    .padding()
                    .background(Color.black.opacity(0.3))
                    .clipShape(Circle())
            }
            .padding()
        }
    }
    
    // 지도 영역 정의
    private var region: MKCoordinateRegion {
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: restaurant.lat, longitude: restaurant.lng),
            span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
        )
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