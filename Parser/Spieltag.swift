import Foundation

class Spiel: Codable {
    let heimteam: String
    let gastteam: String
    let heim: Int
    let gast: Int
    let spielpunkte: Int
    let matchkey: Int

    init(heimteam: String, gastteam: String, heim: Int, gast: Int, spielpunkte: Int = 0, key: Int) {
        self.heimteam = heimteam
        self.gastteam = gastteam
        self.heim = heim
        self.gast = gast
        self.spielpunkte = spielpunkte
        self.matchkey = key
    }
}

class Tippspieler: Codable {
    let name: String
    var tipps: [Spiel] = []
    let punkte: Int
    let position: Int
    let bonus: Int
    let siege: Decimal
    let gesamtpunkte: Int
    var positiondiff = 0

    init(name: String, punkte: Int, position: Int, bonus: Int, siege: Decimal, gesamtpunkte: Int) {
        self.name = name
        self.punkte = punkte
        self.position = position
        self.bonus = bonus
        self.siege = siege
        self.gesamtpunkte = gesamtpunkte
    }
}



class Spieltag: Codable {
    init(spieltag: Int) {
        self.spieltag = spieltag
    }
    let spieltag: Int
    var resultate: [Spiel] = []
    var tippspieler: [Tippspieler] = []
}
