import SwiftUI

struct EmptyCirclePlaceholder: View {
    let label: String
    let useCustomImage: Bool
    
    // 이자카야 테스트 이미지 - 원형 오렌지색 배경
    private let testImageData = Data(base64Encoded: "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")!
    
    var body: some View {
        VStack(spacing: 8) {
            // 원형 배경
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.2))
                    .frame(width: 60, height: 60)
                
                if useCustomImage && label == "izakaya" {
                    // 코드에 내장된 이미지 사용 (이자카야만)
                    if let uiImage = UIImage(data: testImageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 60, height: 60)
                            .clipShape(Circle())
                    }
                } else if useCustomImage {
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