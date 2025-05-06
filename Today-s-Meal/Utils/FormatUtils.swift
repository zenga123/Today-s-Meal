import Foundation
import CoreLocation

// 앱 전체에서 사용되는 포맷팅 유틸리티 함수들
enum FormatUtils {
    // 미터 거리를 사용자 친화적인 포맷으로 변환 (1km 미만은 m, 이상은 km)
    static func formatDistance(_ meters: Double) -> String {
        if meters < 1000 {
            return "\(Int(meters))m"
        } else {
            let km = meters / 1000
            return String(format: "%.1fkm", km)
        }
    }
    
    // 검색 반경 텍스트 포맷팅 (일본어)
    static func formatSearchRadius(_ radius: Double) -> String {
        if radius >= 1000 {
            // 정확히 3000m일 때는 3.0km로 표시
            if radius == 3000 {
                return "範囲: 3.0 km"
            } else {
                let kmRadius = radius / 1000.0
                return String(format: "範囲: %.1f km", kmRadius)
            }
        } else {
            return String(format: "範囲: %d m", Int(radius))
        }
    }
    
    // 날짜/시간 포맷팅
    static func formatDate(_ date: Date, format: String = "yyyy-MM-dd") -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        return formatter.string(from: date)
    }
} 