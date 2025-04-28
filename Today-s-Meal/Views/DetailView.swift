import SwiftUI
import MapKit

struct DetailView: View {
    let restaurant: Restaurant
    @State private var showMap = false
    @EnvironmentObject var locationService: LocationService
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Restaurant image
                imageSection
                
                // Main info section
                mainInfoSection
                
                Divider()
                
                // Details section
                detailsSection
                
                Divider()
                
                // Map section
                mapSection
                
                Divider()
                
                // Action buttons
                actionButtons
            }
            .padding()
        }
        .navigationTitle(restaurant.name)
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private var imageSection: some View {
        AsyncImage(url: URL(string: restaurant.photo.pc.l)) { phase in
            switch phase {
            case .empty:
                ProgressView()
                    .frame(height: 200)
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 200)
                    .clipped()
                    .cornerRadius(8)
            case .failure:
                Image(systemName: "photo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 200)
                    .foregroundColor(.gray)
            @unknown default:
                EmptyView()
            }
        }
        .cornerRadius(8)
    }
    
    private var mainInfoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(restaurant.name)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(restaurant.catchPhrase)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.bottom, 4)
            
            HStack {
                Image(systemName: "mappin.and.ellipse")
                    .foregroundColor(.red)
                Text(restaurant.address)
                    .font(.subheadline)
            }
            
            HStack {
                Image(systemName: "tram.fill")
                    .foregroundColor(.blue)
                Text(restaurant.access)
                    .font(.subheadline)
            }
            
            HStack {
                Image(systemName: "yen.circle.fill")
                    .foregroundColor(.orange)
                Text("\(restaurant.budget.name) (평균: \(restaurant.budget.average))")
                    .font(.subheadline)
            }
        }
    }
    
    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("상세 정보")
            
            detailRow(title: "장르", value: restaurant.genre.name)
            
            detailRow(title: "오픈 시간", value: restaurant.open)
            
            detailRow(title: "마감 시간", value: restaurant.close)
            
            if !restaurant.wifi.isEmpty {
                detailRow(title: "와이파이", value: restaurant.wifi)
            }
            
            if !restaurant.parking.isEmpty {
                detailRow(title: "주차", value: restaurant.parking)
            }
            
            if !restaurant.card.isEmpty {
                detailRow(title: "카드 결제", value: restaurant.card)
            }
        }
    }
    
    private var mapSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader("위치")
            
            MapView(coordinate: CLLocationCoordinate2D(
                latitude: restaurant.lat,
                longitude: restaurant.lng
            ), name: restaurant.name)
            .frame(height: 150)
            .cornerRadius(8)
            .padding(.vertical, 4)
        }
    }
    
    private var actionButtons: some View {
        VStack(spacing: 12) {
            Link(destination: URL(string: restaurant.urls.pc)!) {
                HStack {
                    Image(systemName: "globe")
                    Text("웹사이트 방문")
                    Spacer()
                    Image(systemName: "arrow.right")
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            
            Button(action: {
                let mapURL = URL(string: "maps://?q=\(restaurant.name)&ll=\(restaurant.lat),\(restaurant.lng)")
                if let url = mapURL, UIApplication.shared.canOpenURL(url) {
                    UIApplication.shared.open(url)
                }
            }) {
                HStack {
                    Image(systemName: "map")
                    Text("지도에서 열기")
                    Spacer()
                    Image(systemName: "arrow.right")
                }
                .padding()
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
        }
        .padding(.vertical, 8)
    }
    
    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.headline)
            .padding(.vertical, 4)
    }
    
    private func detailRow(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.gray)
            
            Text(value)
                .font(.body)
        }
        .padding(.vertical, 2)
    }
}

struct MapView: UIViewRepresentable {
    let coordinate: CLLocationCoordinate2D
    let name: String
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        annotation.title = name
        
        mapView.removeAnnotations(mapView.annotations)
        mapView.addAnnotation(annotation)
        
        let region = MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
        
        mapView.setRegion(region, animated: true)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapView
        
        init(_ parent: MapView) {
            self.parent = parent
        }
        
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            let identifier = "restaurantPin"
            
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView
            
            if annotationView == nil {
                annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                annotationView?.canShowCallout = true
            } else {
                annotationView?.annotation = annotation
            }
            
            return annotationView
        }
    }
} 