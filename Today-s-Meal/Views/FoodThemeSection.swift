import SwiftUI

// 음식 테마 섹션
struct FoodThemeSection: View {
    @Binding var selectedTheme: String?
    @EnvironmentObject var locationService: LocationService
    let searchRadius: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 제목 및 설명
            Text("음식 테마")
                .font(.headline)
            
            Text(selectedTheme == nil ? "원하는 음식 테마를 선택하세요" : "선택된 테마: \(selectedTheme == "izakaya" ? "居酒屋" : selectedTheme ?? "")")
                .font(.caption)
                .foregroundColor(selectedTheme == nil ? .gray : .orange)
                .padding(.bottom, 8)
            
            // 선택된 테마가 있으면 해당 테마만 표시, 없으면 모든 테마 표시
            if let theme = selectedTheme {
                // 선택된 테마만 표시
                HStack {
                    // 해당 테마 원형만 표시
                    let label = theme
                    let useCustomImage = theme == "izakaya"
                    
                    EmptyCirclePlaceholder(
                        label: label,
                        useCustomImage: useCustomImage,
                        isSelected: true
                    ) {
                        // 다시 누르면 선택 해제
                        selectedTheme = nil
                    }
                    
                    Spacer()
                }
                .padding(.bottom, 12)
            } else {
                // 첫 번째 줄 (1-4)
                HStack(spacing: 12) {
                    // 이자카야 이미지 사용
                    EmptyCirclePlaceholder(
                        label: "izakaya", 
                        useCustomImage: true,
                        isSelected: selectedTheme == "izakaya"
                    ) {
                        selectedTheme = selectedTheme == "izakaya" ? nil : "izakaya"
                    }
                    
                    EmptyCirclePlaceholder(
                        label: "ダイニングバー・バル", 
                        useCustomImage: true,
                        isSelected: selectedTheme == "ダイニングバー・バル"
                    ) {
                        selectedTheme = selectedTheme == "ダイニングバー・バル" ? nil : "ダイニングバー・バル"
                    }
                    
                    EmptyCirclePlaceholder(
                        label: "創作料理", 
                        useCustomImage: true,
                        isSelected: selectedTheme == "創作料理"
                    ) {
                        selectedTheme = selectedTheme == "創作料理" ? nil : "創作料理"
                    }
                    
                    EmptyCirclePlaceholder(
                        label: "和食", 
                        useCustomImage: true,
                        isSelected: selectedTheme == "和食"
                    ) {
                        selectedTheme = selectedTheme == "和食" ? nil : "和食"
                    }
                }
                .padding(.bottom, 12)
                
                // 두 번째 줄 (5-8)
                HStack(spacing: 12) {
                    EmptyCirclePlaceholder(
                        label: "洋食", 
                        useCustomImage: true,
                        isSelected: selectedTheme == "洋食"
                    ) {
                        selectedTheme = selectedTheme == "洋食" ? nil : "洋食"
                    }
                    
                    EmptyCirclePlaceholder(
                        label: "イタリアン・フレンチ", 
                        useCustomImage: true,
                        isSelected: selectedTheme == "イタリアン・フレンチ"
                    ) {
                        selectedTheme = selectedTheme == "イタリアン・フレンチ" ? nil : "イタリアン・フレンチ"
                    }
                    
                    EmptyCirclePlaceholder(
                        label: "中華", 
                        useCustomImage: true,
                        isSelected: selectedTheme == "中華"
                    ) {
                        selectedTheme = selectedTheme == "中華" ? nil : "中華"
                    }
                    
                    EmptyCirclePlaceholder(
                        label: "焼肉・ホルモン", 
                        useCustomImage: true,
                        isSelected: selectedTheme == "焼肉・ホルモン"
                    ) {
                        selectedTheme = selectedTheme == "焼肉・ホルモン" ? nil : "焼肉・ホルモン"
                    }
                }
                .padding(.bottom, 12)
                
                // 세 번째 줄 (9-12)
                HStack(spacing: 12) {
                    EmptyCirclePlaceholder(
                        label: "韓国料理", 
                        useCustomImage: true,
                        isSelected: selectedTheme == "韓国料理"
                    ) {
                        selectedTheme = selectedTheme == "韓国料理" ? nil : "韓国料理"
                    }
                    
                    EmptyCirclePlaceholder(
                        label: "アジア・エスニック料理", 
                        useCustomImage: true,
                        isSelected: selectedTheme == "アジア・エスニック料理"
                    ) {
                        selectedTheme = selectedTheme == "アジア・エスニック料理" ? nil : "アジア・エスニック料理"
                    }
                    
                    EmptyCirclePlaceholder(
                        label: "各国料理", 
                        useCustomImage: true,
                        isSelected: selectedTheme == "各国料理"
                    ) {
                        selectedTheme = selectedTheme == "各国料理" ? nil : "各国料理"
                    }
                    
                    EmptyCirclePlaceholder(
                        label: "カラオケ・パーティ", 
                        useCustomImage: true,
                        isSelected: selectedTheme == "カラオケ・パーティ"
                    ) {
                        selectedTheme = selectedTheme == "カラオケ・パーティ" ? nil : "カラオケ・パーティ"
                    }
                }
                .padding(.bottom, 12)
                
                // 네 번째 줄 (13-16)
                HStack(spacing: 12) {
                    EmptyCirclePlaceholder(
                        label: "バー・カクテル", 
                        useCustomImage: true,
                        isSelected: selectedTheme == "バー・カクテル"
                    ) {
                        selectedTheme = selectedTheme == "バー・カクテル" ? nil : "バー・カクテル"
                    }
                    
                    EmptyCirclePlaceholder(
                        label: "ラーメン", 
                        useCustomImage: true,
                        isSelected: selectedTheme == "ラーメン"
                    ) {
                        selectedTheme = selectedTheme == "ラーメン" ? nil : "ラーメン"
                    }
                    
                    EmptyCirclePlaceholder(
                        label: "お好み焼き・もんじゃ", 
                        useCustomImage: true,
                        isSelected: selectedTheme == "お好み焼き・もんじゃ"
                    ) {
                        selectedTheme = selectedTheme == "お好み焼き・もんじゃ" ? nil : "お好み焼き・もんじゃ"
                    }
                    
                    EmptyCirclePlaceholder(
                        label: "カフェ・スイーツ", 
                        useCustomImage: true,
                        isSelected: selectedTheme == "カフェ・スイーツ"
                    ) {
                        selectedTheme = selectedTheme == "カフェ・スイーツ" ? nil : "カフェ・スイーツ"
                    }
                }
                .padding(.bottom, 12)
                
                // 다섯 번째 줄 (17)
                HStack(spacing: 12) {
                    EmptyCirclePlaceholder(
                        label: "その他グルメ", 
                        useCustomImage: true,
                        isSelected: selectedTheme == "その他グルメ"
                    ) {
                        selectedTheme = selectedTheme == "その他グルメ" ? nil : "その他グルメ"
                    }
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
        }
        .padding(.horizontal)
        .padding(.top, 16)
    }
} 