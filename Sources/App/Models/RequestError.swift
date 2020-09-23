import Foundation

enum RequstError: Error {
    case unknownMatchday
    case matchdayNotRegistered
    case couldNotParseMatchday
    case couldNotParseTeam
}
