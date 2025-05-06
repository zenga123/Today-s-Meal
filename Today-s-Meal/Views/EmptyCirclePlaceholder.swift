import SwiftUI

struct EmptyCirclePlaceholder: View {
    let label: String
    let useCustomImage: Bool
    var isSelected: Bool = false
    var onTap: () -> Void = {}
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                // 원형 배경
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.orange.opacity(0.6) : Color.orange.opacity(0.2))
                        .frame(width: 60, height: 60)
                    
                    if useCustomImage {
                        // 이자카야인 경우 추가한 이미지 사용
                        if label == "izakaya" {
                            Image("izakaya")
                                .resizable()
                                .scaledToFill()
                                .frame(width: 60, height: 60)
                                .clipShape(Circle())
                                .overlay(
                                    Circle()
                                        .stroke(isSelected ? Color.orange : Color.clear, lineWidth: 1.5)
                                )
                                .onAppear {
                                    print("✅ 이자카야 이미지 로드 시도")
                                }
                        } else {
                            // 다른 이미지 로드 시도
                            let image = Image(label)
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width: 60, height: 60)
                                .clipShape(Circle())
                                .overlay(
                                    Circle()
                                        .stroke(isSelected ? Color.orange : Color.clear, lineWidth: 1.5)
                                )
                        }
                        
                    } else {
                        // 기본 텍스트 표시
                        Text("+")
                            .font(.system(size: 20))
                            .foregroundColor(.gray.opacity(0.7))
                    }
                    
                    // 선택 표시 테두리 - 이미지가 없을 때만 표시
                    if isSelected && !useCustomImage {
                        Circle()
                            .stroke(Color.orange, lineWidth: 1.5)
                            .frame(width: 64, height: 64)
                    }
                }
                
                // 카테고리 이름
                Text(label == "izakaya" ? "居酒屋" : label)
                    .font(.caption)
                    .fontWeight(isSelected ? .bold : .medium)
                    .foregroundColor(isSelected ? .orange : .gray)
                    .multilineTextAlignment(.center)
                    .frame(width: 80)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineLimit(2)
            }
            .frame(width: 80, height: 100)
        }
        .buttonStyle(PlainButtonStyle()) // 버튼 스타일 제거
    }
}

#Preview {
    HStack {
        EmptyCirclePlaceholder(label: "izakaya", useCustomImage: false)
        EmptyCirclePlaceholder(label: "izakaya", useCustomImage: true)
        EmptyCirclePlaceholder(label: "izakaya", useCustomImage: true, isSelected: true)
    }
    .padding()
    .background(Color.black)
} 