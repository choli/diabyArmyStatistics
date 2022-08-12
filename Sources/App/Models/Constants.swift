import Foundation

enum Constants {
    enum MatchPoints: Int {
        case exactResult = 4
        case correctDiff = 3
        case correctWinner = 2
        case noPoints = 0
    }

    enum Season: String {
        case season2021 = "2021"
        case season2122 = "2122"
        case season2223 = "2223"

        static var currentSeason: String {
            return Self.season2223.rawValue
        }
    }
}
