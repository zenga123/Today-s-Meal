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
            if abs(oldValue - searchRadius) > 0.1 {
                print("🔄 searchRadius didSet: \(oldValue) -> \(searchRadius)")
                // 반경이 변경되면 즉시 업데이트
                updateRadiusCircle()
                updateRadiusLabel()
                updateScaleBar()
                
                // 줌 레벨 자동 조정 
                adjustZoomToFitRadius(searchRadius)
            }
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
    
    // 반경 원 업데이트
    private func updateRadiusCircle() {
        // 기존 원 제거
        radiusCircle?.map = nil
        
        // 원 표시 기능 활성화
        guard let location = currentLocation else { return }
        
        // 새 원 생성
        let circle = GMSCircle(position: location.coordinate, radius: searchRadius)
        circle.fillColor = UIColor.clear // 내부 완전 투명
        circle.strokeColor = UIColor.blue // 테두리 파란색
        circle.strokeWidth = 2 // 테두리 두께
        circle.map = mapView
        
        self.radiusCircle = circle
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
        
        // 고정 너비 설정
        let fixedContainerWidth: CGFloat = 120
        let initialLineWith: CGFloat = 100 // 초기 라인 너비 (임의)
        
        NSLayoutConstraint.activate([
            // 컨테이너 위치 및 고정 너비
            scaleBarView.leadingAnchor.constraint(equalTo: mapView.leadingAnchor, constant: 16),
            scaleBarView.bottomAnchor.constraint(equalTo: mapView.bottomAnchor, constant: -16),
            scaleBarView.widthAnchor.constraint(equalToConstant: fixedContainerWidth),
            scaleBarView.heightAnchor.constraint(equalToConstant: 30),
            
            // 라인 위치 및 초기 너비/높이
            scaleBarLine.leadingAnchor.constraint(equalTo: scaleBarView.leadingAnchor),
            scaleBarLine.bottomAnchor.constraint(equalTo: scaleBarView.bottomAnchor),
            scaleBarLine.widthAnchor.constraint(equalToConstant: initialLineWith), // 초기값, 동적 변경됨
            scaleBarLine.heightAnchor.constraint(equalToConstant: 4),
            
            // 라벨 위치
            scaleBarLabel.centerXAnchor.constraint(equalTo: scaleBarLine.centerXAnchor),
            scaleBarLabel.topAnchor.constraint(equalTo: scaleBarLine.bottomAnchor, constant: 2)
        ])
        
        // 초기 텍스트 설정
        scaleBarLabel.text = "1 km"
        
        // 고정된 눈금 추가 제거
        // addScaleMarkers(referenceWidth: markerReferenceWidth)
        
        // 스케일 바 초기 업데이트
        updateScaleBar()
    }
    
    // 스케일 바 업데이트
    private func updateScaleBar() {
        // nil 체크 및 필요한 요소 가져오기
        guard let mapView = self.mapView,
              let scaleBarLine = self.scaleBarLine,
              let scaleBarLabel = self.scaleBarLabel,
              let scaleBarView = self.scaleBarView // scaleBarView도 guard에 포함
        else {
            //print("⚠️ 스케일 바 업데이트 불가: 지도 또는 UI 요소 미초기화")
            return
        }
        // projection은 mapView가 nil이 아니면 항상 존재하므로 직접 할당
        let projection = mapView.projection
        
        // 1. 현재 화면 너비에 해당하는 실제 거리 계산
        let mapBounds = mapView.bounds
        let screenWidthPoints = mapBounds.width
        let leftCenterPoint = CGPoint(x: mapBounds.minX, y: mapBounds.midY)
        let rightCenterPoint = CGPoint(x: mapBounds.maxX, y: mapBounds.midY)
        let leftCoord = projection.coordinate(for: leftCenterPoint)
        let rightCoord = projection.coordinate(for: rightCenterPoint)
        
        // 유효한 좌표인지 확인 (지도가 완전히 로드되지 않았을 수 있음)
        guard CLLocationCoordinate2DIsValid(leftCoord), CLLocationCoordinate2DIsValid(rightCoord) else {
            return
        }
        
        let horizontalDistanceMeters = GMSGeometryDistance(leftCoord, rightCoord)
        
        // 화면 포인트당 실제 미터 계산 (0으로 나누기 방지)
        guard horizontalDistanceMeters > 0, screenWidthPoints > 0 else {
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
        
        // UI 업데이트 (메인 스레드)
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // 레이블 텍스트 업데이트
            scaleBarLabel.text = displayText
            
            // 스케일 바 라인 너비 업데이트
            if let existingConstraint = scaleBarLine.constraints.first(where: { $0.firstAttribute == .width }) {
                existingConstraint.isActive = false
                scaleBarLine.removeConstraint(existingConstraint)
            }
            let newLineConstraint = scaleBarLine.widthAnchor.constraint(equalToConstant: CGFloat(actualBarLengthPoints))
            newLineConstraint.isActive = true
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
        // 디버깅용: 줌 레벨 변경 시 보이는 반경 확인
        debugCheckVisibleRadius()
        
        // 스케일 바 업데이트
        updateScaleBar()
        
        // 디버깅용
        print("📏 줌 레벨 변경: \(position.zoom)")
    }
    
    // 지도 로드 완료 시 호출
    func mapViewDidFinishTileRendering(_ mapView: GMSMapView) {
        // 지도 타일 렌더링 완료
        print("🗺️ 지도 타일 렌더링 완료")
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
    
    // 검색 반경 설정 (버튼 클릭에 대응하는 함수)
    func setSearchRadius(_ radius: Double) {
        print("🎯 지도 검색 반경 설정: \(radius)m, 기존: \(searchRadius)m")
        
        // 반경이 변경되었을 경우에만 처리
        if abs(searchRadius - radius) > 0.1 {
            // 검색 반경 설정
            self.searchRadius = radius
            
            // 선택된 반경에 맞는 줌 레벨로 지도 조정
            adjustZoomToFitRadius(radius)
        }
    }
    
    // 반경에 맞게 지도 줌 레벨 조정
    private func adjustZoomToFitRadius(_ radius: Double) {
        guard let location = currentLocation else { 
            print("⚠️ 현재 위치 정보 없어 줌 조정 실패")
            return 
        }
        
        // 반경에 따른 적절한 줌 레벨 계산 - Google Maps 특성상 각 값 미세 조정
        var zoomLevel: Float
        
        switch radius {
        case ...300:
            zoomLevel = 16.0 // 300m
        case ...500:
            zoomLevel = 15.0 // 500m 
        case ...1000:
            zoomLevel = 14.0 // 1km
        case ...2000:
            zoomLevel = 13.0 // 2km
        case ...3000:
            zoomLevel = 12.0 // 3km
        default:
            zoomLevel = 11.0 // 3km 초과
        }
        
        print("🔍 반경 \(radius)m에 맞게 줌 레벨 조정: \(zoomLevel)")
        
        // 애니메이션과 함께 카메라 이동 - 현재 위치 중심
        let cameraUpdate = GMSCameraUpdate.setTarget(location.coordinate, zoom: zoomLevel)
        mapView.animate(with: cameraUpdate)
        
        // 실제 화면에 표시되는 반경 확인 - 디버깅용
        debugCheckVisibleRadius()
    }
    
    // 디버깅용: 실제 화면에 표시되는 반경 체크
    private func debugCheckVisibleRadius() {
        guard let mapView = self.mapView,
              let location = currentLocation else { return }
        
        let projection = mapView.projection
        let center = location.coordinate
        let centerPoint = projection.point(for: center)
        
        // 화면 가로 끝까지의 실제 거리 계산
        let rightEdgePoint = CGPoint(x: mapView.bounds.maxX, y: centerPoint.y)
        let rightEdgeCoord = projection.coordinate(for: rightEdgePoint)
        let visibleRadius = GMSGeometryDistance(center, rightEdgeCoord)
        
        print("📏 화면에 보이는 실제 반경: \(Int(visibleRadius))m (설정된 반경: \(Int(searchRadius))m)")
    }
    
    // NativeMapView에서 반경 버튼 클릭 시 호출될 메서드
    func handleRadiusButtonTap(radius: Double) {
        setSearchRadius(radius)
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
    
    // UIViewController 생성
    func makeUIViewController(context: Context) -> MapViewController {
        let viewController = MapViewController()
        viewController.currentLocation = mapLocation
        viewController.searchRadius = selectedRadius
        return viewController
    }
    
    // UIViewController 업데이트
    func updateUIViewController(_ uiViewController: MapViewController, context: Context) {
        // 위치 업데이트
        if let location = mapLocation {
            if uiViewController.currentLocation?.coordinate.latitude != location.coordinate.latitude ||
               uiViewController.currentLocation?.coordinate.longitude != location.coordinate.longitude {
                uiViewController.updateLocation(location)
            }
        }
        
        // 반경 업데이트
        if abs(uiViewController.searchRadius - selectedRadius) > 0.1 {
            print("⚡️ NativeMapView: 반경 변경 감지 \(uiViewController.searchRadius) -> \(selectedRadius)")
            uiViewController.searchRadius = selectedRadius
        }
    }
} 