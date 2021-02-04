
import Vapor

struct DrawArray: Content {
    struct Tipper: Content {
        let name: String
        let twitterHandle: String?
        let tweetLink: String?
    }
    let nichtGezogeneUser: [Tipper]?
    let ausgelosteUser: [Tipper]
}
