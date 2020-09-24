import Vapor

struct Spiel: Content {
    let heimteam: String
    let gastteam: String
    let heim: Int
    let gast: Int

    var asUserTipp: UserTipp {
        return UserTipp(goalsFor: heim, goalsAgainst: gast)
    }
}

struct Tippspieler: Content {
    let name: String
    let tipps: [Spiel]
    let punkte: Int
    let position: Int
}

struct Spieltag: Content {
    let resultate: [Spiel]
    let tippspieler: [Tippspieler]
    let spieltag: Int
}

struct UserTipp: Content {
    let goalsFor: Int
    let goalsAgainst: Int

    // Computed properties
    var difference: Int {
        return goalsFor - goalsAgainst
    }
}

struct UserTipps: Content {
    let name: String
    let tipps: [UserTipp]
}

struct AggregatedUserTipp: Content, Equatable {
    let name: String
    let tipp: UserTipp
    let siege: Int
    let unentschieden: Int
    let niederlagen: Int

    static func ==(lhs: AggregatedUserTipp, rhs: AggregatedUserTipp) -> Bool {
        return lhs.tipp.goalsFor == rhs.tipp.goalsFor && lhs.tipp.goalsAgainst == rhs.tipp.goalsAgainst
    }
}

struct TendenzCounter: Content, Equatable {
    let name: String
    let heimsiege: Int
    let gastsiege: Int
    let unentschieden: Int

    static func ==(lhs: TendenzCounter, rhs: TendenzCounter) -> Bool {
        return lhs.heimsiege == rhs.heimsiege && lhs.gastsiege == rhs.gastsiege && lhs.unentschieden == rhs.unentschieden
    }
}

enum StatisticObject: Encodable {
    case aggregatedUserTipp([AggregatedUserTipp])
    case tendenzCounter([TendenzCounter])

    func encode(to encoder: Encoder) throws {
        switch self {
        case .aggregatedUserTipp(let aggregatedTipp):
            try? aggregatedTipp.encode(to: encoder)
        case .tendenzCounter(let tendenzCounter):
            try? tendenzCounter.encode(to: encoder)
        }
    }
}

enum Tendenz {
    case heimsieg
    case unentschieden
    case gastsieg
}

extension Array where Element == UserTipps {
    func summedUpAndSorted(descending: Bool) -> [AggregatedUserTipp] {
        return self.map {
            let goalsFor = $0.tipps.reduce(0) { x,y in x + y.goalsFor }
            let goalsAgainst = $0.tipps.reduce(0) { x,y in x + y.goalsAgainst }
            let wins = $0.tipps.filter { tipp in tipp.goalsFor > tipp.goalsAgainst }.count
            let draws = $0.tipps.filter { tipp in tipp.goalsFor == tipp.goalsAgainst }.count
            let losses = $0.tipps.filter { tipp in tipp.goalsFor < tipp.goalsAgainst }.count
            let tipp = UserTipp(goalsFor: goalsFor, goalsAgainst: goalsAgainst)
            return AggregatedUserTipp(name: $0.name, tipp: tipp, siege: wins, unentschieden: draws, niederlagen: losses)
        }
        .sorted {
            if descending {
                if $0.siege != $1.siege { return $0.siege > $1.siege }
                if $0.unentschieden != $1.unentschieden { return $0.unentschieden > $1.unentschieden }
                if $0.niederlagen != $1.niederlagen { return $0.niederlagen < $1.niederlagen } // Just for my inner Monk
                if $0.tipp.difference != $1.tipp.difference { return $0.tipp.difference > $1.tipp.difference}
                if $0.tipp.goalsFor != $1.tipp.goalsFor { return $0.tipp.goalsFor > $1.tipp.goalsFor }
            } else {
                if $0.niederlagen != $1.niederlagen { return $0.niederlagen > $1.niederlagen }
                if $0.unentschieden != $1.unentschieden { return $0.unentschieden < $1.unentschieden }
                if $0.siege != $1.siege { return $0.siege < $1.siege } // see above
                if $0.tipp.difference != $1.tipp.difference { return $0.tipp.difference < $1.tipp.difference}
                if $0.tipp.goalsFor != $1.tipp.goalsFor { return $0.tipp.goalsFor < $1.tipp.goalsFor }
            }
            return $0.name < $1.name
        }
    }

    var convertedToTendencies: [TendenzCounter] {
        self.map { userTipps -> TendenzCounter in
            let home = userTipps.tipps.filter { $0.goalsFor > $0.goalsAgainst }.count
            let away = userTipps.tipps.filter { $0.goalsFor < $0.goalsAgainst }.count
            let draw = userTipps.tipps.filter { $0.goalsFor == $0.goalsAgainst }.count
            return TendenzCounter(name: userTipps.name, heimsiege: home, gastsiege: away, unentschieden: draw)
        }
    }
}

extension Array where Element: Equatable {
    func getTop(_ x: Int) -> [Element] {
        guard x > 0, self.count > x else { return self }
        let elementX = self[x - 1]

        var i = x
        while (i < self.count && self[i] == elementX) {
            i += 1
        }

        return Array(self.prefix(i))
    }
}

extension Array where Element == TendenzCounter {
    func sorted(by tendency: Tendenz) -> [TendenzCounter] {
        self.sorted {
            switch tendency {
            case .heimsieg:
                if $0.heimsiege != $1.heimsiege { return $0.heimsiege > $1.heimsiege }
                if $0.unentschieden != $1.unentschieden { return $0.unentschieden > $1.unentschieden }
                if $0.gastsiege != $1.gastsiege { return $0.gastsiege > $1.gastsiege }
            case .gastsieg:
                if $0.gastsiege != $1.gastsiege { return $0.gastsiege > $1.gastsiege }
                if $0.unentschieden != $1.unentschieden { return $0.unentschieden > $1.unentschieden }
                if $0.heimsiege != $1.heimsiege { return $0.heimsiege > $1.heimsiege }
            case .unentschieden:
                if $0.unentschieden != $1.unentschieden { return $0.unentschieden > $1.unentschieden }
                if $0.heimsiege != $1.heimsiege { return $0.heimsiege > $1.heimsiege }
                if $0.gastsiege != $1.gastsiege { return $0.gastsiege > $1.gastsiege }
            }
            return $0.name < $1.name
        }
    }
}
