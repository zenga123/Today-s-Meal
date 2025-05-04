import SwiftUI

struct RestaurantRow: View {
    let restaurant: Today_s_Meal.Restaurant
    let distance: Double
    @State private var showingDetail = false
    
    var body: some View {
        NavigationLink(destination: RestaurantDetailView(restaurant: convertToHotPepperRestaurant())) {
            HStack(alignment: .top, spacing: 12) {
                // 레스토랑 썸네일 (기본 아이콘 또는 이미지)
                ZStack {
                    Circle()
                        .fill(Color.orange.opacity(0.3))
                        .frame(width: 60, height: 60)
                    
                    if let imageUrl = restaurant.imageUrl, !imageUrl.isEmpty {
                        AsyncImage(url: URL(string: imageUrl)) { phase in
                            if let image = phase.image {
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 60, height: 60)
                                    .clipShape(Circle())
                            } else if phase.error != nil {
                                Image(systemName: "fork.knife")
                                    .font(.system(size: 24))
                                    .foregroundColor(.orange)
                            } else {
                                ProgressView()
                            }
                        }
                    } else {
                        Image(systemName: "fork.knife")
                            .font(.system(size: 24))
                            .foregroundColor(.orange)
                    }
                }
                .frame(width: 60)
                
                // 레스토랑 정보
                VStack(alignment: .leading, spacing: 4) {
                    Text(restaurant.name)
                        .font(.headline)
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    // 평점, 리뷰 수, 카테고리
                    HStack {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                            .font(.caption)
                        
                        Text(String(format: "%.1f", restaurant.rating))
                            .foregroundColor(.gray)
                            .font(.caption)
                        
                        Text("(\(restaurant.reviewCount))")
                            .foregroundColor(.gray)
                            .font(.caption)
                        
                        Text("•")
                            .foregroundColor(.gray)
                            .font(.caption)
                        
                        Text(restaurant.category)
                            .foregroundColor(.gray)
                            .font(.caption)
                            .lineLimit(1)
                    }
                    
                    // 주소
                    Text(restaurant.address)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .lineLimit(1)
                    
                    // 오시는 길 정보 추가
                    if let access = restaurant.access, !access.isEmpty {
                        VStack(alignment: .leading, spacing: 0) {
                            Text("🚶‍♂️ \(access)")
                                .font(.caption)
                                .foregroundColor(.gray.opacity(0.8))
                                .lineLimit(5)  // 최대 5줄까지 허용
                                .multilineTextAlignment(.leading)  // 텍스트 자체를 왼쪽 정렬
                        }
                        .padding(.vertical, 2)
                    }
                    
                    // 거리
                    Text("\(formattedDistance(distance)) 거리")
                        .font(.caption)
                        .foregroundColor(.green)
                }
                .frame(maxWidth: .infinity, alignment: .leading)  // VStack 전체를 왼쪽 정렬
                
                Spacer(minLength: 0)  // 공간을 최소화하여 콘텐츠에 더 많은 공간 할당
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
        }
    }
    
    private func formattedDistance(_ meters: Double) -> String {
        if meters < 1000 {
            return "\(Int(meters))m"
        } else {
            let km = meters / 1000
            return String(format: "%.1fkm", km)
        }
    }
    
    // Restaurant 객체를 HotPepperRestaurant로 변환
    private func convertToHotPepperRestaurant() -> HotPepperRestaurant {
        // 현재 Restaurant는 간소화된 정보를 가지고 있고, DetailView는 더 자세한 정보가 필요합니다
        // 따라서 제한된 정보만 전달하고, 나머지는 API에서 가져온 실제 데이터를 사용합니다
        
        return HotPepperRestaurant(
            id: restaurant.id,
            name: restaurant.name,
            logoImage: nil,
            nameKana: nil,
            address: restaurant.address,
            stationName: nil,
            ktaiCoupon: 0,
            largeServiceArea: nil,
            serviceArea: nil,
            largeArea: nil,
            middleArea: nil,
            smallArea: nil,
            lat: restaurant.latitude,
            lng: restaurant.longitude,
            genre: Genre(code: "G001", name: restaurant.category, catchPhrase: nil),
            subGenre: nil,
            budget: nil,
            budgetMemo: nil,
            catchPhrase: nil,
            capacity: 0,
            access: restaurant.access,  // access 필드 추가
            mobileAccess: nil,
            urls: URLS(pc: nil, mobile: nil),
            photo: Photo(
                pc: PC(l: restaurant.imageUrl, m: nil, s: nil),
                mobile: nil
            ),
            open: nil,     // API에서 가져온 실제 데이터 사용
            close: nil,    // API에서 가져온 실제 데이터 사용
            wifi: nil,     // API에서 가져온 실제 데이터 사용
            wedding: nil,
            course: nil,
            freeDrink: nil,
            freeFood: nil,
            privateRoom: nil,
            horigotatsu: nil,
            tatami: nil,
            card: nil,     // API에서 가져온 실제 데이터 사용
            nonSmoking: nil,
            charter: nil,
            parking: nil,  // API에서 가져온 실제 데이터 사용
            barrierFree: nil,
            otherMemo: nil,
            sommelier: nil,
            openAir: nil,
            show: nil,
            karaoke: nil,
            band: nil,
            tv: nil,
            english: nil,
            pet: nil,
            child: nil
        )
    }
}

#Preview {
    RestaurantRow(
        restaurant: Today_s_Meal.Restaurant(
            id: "1",
            name: "오이시 이자카야",
            address: "도쿄 신주쿠 2-5-1",
            rating: 4.5,
            reviewCount: 120,
            category: "居酒屋",
            latitude: 35.6895,
            longitude: 139.6917,
            imageUrl: nil,
            access: "신주쿠역 동쪽 출구에서 도보 5분"  // 오시는 길 정보 추가
        ),
        distance: 350
    )
    .background(Color.black)
} 