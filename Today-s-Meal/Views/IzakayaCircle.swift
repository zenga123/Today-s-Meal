import SwiftUI

/// 이자카야 이미지를 위한 특별 컴포넌트
struct IzakayaCircle: View {
    var body: some View {
        VStack(spacing: 8) {
            // Assets에서 이미지 사용
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.2))
                    .frame(width: 60, height: 60)
                
                // Assets의 izakaya 이미지 사용
                Image("izakaya")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 60, height: 60)
                    .clipShape(Circle())
            }
            
            // 카테고리 이름
            Text("居酒屋")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.gray)
        }
        .frame(width: 80, height: 80)
    }
}

/// 미리보기
#Preview {
    IzakayaCircle()
        .padding()
        .background(Color.black)
} 