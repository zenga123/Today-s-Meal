import Foundation
import CoreLocation

// MARK: - Root response
struct HotPepperResponse: Codable {
    let results: Results
}

struct Results: Codable {
    let apiVersion: String
    let resultsAvailable: Int
    let resultsReturned: String
    let resultsStart: Int
    let shop: [Restaurant]
    
    enum CodingKeys: String, CodingKey {
        case apiVersion = "api_version"
        case resultsAvailable = "results_available"
        case resultsReturned = "results_returned"
        case resultsStart = "results_start"
        case shop
    }
}

// MARK: - Restaurant
struct Restaurant: Codable, Identifiable {
    let id: String
    let name: String
    let logoImage: String
    let nameKana: String
    let address: String
    let stationName: String
    let ktaiCoupon: Int
    let largeServiceArea: Area
    let serviceArea: Area
    let largeArea: Area
    let middleArea: Area
    let smallArea: Area
    let lat: Double
    let lng: Double
    let genre: Genre
    let subGenre: Genre
    let budget: Budget
    let budgetMemo: String
    let catchPhrase: String
    let capacity: Int
    let access: String
    let mobileAccess: String
    let urls: URLS
    let photo: Photo
    let open: String
    let close: String
    let wifi: String
    let wedding: String
    let course: String
    let freeDrink: String
    let freeFood: String
    let privateRoom: String
    let horigotatsu: String
    let tatami: String
    let card: String
    let nonSmoking: String
    let charter: String
    let parking: String
    let barrierFree: String
    let otherMemo: String
    let sommelier: String
    let openAir: String
    let show: String
    let karaoke: String
    let band: String
    let tv: String
    let english: String
    let pet: String
    let child: String
    
    // 지도 관련 추가 속성 (코드에서 설정)
    var distance: Int?
    var userLocation: CLLocation?
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case logoImage = "logo_image"
        case nameKana = "name_kana"
        case address
        case stationName = "station_name"
        case ktaiCoupon = "ktai_coupon"
        case largeServiceArea = "large_service_area"
        case serviceArea = "service_area"
        case largeArea = "large_area"
        case middleArea = "middle_area"
        case smallArea = "small_area"
        case lat
        case lng
        case genre
        case subGenre = "sub_genre"
        case budget
        case budgetMemo = "budget_memo"
        case catchPhrase = "catch"
        case capacity
        case access
        case mobileAccess = "mobile_access"
        case urls
        case photo
        case open
        case close
        case wifi
        case wedding
        case course
        case freeDrink = "free_drink"
        case freeFood = "free_food"
        case privateRoom = "private_room"
        case horigotatsu
        case tatami
        case card
        case nonSmoking = "non_smoking"
        case charter
        case parking
        case barrierFree = "barrier_free"
        case otherMemo = "other_memo"
        case sommelier
        case openAir = "open_air"
        case show
        case karaoke
        case band
        case tv
        case english
        case pet
        case child
    }
}

struct Area: Codable {
    let code: String
    let name: String
}

struct Genre: Codable {
    let code: String
    let name: String
    let catchPhrase: String
    
    enum CodingKeys: String, CodingKey {
        case code
        case name
        case catchPhrase = "catch"
    }
}

struct Budget: Codable {
    let code: String
    let name: String
    let average: String
}

struct URLS: Codable {
    let pc: String
    let mobile: String
}

struct Photo: Codable {
    let pc: PC
    let mobile: Mobile
}

struct PC: Codable {
    let l: String
    let m: String
    let s: String
}

struct Mobile: Codable {
    let l: String
    let s: String
} 