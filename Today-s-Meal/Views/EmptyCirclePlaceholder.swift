import SwiftUI

struct EmptyCirclePlaceholder: View {
    let label: String
    let useCustomImage: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            // 원형 배경
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.2))
                    .frame(width: 60, height: 60)
                
                if useCustomImage {
                    // 에셋에서 이미지 로드 시도
                    if let uiImage = UIImage(named: label) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 60, height: 60)
                            .clipShape(Circle())
                    } else {
                        // 이미지를 찾을 수 없는 경우
                        VStack {
                            Text("!")
                                .font(.system(size: 20))
                                .foregroundColor(.red)
                            Text("이미지 없음")
                                .font(.system(size: 8))
                                .foregroundColor(.red)
                        }
                        .onAppear {
                            print("⚠️ 이미지를 찾을 수 없음: \(label)")
                        }
                    }
                } else {
                    // 기본 텍스트 표시
                    Text("+")
                        .font(.system(size: 20))
                        .foregroundColor(.gray.opacity(0.7))
                }
            }
            
            // 카테고리 이름
            Text(label == "izakaya" ? "居酒屋" : label)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.gray)
        }
        .frame(width: 80, height: 80)
    }
}

#Preview {
    HStack {
        EmptyCirclePlaceholder(label: "izakaya", useCustomImage: false)
        EmptyCirclePlaceholder(label: "izakaya", useCustomImage: true)
    }
    .padding()
    .background(Color.black)
} 