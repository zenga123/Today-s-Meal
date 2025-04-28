import SwiftUI

struct ResultsView: View {
    let restaurants: [Restaurant]
    @State private var selectedRestaurant: Restaurant?
    @State private var navigateToDetail = false
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var locationService: LocationService
    
    var body: some View {
        VStack {
            if restaurants.isEmpty {
                emptyResultsView
            } else {
                restaurantListView
            }
        }
        .navigationTitle("검색 결과")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $navigateToDetail) {
            if let restaurant = selectedRestaurant {
                DetailView(restaurant: restaurant)
                    .environmentObject(locationService)
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    dismiss()
                }) {
                    HStack {
                        Image(systemName: "arrow.left")
                        Text("뒤로")
                    }
                }
            }
        }
    }
    
    private var emptyResultsView: some View {
        VStack(spacing: 20) {
            Image(systemName: "magnifyingglass")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .foregroundColor(.gray)
            
            Text("음식점을 찾을 수 없습니다")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("검색 조건을 변경해 보세요")
                .foregroundColor(.gray)
            
            Button(action: {
                dismiss()
            }) {
                Text("검색으로 돌아가기")
                    .padding()
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.top, 20)
        }
        .padding()
    }
    
    private var restaurantListView: some View {
        List {
            ForEach(restaurants) { restaurant in
                RestaurantRow(restaurant: restaurant)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedRestaurant = restaurant
                        navigateToDetail = true
                    }
            }
        }
        .listStyle(PlainListStyle())
    }
}

struct RestaurantRow: View {
    let restaurant: Restaurant
    
    var body: some View {
        HStack(spacing: 16) {
            // Thumbnail image
            AsyncImage(url: URL(string: restaurant.photo.mobile.l)) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                        .frame(width: 80, height: 80)
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 80, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                case .failure:
                    Image(systemName: "photo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 80, height: 80)
                        .foregroundColor(.gray)
                @unknown default:
                    EmptyView()
                }
            }
            .frame(width: 80, height: 80)
            
            // Restaurant info
            VStack(alignment: .leading, spacing: 4) {
                Text(restaurant.name)
                    .font(.headline)
                    .lineLimit(1)
                
                Text(restaurant.genre.name)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                Text(restaurant.access)
                    .font(.caption)
                    .lineLimit(2)
                    .foregroundColor(.secondary)
                
                HStack {
                    Image(systemName: "yen.circle.fill")
                    Text(restaurant.budget.name)
                }
                .font(.caption)
                .foregroundColor(.orange)
            }
        }
        .padding(.vertical, 8)
    }
} 