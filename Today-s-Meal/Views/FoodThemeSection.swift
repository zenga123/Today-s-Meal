import SwiftUI

// 음식 테마 섹션
struct FoodThemeSection: View {
    @Binding var selectedTheme: String?
    
    var body: some View {
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
                // 특별 처리된 이자카야 컴포넌트
                IzakayaCircle()
                
                EmptyCirclePlaceholder(label: "ダイニングバー・バル", useCustomImage: false)
                EmptyCirclePlaceholder(label: "創作料理", useCustomImage: false)
                EmptyCirclePlaceholder(label: "和食", useCustomImage: false)
            }
            .padding(.bottom, 12)
            
            // 두 번째 줄 (5-8)
            HStack(spacing: 12) {
                EmptyCirclePlaceholder(label: "洋食", useCustomImage: false)
                EmptyCirclePlaceholder(label: "イタリアン・フレンチ", useCustomImage: false)
                EmptyCirclePlaceholder(label: "中華", useCustomImage: false)
                EmptyCirclePlaceholder(label: "焼肉・ホルモン", useCustomImage: false)
            }
            .padding(.bottom, 12)
            
            // 세 번째 줄 (9-12)
            HStack(spacing: 12) {
                EmptyCirclePlaceholder(label: "韓国料理", useCustomImage: false)
                EmptyCirclePlaceholder(label: "アジア・エスニック料理", useCustomImage: false)
                EmptyCirclePlaceholder(label: "各国料理", useCustomImage: false)
                EmptyCirclePlaceholder(label: "カラオケ・パーティ", useCustomImage: false)
            }
            .padding(.bottom, 12)
            
            // 네 번째 줄 (13-16)
            HStack(spacing: 12) {
                EmptyCirclePlaceholder(label: "バー・カクテル", useCustomImage: false)
                EmptyCirclePlaceholder(label: "ラーメン", useCustomImage: false)
                EmptyCirclePlaceholder(label: "お好み焼き・もんじゃ", useCustomImage: false)
                EmptyCirclePlaceholder(label: "カフェ・スイーツ", useCustomImage: false)
            }
            .padding(.bottom, 12)
            
            // 다섯 번째 줄 (17)
            HStack(spacing: 12) {
                EmptyCirclePlaceholder(label: "その他グルメ", useCustomImage: false)
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
    }
} 