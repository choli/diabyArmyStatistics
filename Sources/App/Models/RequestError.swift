import Vapor

struct RequestErrorObject: AbortError {
    var status: HTTPResponseStatus {
        switch error {
        case .unknownMatchday:
            return HTTPResponseStatus(statusCode: 404, reasonPhrase: "This matchday has not yet been played")
        default:
            return HTTPResponseStatus(statusCode: 500, reasonPhrase: "Server error")
        }
    }

    let error: RequestError

    init(error: RequestError) {
        self.error = error
    }
}


enum RequestError: Error {
    case unknownMatchday
    case matchdayNotRegistered
    case couldNotParseMatchday
    case couldNotParseTeam
}
