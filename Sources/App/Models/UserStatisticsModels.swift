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

enum Tendenz {
    case heimsieg
    case unentschieden
    case gastsieg
    case total
}

extension Array where Element == Spiel {
    func getCorrectTippTendencies(for results: [Spiel]) -> [Tendenz: Int] {
        var correct: [Tendenz: Int] = [.heimsieg: 0, .unentschieden: 0, .gastsieg: 0]
        self.forEach { userTipp in
            guard let result = results.first(where: { $0.heimteam == userTipp.heimteam && $0.gastteam == userTipp.gastteam })
            else {  fatalError("Match not played on this matchday") }

            if result.heim > result.gast && userTipp.heim > userTipp.gast {
                correct[.heimsieg]! += 1
            } else if result.heim == result.gast && userTipp.heim == userTipp.gast {
                correct[.unentschieden]! += 1
            } else if result.heim < result.gast && userTipp.heim < userTipp.gast {
                correct[.gastsieg]! += 1
            }
        }
        return correct
    }
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
            let points0 = $0.siege * 3 + $0.unentschieden * 1
            let points1 = $1.siege * 3 + $1.unentschieden * 1
            if descending {
                if points0 != points1 { return points0 > points1 }
                if $0.siege != $1.siege { return $0.siege > $1.siege }
                if $0.unentschieden != $1.unentschieden { return $0.unentschieden > $1.unentschieden }
                if $0.niederlagen != $1.niederlagen { return $0.niederlagen < $1.niederlagen } // Just for my inner Monk
                if $0.tipp.difference != $1.tipp.difference { return $0.tipp.difference > $1.tipp.difference}
                if $0.tipp.goalsFor != $1.tipp.goalsFor { return $0.tipp.goalsFor > $1.tipp.goalsFor }
            } else {
                if points0 != points1 { return points0 < points1 }
                if $0.niederlagen != $1.niederlagen { return $0.niederlagen > $1.niederlagen }
                if $0.unentschieden != $1.unentschieden { return $0.unentschieden > $1.unentschieden }
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

    func countTipps(teamX: Int, teamY: Int) -> [TendenzCounter] {
        self.map { userTipps -> TendenzCounter in
            let home = userTipps.tipps.filter { $0.goalsFor == teamX && $0.goalsAgainst == teamY }.count
            let away = userTipps.tipps.filter { $0.goalsAgainst == teamX && $0.goalsFor == teamY }.count
            return TendenzCounter(name: userTipps.name, heimsiege: home, gastsiege: away, unentschieden: 0)
        }
        .sortTotal()
    }

    func countTipps(difference: Int) -> [TendenzCounter] {
        self.map { userTipps -> TendenzCounter in
            let home = userTipps.tipps.filter { $0.goalsFor - $0.goalsAgainst == difference }.count
            let away = userTipps.tipps.filter { $0.goalsAgainst - $0.goalsFor == difference }.count
            return TendenzCounter(name: userTipps.name, heimsiege: home, gastsiege: away, unentschieden: 0)
        }
        .sortTotal()
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
            case .total:
                let first = $0.heimsiege + $0.unentschieden + $0.gastsiege
                let second = $1.heimsiege + $1.unentschieden + $1.gastsiege
                if first != second { return first > second }
            }
            return $0.name < $1.name
        }
    }

    func sortTotal() -> [TendenzCounter] {
        self.sorted {
            guard $0.unentschieden == 0, $1.unentschieden == 0 else {
                fatalError("Data is corrupt")
            }
            if ($1.name == "ErbederElfen" || $0.name == "ErbederElfen") && ($1.name == "Janek" || $0.name == "Janek") {
                print("hallo")
            }
            let total0 = $0.heimsiege + $0.gastsiege
            let total1 = $1.heimsiege + $1.gastsiege
            if total0 != total1 { return total0 > total1 }
            if $0.heimsiege != $1.heimsiege { return $0.heimsiege > $1.heimsiege }
            return $0.name < $1.name
        }
    }
}
