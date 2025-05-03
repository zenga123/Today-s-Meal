import SwiftUI

struct RestaurantRow: View {
    let restaurant: Today_s_Meal.Restaurant
    let distance: Double
    
    var body: some View {
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
                
                // 거리
                Text("\(formattedDistance(distance)) 거리")
                    .font(.caption)
                    .foregroundColor(.green)
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
    }
    
    private func formattedDistance(_ meters: Double) -> String {
        if meters < 1000 {
            return "\(Int(meters))m"
        } else {
            let km = meters / 1000
            return String(format: "%.1fkm", km)
        }
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
            imageUrl: nil
        ),
        distance: 350
    )
    .background(Color.black)
} 