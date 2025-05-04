import SwiftUI

struct ImageTestView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("이미지 테스트")
                    .font(.title)
                    .bold()
                
                // 방법 1: Image 직접 사용 (권장 방식)
                Group {
                    Text("1. Image() 직접 사용").font(.headline)
                    
                    HStack(spacing: 20) {
                        VStack {
                            Image("izakaya")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 100, height: 100)
                            Text("izakaya").font(.caption)
                        }
                        
                        VStack {
                            Image("SimpleBaru")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 100, height: 100)
                            Text("SimpleBaru").font(.caption)
                        }
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                
                // 방법 2: UIImage 사용 후 변환
                Group {
                    Text("2. UIImage() 사용 후 변환").font(.headline)
                    
                    HStack(spacing: 20) {
                        VStack {
                            if let uiImage = UIImage(named: "izakaya") {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 100, height: 100)
                                Text("izakaya - 성공").font(.caption).foregroundColor(.green)
                            } else {
                                Text("izakaya - 실패").font(.caption).foregroundColor(.red)
                            }
                        }
                        
                        VStack {
                            if let uiImage = UIImage(named: "SimpleBaru") {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 100, height: 100)
                                Text("SimpleBaru - 성공").font(.caption).foregroundColor(.green)
                            } else {
                                Text("SimpleBaru - 실패").font(.caption).foregroundColor(.red)
                            }
                        }
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                
                // 파일 이름으로 직접 시도
                Group {
                    Text("3. 다양한 파일명 시도").font(.headline)
                    
                    HStack(spacing: 20) {
                        VStack {
                            if let uiImage = UIImage(named: "ija") {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 100, height: 100)
                                Text("ija - 성공").font(.caption).foregroundColor(.green)
                            } else {
                                Text("ija - 실패").font(.caption).foregroundColor(.red)
                            }
                        }
                        
                        VStack {
                            if let uiImage = UIImage(named: "baru") {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 100, height: 100)
                                Text("baru - 성공").font(.caption).foregroundColor(.green)
                            } else {
                                Text("baru - 실패").font(.caption).foregroundColor(.red)
                            }
                        }
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                
                // 새 이미지 테스트
                Group {
                    Text("4. 새 이미지 테스트").font(.headline)
                    
                    HStack(spacing: 20) {
                        VStack {
                            Image("SimpleBaru")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 100, height: 100)
                            Text("SimpleBaru").font(.caption)
                        }
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                
                // 사용 가능한 모든 이미지 파일 정보
                VStack(alignment: .leading) {
                    Text("이미지 디버그 정보:").font(.headline)
                    Text("Bundle.main.bundlePath: \(Bundle.main.bundlePath)")
                        .font(.caption)
                        .lineLimit(1)
                        .truncationMode(.tail)
                    
                    let imageCount = Bundle.main.paths(forResourcesOfType: "png", inDirectory: nil).count
                    Text("PNG 이미지 수: \(imageCount)")
                        .font(.caption)
                    
                    let firstFewImages = Bundle.main.paths(forResourcesOfType: "png", inDirectory: nil).prefix(5)
                    Text("이미지 예시: \(firstFewImages.joined(separator: ", "))")
                        .font(.caption)
                        .lineLimit(2)
                        .truncationMode(.tail)
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
            }
            .padding()
        }
    }
}

#Preview {
    ImageTestView()
} 