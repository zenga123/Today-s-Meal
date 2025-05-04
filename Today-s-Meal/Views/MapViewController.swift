import UIKit
import GoogleMaps
import SwiftUI
import CoreLocation
import Combine

// KVO Context
private var observerContext = 0

// UIKit 기반 지도 뷰 컨트롤러
class MapViewController: UIViewController, GMSMapViewDelegate {
    // 현재 위치
    var currentLocation: CLLocation?
    
    // 검색 반경 (미터 단위) - 기본값을 300m로 변경
    var searchRadius: Double = 300 {
        didSet {
            // oldValue와 비교하는 조건은 유지 (불필요한 업데이트 방지)
            if abs(oldValue - searchRadius) > 0.1 {
                print("🔄 searchRadius didSet: \(oldValue) -> \(searchRadius)")
                // 반경 원, 레이블, 스케일 바 업데이트
                updateRadiusCircle()
                updateRadiusLabel()
                updateScaleBar()

                // 줌 업데이트 로직은 제거 (setSearchRadius 또는 updateSearchRadiusBasedOnScale에서 처리)
                // updateMapZoomForRadius() // 제거

                // 콜백 호출도 제거 (updateSearchRadiusBasedOnScale 함수로 이동)
                // radiusChangeCallback?(searchRadius) // 제거
            }
        }
    }
    
    // 반경 변경을 부모 뷰에 알리기 위한 콜백
    var radiusChangeCallback: ((Double) -> Void)?
    
    // 검색 결과를 부모 뷰에 알리기 위한 콜백
    var searchResultsCallback: (([HotPepperRestaurant]) -> Void)?
    
    // 프로그램적인 줌 변경 여부 플래그
    private var isProgrammaticZoomChange: Bool = false
    
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
    
    // 식당 목록
    var restaurants: [HotPepperRestaurant] = [] {
        didSet {
            // 식당 목록이 업데이트될 때마다 지도에 표시
            updateRestaurantMarkers()
        }
    }
    
    // 마커 관리를 위한 딕셔너리 (식당 ID를 키로 사용)
    private var restaurantMarkers: [String: GMSMarker] = [:]
    
    // 선택된 테마
    var selectedTheme: String?
    
    // 식당 상세 페이지로 이동하기 위한 콜백
    var onRestaurantSelected: ((HotPepperRestaurant) -> Void)?
    
    override func loadView() {
        // Google Maps API 키 설정 (코드로 직접 설정)
        GMSServices.provideAPIKey("AIzaSyCE5Ey4KQcU5d91JKIaVePni4WDouOE7j8")
        
        // 기본 위치 - 서울 (초기값으로 사용, 실제 위치가 업데이트 예정)
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
        
        // 현재 위치로 이동 (위치 서비스에서 제공하면)
        if let location = currentLocation {
            moveToCurrentLocation()
            
            // 위치가 있으면 자동으로 검색 실행
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.searchRestaurants(theme: self.selectedTheme)
            }
        }
        
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
        radiusLabel = PaddingLabel(padding: UIEdgeInsets(top: 6, left: 12, bottom: 6, right: 12))
        radiusLabel.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.8)
        radiusLabel.textColor = .white
        radiusLabel.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        radiusLabel.textAlignment = .center
        radiusLabel.layer.cornerRadius = 12
        radiusLabel.clipsToBounds = true
        
        // 기본 반경 텍스트 설정
        updateRadiusLabel()
        
        // 지도 뷰에 추가
        mapView.addSubview(radiusLabel)
        
        // 레이블 위치 조정 (중앙 상단)
        radiusLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            radiusLabel.centerXAnchor.constraint(equalTo: mapView.centerXAnchor),
            radiusLabel.topAnchor.constraint(equalTo: mapView.topAnchor, constant: 70)
        ])
        
        // 기본적으로 표시
        radiusLabel.isHidden = false
        
        // 2초 후 숨김
        perform(#selector(fadeOutRadiusLabel), with: nil, afterDelay: 2.0)
    }
    
    // 반경 레이블 업데이트
    private func updateRadiusLabel() {
        let radiusText: String
        if searchRadius >= 1000 {
            // 정확히 3000m일 때는 3.0km로 표시
            if searchRadius == 3000 {
                radiusText = "範囲: 3.0 km"
            } else {
                let kmRadius = searchRadius / 1000.0
                radiusText = String(format: "範囲: %.1f km", kmRadius)
            }
        } else {
            radiusText = String(format: "範囲: %d m", Int(searchRadius))
        }
        
        // UI 업데이트는 메인 스레드에서
        DispatchQueue.main.async { [weak self] in
            self?.radiusLabel.text = radiusText
            
            // 검색 반경 변경 시 애니메이션 효과
            UIView.animate(withDuration: 0.2) {
                self?.radiusLabel.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
            } completion: { _ in
                UIView.animate(withDuration: 0.1) {
                    self?.radiusLabel.transform = .identity
                }
            }
        }
    }
    
    // 테스트용 마커
    private func addTestMarker() {
        // 서울 시청 위치에 마커 추가
        let seoulCityHall = CLLocationCoordinate2D(latitude: 37.5662, longitude: 126.9785)
        let marker = GMSMarker()
        marker.position = seoulCityHall
        marker.title = "東京都庁"
        marker.snippet = "Tokyo Metropolitan Government Building"
        marker.icon = GMSMarker.markerImage(with: .blue)
        marker.map = mapView
        
        print("✅ テストマーカーが追加されました")
    }
    
    // 위치 업데이트 메서드
    func updateLocation(_ location: CLLocation) {
        // 이전 위치와 새 위치 사이의 거리 계산
        let locationChanged: Bool
        if let oldLocation = self.currentLocation {
            let distance = location.distance(from: oldLocation)
            locationChanged = distance > 10  // 10m 이상 차이가 있을 때만 위치 변경으로 간주
            print("🔄 位置が更新されました: \(distance)m 移動")
        } else {
            locationChanged = true
            print("🔄 最初の位置が設定されました")
        }
        
        // 위치 업데이트
        self.currentLocation = location
        
        // 위치가 변경되었거나 처음 위치가 설정된 경우에만 지도 이동
        if locationChanged {
            moveToCurrentLocation()
            
            // 위치가 변경되면 자동으로 검색 실행
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.searchRestaurants(theme: self.selectedTheme)
            }
        }
    }
    
    // 반경 원 업데이트
    private func updateRadiusCircle() {
        // 기존 원 제거
        radiusCircle?.map = nil
        
        // 원 표시 기능 활성화
        guard let location = currentLocation else { return }
        
        // 새 원 생성
        let circle = GMSCircle(position: location.coordinate, radius: searchRadius)
        circle.fillColor = UIColor.systemBlue.withAlphaComponent(0.1) // 약간의 파란색 내부 (완전 투명 대신)
        circle.strokeColor = UIColor.systemBlue.withAlphaComponent(0.8) // 더 진한 테두리
        circle.strokeWidth = 2 // 테두리 두께
        circle.map = mapView
        
        self.radiusCircle = circle
        
        // 반경 레이블도 함께 업데이트 및 표시
        updateRadiusLabel()
        showRadiusLabelTemporarily()
    }
    
    // 현재 위치로 지도 이동
    private func moveToCurrentLocation() {
        guard let location = currentLocation else { 
            print("❌ 現在の位置情報がありません")
            return 
        }
        
        let position = CLLocationCoordinate2D(
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude
        )
        
        // カメラを移動
        let camera = GMSCameraPosition.camera(withTarget: position, zoom: 15)
        mapView.animate(to: camera)
        
        // 半径の円を更新
        updateRadiusCircle()
        
        print("✅ 地図の位置が更新されました: \(position.latitude), \(position.longitude)")
    }
    
    // 스케일바를 설정
    private func setupScaleBar() {
        // 스케일바의 컨테이너 뷰
        scaleBarView = UIView()
        scaleBarView.backgroundColor = .clear
        mapView.addSubview(scaleBarView)
        
        // 스케일바의 선
        scaleBarLine = UIView()
        scaleBarLine.backgroundColor = .white
        scaleBarLine.layer.borderWidth = 1
        scaleBarLine.layer.borderColor = UIColor.black.withAlphaComponent(0.5).cgColor
        scaleBarView.addSubview(scaleBarLine)
        
        // 스케일바의 레이블
        scaleBarLabel = UILabel()
        scaleBarLabel.font = UIFont.systemFont(ofSize: 10, weight: .regular)
        scaleBarLabel.textColor = UIColor.black.withAlphaComponent(0.8)
        scaleBarLabel.textAlignment = .center
        scaleBarView.addSubview(scaleBarLabel)
        
        // 레이아웃을 설정
        scaleBarView.translatesAutoresizingMaskIntoConstraints = false
        scaleBarLine.translatesAutoresizingMaskIntoConstraints = false
        scaleBarLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // 고정 너비를 설정
        let fixedContainerWidth: CGFloat = 120
        let initialLineWith: CGFloat = 100 // 초기 라인 너비 (임의)
        
        NSLayoutConstraint.activate([
            // 컨테이너의 위치와 고정 너비
            scaleBarView.leadingAnchor.constraint(equalTo: mapView.leadingAnchor, constant: 16),
            scaleBarView.bottomAnchor.constraint(equalTo: mapView.bottomAnchor, constant: -16),
            scaleBarView.widthAnchor.constraint(equalToConstant: fixedContainerWidth),
            scaleBarView.heightAnchor.constraint(equalToConstant: 30),
            
            // 라인의 위치와 초기 너비/높이
            scaleBarLine.leadingAnchor.constraint(equalTo: scaleBarView.leadingAnchor),
            scaleBarLine.bottomAnchor.constraint(equalTo: scaleBarView.bottomAnchor),
            scaleBarLine.widthAnchor.constraint(equalToConstant: initialLineWith), // 초기값, 동적 변경됨
            scaleBarLine.heightAnchor.constraint(equalToConstant: 4),
            
            // 라벨의 위치
            scaleBarLabel.centerXAnchor.constraint(equalTo: scaleBarLine.centerXAnchor),
            scaleBarLabel.topAnchor.constraint(equalTo: scaleBarLine.bottomAnchor, constant: 2)
        ])
        
        // 초기 텍스트를 설정
        scaleBarLabel.text = "1 km"
        
        // 고정된 눈금을 추가하는 코드를 제거
        // addScaleMarkers(referenceWidth: markerReferenceWidth)
        
        // 스케일바의 초기 업데이트
        updateScaleBar()
    }
    
    // 깔끔한 반올림 거리 계산 (구글 맵 스타일)
    private func calculateNiceRoundedDistance(for distance: Double) -> Double {
        // 300m 이하의 거리도 지원하도록 수정
        if distance < 50 {
            return 50.0
        }
        
        // 최대 거리를 3000m로 제한
        if distance > 3000 {
            return 3000.0
        }
        
        let niceDistances: [Double] = [
            50, 100, 200, 300, 500, 1000, 2000, 3000
        ]
        
        // 적절한 반올림 거리 찾기
        for niceDistance in niceDistances {
            if distance <= niceDistance * 1.5 {
                return niceDistance
            }
        }
        
        return 3000.0 // 최대 3km로 제한
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
        
        // 거리 표시 형식
        let formattedSearchRadius: String
        if searchRadius >= 1000 {
            formattedSearchRadius = String(format: "%.1f km", searchRadius / 1000.0)
        } else {
            formattedSearchRadius = "\(Int(searchRadius)) m"
        }
        
        print("📏 화면에 보이는 실제 반경: \(Int(visibleRadius))m (설정된 반경: \(formattedSearchRadius))")
    }
    
    // 스케일바 거리를 기반으로 검색 반경 업데이트 (완전 동기화)
    private func updateSearchRadiusBasedOnScale(_ scaleDistance: Double) {
        // [기능 비활성화] 핀치 줌으로 인한 반경 변경 기능을 제거
        // 원래 코드는 주석 처리
        /*
        // 검색 반경을 스케일바 거리와 1:1로 매칭 (2배가 아닌 직접 사용)
        // 최소값 300m, 최대값 3000m로 제한
        let calculatedRadius = min(max(scaleDistance, 300.0), 3000.0)
        
        // 표준 반경 값과 매핑 (필요한 경우)
        let standardRadii = [300.0, 500.0, 1000.0, 2000.0, 3000.0]
        
        // 스케일바와 완전히 일치하는 값 사용
        var closestRadius = calculatedRadius
        
        // 이전 값과의 차이가 일정 수준 이상일 때만 업데이트 (너무 잦은 업데이트 방지)
        if abs(closestRadius - searchRadius) / searchRadius > 0.05 || (searchRadius == 0 && closestRadius > 0) { // searchRadius가 0일 때도 업데이트 되도록 조건 추가
            // 출력 형식 - km일 경우 소수점 형식
            let formattedRadius: String
            if closestRadius >= 1000 {
                formattedRadius = String(format: "%.1f km", closestRadius / 1000.0)
            } else {
                formattedRadius = "\(Int(closestRadius)) m"
            }
            
            print("📏 스케일바 기반 반경 업데이트: \(formattedRadius)")
            
            // searchRadius 직접 업데이트 (didSet 호출)
            // 주의: didSet 로직 변경으로 인해 무한 루프 발생 가능성 없음 확인 필요
            // didSet에서 콜백이 제거되었으므로 괜찮음
            searchRadius = closestRadius

            // 반경 레이블 표시 (일시적으로)
            showRadiusLabelTemporarily()

            // --- 추가된 코드 시작 ---
            // SwiftUI 뷰에 변경 사항 알림
            radiusChangeCallback?(closestRadius)
            // --- 추가된 코드 끝 ---
        }
        */
        
        // 반경 변경 없이 현재 반경을 표시만 함 (디버깅용)
        print("📏 핀치 줌 감지됨, 반경 변경 기능 비활성화 (현재 반경: \(searchRadius)m)")
    }
    
    // 스케일바 업데이트
    private func updateScaleBar() {
        // nil 체크 및 필요한 요소 가져오기
        guard let mapView = self.mapView,
              let scaleBarLine = self.scaleBarLine,
              let scaleBarLabel = self.scaleBarLabel,
              let scaleBarView = self.scaleBarView // scaleBarView도 guard에 포함
        else {
            //print("⚠️ 스케일바 업데이트 불가: 지도 또는 UI 요소 미초기화")
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
        
        // 3. 표시할 '깔끔한' 거리 선택 - 최소값 50m, 최대값 3000m으로 제한
        let displayDistance = min(max(calculateNiceRoundedDistance(for: approxDistanceForTargetLength), 50.0), 3000.0)
        
        // 4. 선택된 거리를 표시하기 위한 실제 막대 길이 계산
        let actualBarLengthPoints = pointsPerMeter * displayDistance

        // 최대 길이 제한 (화면 너비의 50%를 넘지 않도록)
        let maxBarLength = min(actualBarLengthPoints, screenWidthPoints * 0.5)
        
        // 5. 텍스트 설정
        let displayText: String
        if displayDistance >= 1000 {
            // 특정 거리는 소수점 한 자리로 표시 (3000m -> 3.0km)
            if displayDistance == 3000 {
                displayText = "3.0 km"
            } else {
                let kmDistance = displayDistance / 1000.0
                displayText = String(format: "%.*f km", kmDistance.truncatingRemainder(dividingBy: 1) == 0 ? 0 : 1, kmDistance)
            }
        } else {
            displayText = "\(Int(displayDistance)) m"
        }
        
        // UI 업데이트 (메인 스레드)
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // 레이블 텍스트 업데이트
            scaleBarLabel.text = displayText
            
            // 스케일바 라인 너비 업데이트
            if let existingConstraint = scaleBarLine.constraints.first(where: { $0.firstAttribute == .width }) {
                existingConstraint.isActive = false
                scaleBarLine.removeConstraint(existingConstraint)
            }
            let newLineConstraint = scaleBarLine.widthAnchor.constraint(equalToConstant: CGFloat(maxBarLength))
            newLineConstraint.isActive = true
        }
        
        // 현재 위치가 설정되어 있고, 프로그램적 줌 변경이 아닐 때만 스케일 기반 반경 업데이트
        if !isProgrammaticZoomChange, let _ = currentLocation { // 플래그 확인 및 위치 확인
             // 핀치 줌에 의한 반경 변경 기능 비활성화
             // updateSearchRadiusBasedOnScale(displayDistance)
        }
    }
    
    // MARK: - GMSMapViewDelegate
    
    // 카메라의 이동이 완료된 후에 호출되는
    func mapView(_ mapView: GMSMapView, didChange position: GMSCameraPosition) {
        // 스케일바를 업데이트
        updateScaleBar()
        
        // 디버깅용: 줌 레벨 변경 시에 표시되는 반경 확인
        debugCheckVisibleRadius()
        
        // 디버깅용
        print("📏 줌 레벨 변경: \(position.zoom)")
    }

    // 지도가 비활성 상태일 때 호출되는 (애니메이션 완료 등)
    func mapView(_ mapView: GMSMapView, idleAt position: GMSCameraPosition) {
        // 카메라의 이동이 중지된 후에 프로그램적인 줌 변경 플래그를 해제
        self.isProgrammaticZoomChange = false
        print("🗺️ 지도 비활성 상태, isProgrammaticZoomChange = false")
    }
    
    // 지도의 로드 완료 시에 호출되는
    func mapViewDidFinishTileRendering(_ mapView: GMSMapView) {
        // 지도 타일 렌더링 완료
        print("🗺️ 지도 타일 렌더링 완료")
    }
    
    // Google로고의 위치를 조정
    private func adjustGoogleLogo() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            if let logoView = self.findGoogleLogo(in: self.mapView) {
                // 로고를 오른쪽 하단으로 이동
                logoView.translatesAutoresizingMaskIntoConstraints = false
                
                // 기존의 제약 제거
                if let superview = logoView.superview {
                    for constraint in superview.constraints {
                        if constraint.firstItem === logoView || constraint.secondItem === logoView {
                            superview.removeConstraint(constraint)
                        }
                    }
                }
                
                // 로고의 사이즈를 강제로 작게 만들기
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
                print("✅ Google로고 위치 조정 완료")
            } else {
                print("⚠️ Google로고를 찾을 수 없습니다")
            }
        }
    }
    
    // Google로고 뷰를 찾기
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
    
    // 반경에 따라 지도의 줌 레벨을 조정
    private func adjustZoomToFitRadius(_ radius: Double) {
        guard let location = currentLocation else { 
            print("⚠️ 현재 위치 정보가 없습니다 줌 조정 실패")
            return 
        }
        
        // 유효한 반경에 제한 (300m ~ 3000m)
        let validRadius = min(max(radius, 300.0), 3000.0)
        
        // 반경에 따른 적절한 줌 레벨 계산 - Google Maps의 특성상 각 값 약간 조정
        var zoomLevel: Float
        
        switch validRadius {
        case ...300:
            zoomLevel = 16.5 // 300m - 정확히 300m가 표시되도록 조정
        case ...500:
            zoomLevel = 16.0 // 500m
        case ...1000:
            zoomLevel = 15.0 // 1km
        case ...2000:
            zoomLevel = 14.0 // 2km
        case ...3000:
            zoomLevel = 13.0 // 3km
        default:
            zoomLevel = 13.0 // 3km 이상은 없지만 안전을 위해 유지
        }
        
        print("🔍 반경 \(validRadius)m에 따른 줌 레벨 조정: \(zoomLevel)")
        
        // 애니메이션과 함께 카메라를 이동 - 현재 위치 중심
        let cameraUpdate = GMSCameraUpdate.setTarget(location.coordinate, zoom: zoomLevel)
        mapView.animate(with: cameraUpdate)

        // 실제 화면에 표시되는 반경 확인 - 디버깅용
        debugCheckVisibleRadius()
    }
    
    // 검색 범위 설정 (버튼 클릭에 대응하는 함수)
    func setSearchRadius(_ radius: Double) {
        // 유효한 범위 확인 (300m~3000m)
        let validRadius = min(max(radius, 300.0), 3000.0)

        print("🎯 지도 검색 범위 설정: \(validRadius)m, 이전: \(searchRadius)m")

        // 반경이 변경된 경우에만 처리
        if abs(searchRadius - validRadius) > 0.1 {
            // --- 수정된 코드 시작 ---
            // searchRadius 설정 전에 플래그를 먼저 설정
            self.isProgrammaticZoomChange = true
            // --- 수정된 코드 끝 ---

            // 검색 범위 설정 (didSet 호출)
            self.searchRadius = validRadius

            // 선택된 반경에 따른 지도 조정 (bounds 기반 통일)
            updateMapZoomForRadius() // 수정: bounds 기반 줌 업데이트 호출
        }
    }
    
    // NativeMapView에서 반경 버튼 클릭 시에 호출되는 메서드
    func handleRadiusButtonTap(radius: Double) {
        setSearchRadius(radius)
    }
    
    // 반경 레이블을 일시적으로 표시
    private func showRadiusLabelTemporarily() {
        // 레이블 표시
        radiusLabel.isHidden = false
        radiusLabel.alpha = 1.0
        
        // 기존의 타이머 취소
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(fadeOutRadiusLabel), object: nil)
        
        // 2초 후에 레이블이 서서히 사라지기
        perform(#selector(fadeOutRadiusLabel), with: nil, afterDelay: 2.0)
    }
    
    @objc private func fadeOutRadiusLabel() {
        // 서서히 사라지는 애니메이션
        UIView.animate(withDuration: 1.0) { [weak self] in
            self?.radiusLabel.alpha = 0.0
        } completion: { [weak self] finished in
            if finished {
                self?.radiusLabel.isHidden = true
                self?.radiusLabel.alpha = 1.0
            }
        }
    }
    
    // 지도의 핀치에 따라 검색 범위를 업데이트 (스케일바와 동기화된 새로운 방법)
    private func updateSearchRadiusFromVisibleRegion() {
        // 스케일바가 업데이트될 때 동시에 검색 범위도 업데이트되므로
        // 여기서는 스케일바 업데이트만 호출
        updateScaleBar()
    }

    // 반경 변경 시 지도 뷰를 업데이트
    private func updateMapZoomForRadius() {
        // radiusCircle의 position과 radius를 사용하여 bounds를 계산
        guard let center = self.radiusCircle?.position else {
            print("⚠️ 반경의 원(radiusCircle)이나 중심(position)을 찾을 수 없습니다 줌 업데이트 실패")
            return
        }
        let radius = self.radiusCircle?.radius ?? self.searchRadius // 만약 circle이 nil인 경우는 searchRadius를 사용

        // 북, 동, 남, 서 방향으로 radius만큼 떨어진 위치 계산
        let northCoord = GMSGeometryOffset(center, radius, 0)    // Heading 0 = North
        let eastCoord  = GMSGeometryOffset(center, radius, 90)   // Heading 90 = East
        let southCoord = GMSGeometryOffset(center, radius, 180)  // Heading 180 = South
        let westCoord  = GMSGeometryOffset(center, radius, 270)  // Heading 270 = West

        // 계산된 위치를 사용하여 북동(NE), 남서(SW) 좌표 생성
        let northEast = CLLocationCoordinate2D(latitude: northCoord.latitude, longitude: eastCoord.longitude)
        let southWest = CLLocationCoordinate2D(latitude: southCoord.latitude, longitude: westCoord.longitude)

        // 최종 bounds 생성
        let bounds = GMSCoordinateBounds(coordinate: southWest, coordinate: northEast)

        // bounds에 맞춰 카메라 업데이트 (패딩 포함)
        let cameraUpdate = GMSCameraUpdate.fit(bounds, withPadding: 50.0) // 50포인트 패딩

        // 애니메이션 시작 전에 플래그 설정
        self.isProgrammaticZoomChange = true
        mapView.animate(with: cameraUpdate)

        print("🗺️ 지도 줌 업데이트 완료: 반경 \(searchRadius)m")
    }

    // MARK: - 레스토랑 마커 관련 메서드
    
    // 레스토랑 마커를 업데이트
    private func updateRestaurantMarkers() {
        // 기존의 마커를 모두 제거
        clearAllRestaurantMarkers()
        
        // 테마가 선택되지 않은 경우는 마커를 추가하지 않음
        if selectedTheme == nil {
            print("🔍 선택된 테마가 없으므로 지도에 표시할 마커가 없습니다")
            return
        }
        
        // 새로운 마커 추가
        for restaurant in restaurants {
            addRestaurantMarker(restaurant)
        }
    }
    
    // 모든 레스토랑 마커를 제거
    private func clearAllRestaurantMarkers() {
        for marker in restaurantMarkers.values {
            marker.map = nil
        }
        restaurantMarkers.removeAll()
    }
    
    // 레스토랑 마커 추가
    private func addRestaurantMarker(_ restaurant: HotPepperRestaurant) {
        let position = CLLocationCoordinate2D(latitude: restaurant.lat, longitude: restaurant.lng)
        let marker = GMSMarker(position: position)
        
        // 마커의 제목과 스니펫을 설정 - Optional 문자열 피하기
        marker.title = restaurant.name
        
        // Optional 값을 안전하게 처리
        if let catchPhrase = restaurant.catchPhrase {
            marker.snippet = catchPhrase
        } else {
            marker.snippet = "정보 없음"
        }
        
        // 거리 표시 (옵션)
        if let distance = restaurant.distance {
            let distanceText = distance < 1000 ? "\(distance)m" : String(format: "%.1fkm", Double(distance) / 1000.0)
            if let catchPhrase = restaurant.catchPhrase {
                marker.snippet = "\(distanceText) - \(catchPhrase)"
            } else {
                marker.snippet = "\(distanceText)"
            }
        }
        
        // 마커 아이콘을 커스터마이즈 (레스토랑 아이콘 사용)
        marker.icon = GMSMarker.markerImage(with: .orange)
        
        // 레스토랑 ID를 마커의 userData에 저장
        marker.userData = restaurant.id
        
        // 지도에 마커 표시
        marker.map = mapView
        
        // 마커 딕셔너리에 저장
        restaurantMarkers[restaurant.id] = marker
    }
    
    // 마커 탭 이벤트 처리
    func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool {
        // 마커의 정보 창 표시
        return false // false를 반환하면 기본 정보 창이 표시됩니다
    }
    
    // 마커 인포 창을 커스터마이즈
    func mapView(_ mapView: GMSMapView, markerInfoWindow marker: GMSMarker) -> UIView? {
        // 커스텀 인포 창 생성
        let infoWindow = UIView(frame: CGRect(x: 0, y: 0, width: 250, height: 100)) // 높이 증가
        infoWindow.backgroundColor = UIColor.white
        infoWindow.layer.cornerRadius = 10
        infoWindow.layer.shadowColor = UIColor.black.cgColor
        infoWindow.layer.shadowOffset = CGSize(width: 0, height: 2)
        infoWindow.layer.shadowOpacity = 0.2
        infoWindow.layer.shadowRadius = 4
        
        // 제목 레이블
        let titleLabel = UILabel(frame: CGRect(x: 15, y: 10, width: 220, height: 30))
        titleLabel.font = UIFont.boldSystemFont(ofSize: 15)
        titleLabel.textColor = UIColor.black
        titleLabel.text = marker.title ?? "이름 없음"
        
        // 스니펫 레이블
        let snippetLabel = UILabel(frame: CGRect(x: 15, y: 40, width: 220, height: 30))
        snippetLabel.font = UIFont.systemFont(ofSize: 13)
        snippetLabel.textColor = UIColor.darkGray
        snippetLabel.text = marker.snippet ?? "정보 없음"
        
        // 상세 버튼 추가 - 하단에 "상세 보기" 버튼 표시
        let detailsButton = UIButton(frame: CGRect(x: 15, y: 70, width: 220, height: 25))
        detailsButton.setTitle("상세 보기 ›", for: .normal)
        detailsButton.setTitleColor(UIColor.systemBlue, for: .normal)
        detailsButton.titleLabel?.font = UIFont.systemFont(ofSize: 13, weight: .medium)
        detailsButton.contentHorizontalAlignment = .right
        
        // 레이블과 버튼 추가
        infoWindow.addSubview(titleLabel)
        infoWindow.addSubview(snippetLabel)
        infoWindow.addSubview(detailsButton)
        
        // 인포 창에 탭 제스처를 추가
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(infoWindowTapped(_:)))
        infoWindow.addGestureRecognizer(tapGesture)
        infoWindow.isUserInteractionEnabled = true
        
        // 마커의 userData에서 restaurantId 가져오기
        if let restaurantId = marker.userData as? String {
            // 태그에 레스토랑 ID 저장 (나중에 식별하기 위함)
            infoWindow.tag = restaurantId.hashValue
            
            // 유저 정의 태그 데이터 추가
            objc_setAssociatedObject(infoWindow, &AssociatedKeys.restaurantId, restaurantId, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        
        return infoWindow
    }
    
    // AssociatedKeys 구조체 (연관 객체 키로 사용)
    private struct AssociatedKeys {
        static var restaurantId = "restaurantId"
    }
    
    // 인포 창 탭 이벤트 처리
    @objc func infoWindowTapped(_ sender: UITapGestureRecognizer) {
        guard let infoWindow = sender.view else { return }
        
        // 연관 객체에서 restaurantId 가져오기
        guard let restaurantId = objc_getAssociatedObject(infoWindow, &AssociatedKeys.restaurantId) as? String else { return }
        
        // restaurantId로 레스토랑 정보 찾기
        if let restaurant = restaurants.first(where: { $0.id == restaurantId }) {
            print("🔍 인포 창 탭: 레스토랑 \(restaurant.name)가 선택됨")
            
            // 콜백 호출하여 상세 페이지로 이동
            onRestaurantSelected?(restaurant)
        }
    }
    
    // 인포 창 탭 델리게이트 메서드 - 이 방법이 더 안정적
    func mapView(_ mapView: GMSMapView, didTapInfoWindowOf marker: GMSMarker) {
        print("🔍 인포 창 탭 델리게이트: 마커 탭됨")
        
        // 마커의 userData에서 restaurantId 가져오기
        if let restaurantId = marker.userData as? String {
            print("🔍 마커에서 레스토랑 ID 찾음: \(restaurantId)")
            
            // restaurantId로 레스토랑 정보 찾기
            if let restaurant = restaurants.first(where: { $0.id == restaurantId }) {
                print("🔍 인포 창 탭 델리게이트: 레스토랑 \(restaurant.name)가 선택됨")
                print("🔍 콜백 함수 존재 확인: \(onRestaurantSelected != nil ? "있습니다" : "없습니다")")
                
                // 콜백 호출하여 상세 페이지로 이동
                DispatchQueue.main.async {
                    self.onRestaurantSelected?(restaurant)
                    print("🔍 레스토랑 선택 콜백 완료: \(restaurant.name)")
                }
            } else {
                print("⚠️ 레스토랑 ID \(restaurantId)에 대응하는 레스토랑을 찾을 수 없습니다")
                print("⚠️ 현재 저장된 레스토랑 수: \(self.restaurants.count)")
            }
        } else {
            print("⚠️ 마커의 userData에서 레스토랑 ID를 찾을 수 없습니다")
            if let userData = marker.userData {
                print("⚠️ userData 타입: \(type(of: userData))")
            } else {
                print("⚠️ userData가 nil입니다")
            }
        }
    }
    
    // 레스토랑 검색 실행
    func searchRestaurants(theme: String? = nil) {
        guard let location = currentLocation else {
            print("⚠️ 현재 위치 정보가 없으므로 검색 실패")
            return
        }
        
        // 테마 파라메터가 제공되는 경우는 해당 값을 사용, 없는 경우는 클래스 속성을 사용
        let themeToUse = theme ?? selectedTheme
        
        // 테마가 선택되지 않은 경우는 기존의 마커를 제거하고 API 호출하지 않음
        if themeToUse == nil {
            print("🔍 선택된 테마가 없으므로 검색하지 않고 기존의 마커를 제거")
            clearAllRestaurantMarkers()
            // 빈 배열을 결과 콜백 호출하여 UI 업데이트
            searchResultsCallback?([])
            return
        }
        
        // 검색 진행 중 표시
        // (필요한 경우는 여기에 구현)
        
        // API 범위값으로 변환
        let rangeValue = getAPIRangeValue(forMeters: searchRadius)
        
        print("🔍 지도에서 검색 요청: 반경 \(searchRadius)m (API값: \(rangeValue))")
        print("🔍 검색 좌표: 위도 \(location.coordinate.latitude), 경도 \(location.coordinate.longitude)")
        print("🔍 선택된 테마: \(themeToUse ?? "")")
        
        // 테마 검색 API 사용
        RestaurantAPI.shared.searchRestaurantsByTheme(
            theme: themeToUse!,
            lat: location.coordinate.latitude,
            lng: location.coordinate.longitude,
            range: rangeValue // 유저가 선택한 반경 사용
        ) { [weak self] restaurants in
            guard let self = self else { return }
            
            // 메인 스레드에서 UI 업데이트
            DispatchQueue.main.async {
                print("📍 테마 API 응답: \(restaurants.count)개의 레스토랑 데이터 수신")
                
                // 결과가 없는 경우 처리
                if restaurants.isEmpty {
                    print("⚠️ 검색 결과가 없습니다")
                    self.restaurants = []
                    self.searchResultsCallback?([])
                    return
                }
                
                // 거리 계산 및 정렬
                var updatedRestaurants = restaurants
                if let userLocation = self.currentLocation {
                    updatedRestaurants = updatedRestaurants.map { restaurant in
                        var updatedRestaurant = restaurant
                        
                        // 레스토랑 위치 설정
                        let restaurantLocation = CLLocation(latitude: restaurant.lat, longitude: restaurant.lng)
                        
                        // 거리 계산 (미터 단위)
                        let distanceInMeters = Int(userLocation.distance(from: restaurantLocation))
                        updatedRestaurant.distance = distanceInMeters
                        updatedRestaurant.userLocation = userLocation
                        
                        return updatedRestaurant
                    }
                    
                    // 거리 순으로 정렬
                    updatedRestaurants.sort { ($0.distance ?? 0) < ($1.distance ?? 0) }
                }
                
                print("✅ 테마 검색 완료: \(updatedRestaurants.count)개의 레스토랑 찾음")
                
                // 검색 결과 업데이트 (didSet 트리거하기 위해 마커 표시)
                self.restaurants = updatedRestaurants
                
                // 검색 결과 콜백 호출
                self.searchResultsCallback?(updatedRestaurants)
            }
        }
    }
    
    // 취소 가능한 서브스크립션 저장
    private var cancellables = Set<AnyCancellable>()
    
    // API 범위값으로 변환 (미터 -> API 사용 범위값)
    private func getAPIRangeValue(forMeters meters: Double) -> Int {
        switch meters {
        case ...300: return 1
        case ...500: return 2
        case ...1000: return 3
        case ...2000: return 4
        default: return 5
        }
    }
}

// 패딩이 있는 레이블 클래스 (UILabel 확장이 아닌 서브클래스를 사용)
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
    // 위치 바인드
    @Binding var mapLocation: CLLocation?
    // 선택된 반경 바인드
    @Binding var selectedRadius: Double
    // 선택된 테마 (옵션)
    var selectedTheme: String?
    // 자동 검색의 유무 (옵션)
    var autoSearch: Bool = true
    // 검색 결과 콜백 (옵션)
    var onSearchResults: (([HotPepperRestaurant]) -> Void)?
    
    // 레스토랑 선택 콜백 추가
    var onRestaurantSelected: ((HotPepperRestaurant) -> Void)?
    
    // UIViewController를 생성
    func makeUIViewController(context: Context) -> MapViewController {
        let viewController = MapViewController()
        viewController.currentLocation = mapLocation
        viewController.searchRadius = selectedRadius
        viewController.selectedTheme = selectedTheme
        
        // 반경 변경 콜백을 설정
        viewController.radiusChangeCallback = { newRadius in
            // 지도에서 반경이 변경될 때마다 부모 뷰의 상태를 업데이트
            DispatchQueue.main.async {
                selectedRadius = newRadius
                
                // 자동 검색이 유효한 경우는 반경 변경 시에 자동으로 검색 실행
                if autoSearch {
                    viewController.searchRestaurants(theme: selectedTheme)
                }
            }
        }
        
        // 검색 결과 콜백을 설정
        viewController.searchResultsCallback = { restaurants in
            DispatchQueue.main.async {
                onSearchResults?(restaurants)
            }
        }
        
        // 레스토랑 선택 콜백을 설정
        viewController.onRestaurantSelected = { restaurant in
            DispatchQueue.main.async {
                onRestaurantSelected?(restaurant)
            }
        }
        
        return viewController
    }
    
    // UIViewController를 업데이트
    func updateUIViewController(_ uiViewController: MapViewController, context: Context) {
        // 위치를 업데이트
        if let location = mapLocation {
            let locationChanged = uiViewController.currentLocation?.coordinate.latitude != location.coordinate.latitude ||
                                 uiViewController.currentLocation?.coordinate.longitude != location.coordinate.longitude
            
            if locationChanged {
                uiViewController.updateLocation(location)
                
                // 자동 검색이 유효한 경우는 위치 변경 시에 자동으로 검색 실행
                if autoSearch {
                    // 약간의 지연을 주어 지도가 업데이트된 후에 검색하도록 함
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        uiViewController.searchRestaurants(theme: selectedTheme)
                    }
                }
            }
        }
        
        // 테마를 업데이트
        let themeChanged = uiViewController.selectedTheme != selectedTheme
        if themeChanged {
            print("⚡️ NativeMapView: 테마 변경 감지 \(uiViewController.selectedTheme ?? "없음") -> \(selectedTheme ?? "없음")")
            uiViewController.selectedTheme = selectedTheme
            
            // 테마가 nil로 변경된 경우에도 업데이트 실행 (selectedTheme 전달)
            if autoSearch || selectedTheme == nil {
                uiViewController.searchRestaurants(theme: selectedTheme)
            }
        }
        
        // 반경을 업데이트
        if abs(uiViewController.searchRadius - selectedRadius) > 0.1 {
            print("⚡️ NativeMapView: 반경 변경 감지 \(uiViewController.searchRadius) -> \(selectedRadius)")
            uiViewController.setSearchRadius(selectedRadius)
            
            // 자동 검색이 유효한 경우는 반경 변경 시에 자동으로 검색 실행
            if autoSearch {
                uiViewController.searchRestaurants(theme: selectedTheme)
            }
        }
        
        // 검색 결과 콜백을 업데이트
        if uiViewController.searchResultsCallback == nil && onSearchResults != nil {
            uiViewController.searchResultsCallback = { restaurants in
                DispatchQueue.main.async {
                    onSearchResults?(restaurants)
                }
            }
        }
    }
} 
