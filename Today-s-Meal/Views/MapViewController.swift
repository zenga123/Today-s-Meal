import UIKit
import GoogleMaps
import SwiftUI
import CoreLocation

// KVO Context
private var observerContext = 0

// UIKit 기반 지도 뷰 컨트롤러
class MapViewController: UIViewController, GMSMapViewDelegate {
    // 현재 위치
    var currentLocation: CLLocation?
    
    // 검색 반경 (미터 단위)
    var searchRadius: Double = 1000 {
        didSet {
            // 반경이 변경되면 즉시 업데이트
            updateRadiusCircle()
            updateRadiusLabel()
            updateScaleBar()
        }
    }
    
    // 지도 뷰 참조
    private var mapView: GMSMapView!
    
    // 반경 원 오버레이
    private var radiusCircle: GMSCircle?
    
    // 반경 표시 레이블
    private var radiusLabel: PaddingLabel!
    
    // 스케일 바 요소들
    private var scaleBarView: UIView!
    private var scaleBarLine: UIView!
    private var scaleBarLabel: UILabel!
    
    override func loadView() {
        // Google Maps API 키 설정 (코드로 직접 설정)
        GMSServices.provideAPIKey("AIzaSyCE5Ey4KQcU5d91JKIaVePni4WDouOE7j8")
        
        // 기본 위치 - 서울
        let defaultLocation = CLLocationCoordinate2D(latitude: 37.5665, longitude: 126.9780)
        
        // 지도 옵션 설정
        let camera = GMSCameraPosition.camera(withTarget: defaultLocation, zoom: 15)
        
        // 지도 생성 (로드뷰에서 직접 생성)
        let mapView = GMSMapView.map(withFrame: .zero, camera: camera)
        self.mapView = mapView
        self.view = mapView
        
        // 지도 설정
        mapView.mapType = .normal
        mapView.settings.compassButton = true
        mapView.settings.myLocationButton = true
        mapView.isMyLocationEnabled = true
        
        // 지도 델리게이트 설정
        mapView.delegate = self
        
        // 반경 레이블 추가
        setupRadiusLabel()
        
        // 디버깅용 로그
        print("✅ MapViewController loadView 완료")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("✅ MapViewController viewDidLoad 호출됨")
        
        // 현재 위치로 이동 (있는 경우)
        moveToCurrentLocation()
        
        // 테스트용 마커 추가
        addTestMarker()
        
        // 스케일 바 설정
        setupScaleBar()
        
        // Google 로고 위치 조정
        adjustGoogleLogo()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // KVO 관찰자 추가 (줌 레벨 변경 감지)
        if mapView != nil {
            mapView.addObserver(self, forKeyPath: #keyPath(GMSMapView.camera.zoom), options: [.new], context: &observerContext)
            // 초기 스케일 바 업데이트
            updateScaleBar()
            print("👀 KVO 관찰자 추가: camera.zoom")
        } else {
            print("⚠️ viewWillAppear: MapView가 아직 초기화되지 않음")
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // KVO 관찰자 제거
        if mapView != nil {
            mapView.removeObserver(self, forKeyPath: #keyPath(GMSMapView.camera.zoom), context: &observerContext)
            print("👀 KVO 관찰자 제거: camera.zoom")
        } else {
             print("⚠️ viewWillDisappear: MapView가 없음")
        }
    }
    
    // KVO 핸들러
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if context == &observerContext {
            if keyPath == #keyPath(GMSMapView.camera.zoom) {
                // 줌 레벨 변경 감지 -> 스케일 바 업데이트 (메인 스레드에서)
                DispatchQueue.main.async { [weak self] in
                    self?.updateScaleBar()
                }
            }
        } else {
            // 상위 클래스의 observeValue 호출 (중요)
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
    
    deinit {
        // 만약을 대비한 KVO 관찰자 제거 (viewWillDisappear 호출이 보장되지 않는 경우)
        // mapView가 nil이 아닐 때만 제거 시도
        if mapView != nil {
             // 에러 발생 가능성 때문에 실제 프로덕션에서는 더 견고한 확인 필요
             // 여기서는 viewWillDisappear에서 제거되는 것을 가정
             print("맵 뷰 컨트롤러 deinit")
        }
    }
    
    // 반경 레이블 설정
    private func setupRadiusLabel() {
        radiusLabel = PaddingLabel(padding: UIEdgeInsets(top: 4, left: 8, bottom: 4, right: 8))
        radiusLabel.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        radiusLabel.textColor = .white
        radiusLabel.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        radiusLabel.textAlignment = .center
        radiusLabel.layer.cornerRadius = 8
        radiusLabel.clipsToBounds = true
        
        // 기본 반경 텍스트 설정
        updateRadiusLabel()
        
        // 지도 뷰에 추가
        mapView.addSubview(radiusLabel)
        
        // 레이블 위치 조정 (왼쪽 하단)
        radiusLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            radiusLabel.leadingAnchor.constraint(equalTo: mapView.leadingAnchor, constant: 16),
            radiusLabel.bottomAnchor.constraint(equalTo: mapView.bottomAnchor, constant: -32)
        ])
        
        // 화면에서 숨김
        radiusLabel.isHidden = true
    }
    
    // 반경 레이블 업데이트
    private func updateRadiusLabel() {
        let radiusText: String
        if searchRadius >= 1000 {
            let kmRadius = searchRadius / 1000.0
            radiusText = String(format: "검색 반경: %.1f km", kmRadius)
        } else {
            radiusText = String(format: "검색 반경: %.0f m", searchRadius)
        }
        
        // UI 업데이트는 메인 스레드에서
        DispatchQueue.main.async { [weak self] in
            self?.radiusLabel.text = radiusText
        }
    }
    
    // 테스트용 마커
    private func addTestMarker() {
        // 서울 시청 위치에 마커 추가
        let seoulCityHall = CLLocationCoordinate2D(latitude: 37.5662, longitude: 126.9785)
        let marker = GMSMarker()
        marker.position = seoulCityHall
        marker.title = "서울시청"
        marker.snippet = "Seoul City Hall"
        marker.icon = GMSMarker.markerImage(with: .blue)
        marker.map = mapView
        
        print("✅ 테스트 마커 추가됨")
    }
    
    // 위치 업데이트 메서드
    func updateLocation(_ location: CLLocation) {
        self.currentLocation = location
        moveToCurrentLocation()
    }
    
    // 검색 반경 변경 메서드
    func updateSearchRadius(_ radius: Double) {
        self.searchRadius = radius
    }
    
    // 반경 원 업데이트
    private func updateRadiusCircle() {
        // 기존 원 제거
        radiusCircle?.map = nil
        
        // 보라색 원을 표시하지 않음 - 원하는 경우 아래 주석을 해제하여 다시 활성화 가능
        /*
        guard let location = currentLocation else { return }
        
        // 새 원 생성
        let circle = GMSCircle(position: location.coordinate, radius: searchRadius)
        circle.fillColor = UIColor.blue.withAlphaComponent(0.1)
        circle.strokeColor = UIColor.blue.withAlphaComponent(0.5)
        circle.strokeWidth = 1
        circle.map = mapView
        
        self.radiusCircle = circle
        */
    }
    
    // 현재 위치로 지도 이동
    private func moveToCurrentLocation() {
        guard let location = currentLocation else { 
            print("❌ 현재 위치 정보 없음")
            return 
        }
        
        let position = CLLocationCoordinate2D(
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude
        )
        
        // 카메라 이동
        let camera = GMSCameraPosition.camera(withTarget: position, zoom: 15)
        mapView.animate(to: camera)
        
        // 현재 위치에 마커 추가
        let marker = GMSMarker()
        marker.position = position
        marker.title = "현재 위치"
        marker.snippet = "여기에 있습니다"
        marker.map = mapView
        
        // 반경 원 업데이트
        updateRadiusCircle()
        
        print("✅ 지도 위치 업데이트: \(position.latitude), \(position.longitude)")
    }
    
    // 스케일 바 설정
    private func setupScaleBar() {
        // 스케일 바 컨테이너 뷰
        scaleBarView = UIView()
        scaleBarView.backgroundColor = .clear
        mapView.addSubview(scaleBarView)
        
        // 스케일 바 선
        scaleBarLine = UIView()
        scaleBarLine.backgroundColor = .white
        scaleBarLine.layer.borderWidth = 1
        scaleBarLine.layer.borderColor = UIColor.black.withAlphaComponent(0.5).cgColor
        scaleBarView.addSubview(scaleBarLine)
        
        // 스케일 바 레이블
        scaleBarLabel = UILabel()
        scaleBarLabel.font = UIFont.systemFont(ofSize: 10, weight: .regular)
        scaleBarLabel.textColor = UIColor.black.withAlphaComponent(0.8)
        scaleBarLabel.textAlignment = .center
        scaleBarView.addSubview(scaleBarLabel)
        
        // 레이아웃 설정
        scaleBarView.translatesAutoresizingMaskIntoConstraints = false
        scaleBarLine.translatesAutoresizingMaskIntoConstraints = false
        scaleBarLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // 고정 너비 설정 (Google Maps 스타일)
        let fixedScaleBarWidth: CGFloat = 100
        
        NSLayoutConstraint.activate([
            scaleBarView.leadingAnchor.constraint(equalTo: mapView.leadingAnchor, constant: 16),
            scaleBarView.bottomAnchor.constraint(equalTo: mapView.bottomAnchor, constant: -16),
            scaleBarView.widthAnchor.constraint(equalToConstant: fixedScaleBarWidth + 20),
            scaleBarView.heightAnchor.constraint(equalToConstant: 30),
            
            scaleBarLine.leadingAnchor.constraint(equalTo: scaleBarView.leadingAnchor),
            scaleBarLine.bottomAnchor.constraint(equalTo: scaleBarView.bottomAnchor),
            scaleBarLine.widthAnchor.constraint(equalToConstant: fixedScaleBarWidth),
            scaleBarLine.heightAnchor.constraint(equalToConstant: 4),
            
            scaleBarLabel.centerXAnchor.constraint(equalTo: scaleBarLine.centerXAnchor),
            scaleBarLabel.topAnchor.constraint(equalTo: scaleBarLine.bottomAnchor, constant: 2)
        ])
        
        // 초기 텍스트 설정
        scaleBarLabel.text = "1 km"
        
        // 구글 맵 스타일 스케일 마커 추가
        addScaleMarkers(to: scaleBarLine, width: fixedScaleBarWidth)
        
        // 스케일 바 초기 업데이트
        updateScaleBar()
    }
    
    // 스케일 마커(눈금) 추가 - 구글맵 스타일
    private func addScaleMarkers(to scaleBarLine: UIView, width: CGFloat) {
        // 눈금 추가 (시작, 중간, 끝)
        let markerPositions = [0, width/2, width]
        
        for position in markerPositions {
            let marker = UIView()
            marker.backgroundColor = .black
            marker.translatesAutoresizingMaskIntoConstraints = false
            scaleBarLine.addSubview(marker)
            
            NSLayoutConstraint.activate([
                marker.centerXAnchor.constraint(equalTo: scaleBarLine.leadingAnchor, constant: position),
                marker.topAnchor.constraint(equalTo: scaleBarLine.topAnchor, constant: -3),
                marker.widthAnchor.constraint(equalToConstant: 1),
                marker.heightAnchor.constraint(equalToConstant: 10)
            ])
        }
    }
    
    // 스케일 바 업데이트
    private func updateScaleBar() {
        // nil 체크 및 필요한 요소 가져오기
        guard let mapView = self.mapView,
              let scaleBarLine = self.scaleBarLine,
              let scaleBarView = self.scaleBarView,
              let scaleBarLabel = self.scaleBarLabel else {
            //print("⚠️ 스케일 바 업데이트 불가: 지도 또는 UI 요소 미초기화")
            return
        }
        // projection은 mapView가 nil이 아니면 항상 존재하므로 직접 할당
        let projection = mapView.projection
        
        // 1. 현재 화면 너비에 해당하는 실제 거리 계산
        let mapBounds = mapView.bounds
        let screenWidthPoints = mapBounds.width
        // 화면 중앙 좌우 끝점의 좌표 계산
        let leftCenterPoint = CGPoint(x: mapBounds.minX, y: mapBounds.midY)
        let rightCenterPoint = CGPoint(x: mapBounds.maxX, y: mapBounds.midY)
        let leftCoord = projection.coordinate(for: leftCenterPoint)
        let rightCoord = projection.coordinate(for: rightCenterPoint)
        
        // 유효한 좌표인지 확인 (지도가 완전히 로드되지 않았을 수 있음)
        guard CLLocationCoordinate2DIsValid(leftCoord), CLLocationCoordinate2DIsValid(rightCoord) else {
            //print("⚠️ 유효하지 않은 좌표, 스케일 바 업데이트 건너뜀")
            return
        }
        
        let horizontalDistanceMeters = GMSGeometryDistance(leftCoord, rightCoord)
        
        // 화면 포인트당 실제 미터 계산 (0으로 나누기 방지)
        guard horizontalDistanceMeters > 0, screenWidthPoints > 0 else {
             //print("⚠️ 거리 또는 너비가 0, 스케일 바 업데이트 건너뜀")
            return
        }
        let pointsPerMeter = Double(screenWidthPoints) / horizontalDistanceMeters
        
        // 2. 목표 막대 길이에 해당하는 실제 거리 계산 (예: 100 포인트 기준)
        let targetBarLengthPoints: Double = 100.0 // 원하는 막대 길이 (포인트)
        let approxDistanceForTargetLength = targetBarLengthPoints / pointsPerMeter
        
        // 3. 표시할 '깔끔한' 거리 선택
        let displayDistance = calculateNiceRoundedDistance(for: approxDistanceForTargetLength)
        
        // 4. 선택된 거리를 표시하기 위한 실제 막대 길이 계산
        let actualBarLengthPoints = pointsPerMeter * displayDistance
        
        // 5. 텍스트 설정
        let displayText: String
        if displayDistance >= 1000 {
            let kmDistance = displayDistance / 1000.0
            displayText = String(format: "%.*f km", kmDistance.truncatingRemainder(dividingBy: 1) == 0 ? 0 : 1, kmDistance)
        } else {
            displayText = "\(Int(displayDistance)) m"
        }
        
        // print("📊 스케일 바 업데이트: \(displayText), 막대 길이: \(actualBarLengthPoints)pt")
        
        // 6. UI 업데이트 (메인 스레드)
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // 레이블 텍스트 업데이트
            scaleBarLabel.text = displayText
            
            // 스케일 바 라인 너비 업데이트
            // 기존 너비 제약 조건 찾아서 비활성화 및 제거 (더 안전한 방식)
            if let existingConstraint = scaleBarLine.constraints.first(where: { $0.firstAttribute == .width }) {
                existingConstraint.isActive = false
                scaleBarLine.removeConstraint(existingConstraint)
            }
            let newLineConstraint = scaleBarLine.widthAnchor.constraint(equalToConstant: CGFloat(actualBarLengthPoints))
            newLineConstraint.isActive = true
            
            // 스케일 바 컨테이너 너비 업데이트
            if let existingContainerConstraint = scaleBarView.constraints.first(where: { $0.firstAttribute == .width }) {
                existingContainerConstraint.isActive = false
                scaleBarView.removeConstraint(existingContainerConstraint)
            }
            let newContainerConstraint = scaleBarView.widthAnchor.constraint(equalToConstant: CGFloat(actualBarLengthPoints))
            newContainerConstraint.isActive = true
            
            // 레이아웃 업데이트 요청
            // self.view.layoutIfNeeded() // KVO에서 너무 자주 호출될 수 있으므로 주석 처리, 필요시 활성화
        }
    }
    
    // 깔끔한 반올림 거리 계산 (구글 맵 스타일)
    private func calculateNiceRoundedDistance(for distance: Double) -> Double {
        let niceDistances: [Double] = [
            10, 20, 25, 50, 100, 200, 250, 500,
            1000, 2000, 2500, 5000, 10000, 20000, 25000, 50000, 100000
        ]
        
        // 적절한 반올림 거리 찾기
        for niceDistance in niceDistances {
            if distance <= niceDistance * 1.5 {
                return niceDistance
            }
        }
        
        return 100000 // 최대 100km
    }
    
    // MARK: - GMSMapViewDelegate
    
    // 카메라 이동이 완료된 후 호출
    func mapView(_ mapView: GMSMapView, didChange position: GMSCameraPosition) {
        // 줌 레벨에 따라 실제 검색 반경 업데이트
        let zoomLevel = position.zoom
        updateRadiusBasedOnZoom(zoomLevel)
        
        // KVO가 스케일 바 업데이트를 처리하므로 여기서는 호출 안 함
        // updateScaleBar()
        
        // 디버깅용
        print("📏 줌 레벨 완료: \(zoomLevel), 검색 반경 설정: \(searchRadius)")
    }
    
    // 지도 로드 완료 시 호출
    func mapViewDidFinishTileRendering(_ mapView: GMSMapView) {
        // KVO가 viewWillAppear에서 초기 업데이트를 처리하므로 여기서는 호출 안 함
        // updateScaleBar()
        print("🗺️ 지도 타일 렌더링 완료")
    }
    
    // 줌 레벨에 따라 반경 업데이트
    private func updateRadiusBasedOnZoom(_ zoomLevel: Float) {
        if zoomLevel >= 10 && zoomLevel <= 18 {
            let newRadius = calculateRadiusFromZoom(zoomLevel)
            // 민감도 임계값을 작게 설정하여 작은 변화도 반영되도록 함
            if abs(newRadius - searchRadius) > 0.1 { 
                searchRadius = newRadius
                print("🔄 반경 업데이트: \(searchRadius)")
            }
        }
    }
    
    // 줌 레벨에 따른 반경 계산 함수
    private func calculateRadiusFromZoom(_ zoom: Float) -> Double {
        // 줌 레벨에 따른 반경 계산 (18: 300m, 10: 3000m 사이의 값)
        // zoom이 18일 때 300, 10일 때 3000이 되도록 선형 계산
        let zoomRange: Double = 8.0 // 18 - 10
        let radiusRange: Double = 2700.0 // 3000 - 300
        
        let zoomFactor = Double(18.0 - zoom) / zoomRange
        let radius = 300.0 + (zoomFactor * radiusRange)
        
        // 소수점 아래 1자리까지만 사용하여 안정성 향상
        return Double(round(radius * 10) / 10)
    }
    
    // Google 로고 위치 조정
    private func adjustGoogleLogo() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            if let logoView = self.findGoogleLogo(in: self.mapView) {
                // 로고를 오른쪽 하단으로 이동
                logoView.translatesAutoresizingMaskIntoConstraints = false
                
                // 기존 제약조건 제거
                if let superview = logoView.superview {
                    for constraint in superview.constraints {
                        if constraint.firstItem === logoView || constraint.secondItem === logoView {
                            superview.removeConstraint(constraint)
                        }
                    }
                }
                
                // 로고 크기 강제로 작게 만들기
                logoView.contentMode = .scaleAspectFit
                
                if let superview = logoView.superview {
                    NSLayoutConstraint.activate([
                        logoView.trailingAnchor.constraint(equalTo: superview.trailingAnchor, constant: -8),
                        logoView.bottomAnchor.constraint(equalTo: superview.bottomAnchor, constant: -8),
                        logoView.widthAnchor.constraint(lessThanOrEqualToConstant: 80),
                        logoView.heightAnchor.constraint(lessThanOrEqualToConstant: 22)
                    ])
                }
                
                self.view.layoutIfNeeded()
                print("✅ Google 로고 위치 조정됨")
            } else {
                print("⚠️ Google 로고를 찾을 수 없음")
            }
        }
    }
    
    // Google 로고 뷰 찾기
    private func findGoogleLogo(in view: UIView) -> UIView? {
        if view.isKind(of: NSClassFromString("GMSUISettingsView") ?? UIView.self) {
            return view
        }
        
        for subview in view.subviews {
            if let logoView = findGoogleLogo(in: subview) {
                return logoView
            }
        }
        
        return nil
    }
}

// 패딩이 있는 라벨 클래스 (UILabel 확장 대신 서브클래스 사용)
class PaddingLabel: UILabel {
    private var insets: UIEdgeInsets
    
    init(padding: UIEdgeInsets) {
        self.insets = padding
        super.init(frame: .zero)
    }
    
    required init?(coder aDecoder: NSCoder) {
        self.insets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        super.init(coder: aDecoder)
    }
    
    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: insets))
    }
    
    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(
            width: size.width + insets.left + insets.right,
            height: size.height + insets.top + insets.bottom
        )
    }
}

// SwiftUI에서 사용할 수 있는 MapView
struct NativeMapView: UIViewControllerRepresentable {
    // 위치 바인딩
    @Binding var mapLocation: CLLocation?
    // 선택된 반경 바인딩
    @Binding var selectedRadius: Double
    
    func makeUIViewController(context: Context) -> MapViewController {
        let viewController = MapViewController()
        viewController.currentLocation = mapLocation
        viewController.searchRadius = selectedRadius
        return viewController
    }
    
    func updateUIViewController(_ uiViewController: MapViewController, context: Context) {
        if let location = mapLocation {
            uiViewController.updateLocation(location)
        }
        
        // 선택된 반경 업데이트
        if uiViewController.searchRadius != selectedRadius {
            uiViewController.updateSearchRadius(selectedRadius)
        }
    }
} 