import Vapor

public struct Spiel: Content {
    public let heimteam: String
    public let gastteam: String
    public let heim: Int
    public let gast: Int
}

public struct Tippspieler: Content {
    public let name: String
    public let tipps: [Spiel]
    public let punkte: Int
    public let position: Int
}

public struct Spieltag: Content {
    public let resultate: [Spiel]
    public let tippspieler: [Tippspieler]
}
