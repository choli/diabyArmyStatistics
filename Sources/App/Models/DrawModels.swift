
import Vapor

struct DrawTipperArray: Content {
    let nonDrawnUser: [DrawTipper]?
    let drawnUser: [DrawTipper]
}

struct DrawTagTeamArray: Content {
    let nonDrawnTeams: [DrawTagTeam]?
    let drawnTeams: [DrawTagTeam]
}

struct DrawTipper: Content {
    let name: String
    let twitterHandle: String
    let tweetLink: String?
    let order: Int?

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let decName = try container.decode(String.self, forKey: .name)
        name = decName
        twitterHandle = (try? container.decode(String?.self, forKey: .twitterHandle)) ?? decName
        tweetLink = try? container.decode(String?.self, forKey: .tweetLink)
        order = try? container.decode(Int?.self, forKey: .order)
    }

    init(with registration: Registration) {
        name = registration.kicktippname
        twitterHandle = registration.twittername
        tweetLink = nil
        order = registration.order
    }

    private enum CodingKeys: String, CodingKey {
        case name
        case twitterHandle
        case tweetLink
        case order
    }
}

struct DrawTagTeam: Content {
    let teamname: String
    let teamplayerA: DrawTipper
    let teamplayerB: DrawTipper
}
