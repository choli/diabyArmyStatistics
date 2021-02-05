
import Vapor

struct DrawArray: Content {
    struct Tipper: Content {
        let name: String
        let customTwitterHandle: String?
        let tweetLink: String?
        let twitterHandle: String

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let decName = try container.decode(String.self, forKey: .name)
            name = decName
            customTwitterHandle = try? container.decode(String?.self, forKey: .customTwitterHandle)
            tweetLink = try? container.decode(String?.self, forKey: .tweetLink)
            twitterHandle = customTwitterHandle ?? decName
        }

        private enum CodingKeys: String, CodingKey {
            case name
            case customTwitterHandle
            case tweetLink
            case twitterHandle
        }
    }
    let nichtGezogeneUser: [Tipper]?
    let ausgelosteUser: [Tipper]
}
