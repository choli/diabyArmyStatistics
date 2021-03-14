import Vapor

infix operator %% : ComparisonPrecedence

protocol TotalEquatable: Equatable {
    static func %%(lhs: Self, rhs: Self) -> Bool
}

struct Spiel: Content {
    let heimteam: String
    let gastteam: String
    let heim: Int
    let gast: Int
    let spielpunkte: Int

    var asUserTipp: UserTipp {
        return UserTipp(goalsFor: heim, goalsAgainst: gast, points: spielpunkte)
    }
}

struct Tippspieler: Content {
    let name: String
    let tipps: [Spiel]
    let punkte: Int
    let position: Int
    let bonus: Int
    let siege: Decimal
    let gesamtpunkte: Int
    let spieltagssieger: Bool?
    var drawTipper: DrawArray.Tipper?

    var hashValue: Int {
        var hasher = Hasher()
        hasher.combine(self.name)
        hasher.combine(self.position)
        return hasher.finalize()
    }
}

struct Spieltag: Content {
    let resultate: [Spiel]
    let tippspieler: [Tippspieler]
    let spieltag: Int
}

struct SpieltagFacts: Content {
    let spieltag: Int
    let spieltagssieger: [String]
    let punkteAvg: Double
}

struct UserTipp: Content {
    let goalsFor: Int
    let goalsAgainst: Int
    let points: Int

    // Computed properties
    var difference: Int {
        return goalsFor - goalsAgainst
    }
}

struct UserTipps: Content {
    let name: String
    let tipps: [UserTipp]
}

struct AggregatedUserTipp: Content, TotalEquatable {
    let name: String
    let tipp: UserTipp
    let siege: Int
    let unentschieden: Int
    let niederlagen: Int

    static func ==(lhs: AggregatedUserTipp, rhs: AggregatedUserTipp) -> Bool {
        return lhs.tipp.goalsFor == rhs.tipp.goalsFor && lhs.tipp.goalsAgainst == rhs.tipp.goalsAgainst
    }

    static func %%(lhs: AggregatedUserTipp, rhs: AggregatedUserTipp) -> Bool {
        return lhs.tipp.goalsFor + lhs.tipp.goalsAgainst == rhs.tipp.goalsFor + rhs.tipp.goalsAgainst
    }
}


struct TendenzCounter: Content, TotalEquatable {
    let name: String
    let heimsiege: Int
    let gastsiege: Int
    let unentschieden: Int

    let average: Double?


    init(name: String, heimsiege: Int, gastsiege: Int, unentschieden: Int, average: Double? = nil) {
        self.name = name
        self.heimsiege = heimsiege
        self.gastsiege = gastsiege
        self.unentschieden = unentschieden
        self.average = average
    }


    static func ==(lhs: TendenzCounter, rhs: TendenzCounter) -> Bool {
        return lhs.heimsiege == rhs.heimsiege && lhs.gastsiege == rhs.gastsiege && lhs.unentschieden == rhs.unentschieden
    }

    static func %%(lhs: TendenzCounter, rhs: TendenzCounter) -> Bool {
        return lhs.heimsiege + lhs.gastsiege + lhs.unentschieden == rhs.heimsiege + rhs.gastsiege + rhs.unentschieden
    }
}

struct TendenzCounterWithResult: Content {
    let result: TendenzCounter
    let tipps: [TendenzCounter]
}

enum Tendenz {
    case heimsieg
    case unentschieden
    case gastsieg
    case total
}

struct KnockOutDuel: Content {
    enum TieBreaker {
        case gesamtpunkte
        case mehrExakteTipps
    }

    let spielnummer: Int
    let tipperA: Tippspieler
    let tipperB: Tippspieler
    let positionA: Int
    let positionB: Int
    let punkteA: Int?
    let punkteB: Int?
    let winner: Int // winner: 0 for none, 1 for A, 2 for B
    init(spielnummer: Int, tipperA: Tippspieler, tipperB: Tippspieler, positionA: Int, positionB: Int, punkteA: Int?, punkteB: Int?, tieBreaker: TieBreaker) {
        self.spielnummer = spielnummer
        self.tipperA = tipperA
        self.tipperB = tipperB
        self.positionA = positionA
        self.positionB = positionB
        self.punkteA = punkteA
        self.punkteB = punkteB

        if let pointsA = punkteA, let pointsB = punkteB {
            if pointsA == pointsB {
                switch tieBreaker {
                case .gesamtpunkte:
                    self.winner = tipperA.gesamtpunkte + pointsA > tipperB.gesamtpunkte + pointsB ? 1 : 2
                case .mehrExakteTipps:
                    let exactA = tipperA.tipps.filter { $0.spielpunkte == Constants.MatchPoints.exactResult.rawValue }.count
                    let exactB = tipperB.tipps.filter { $0.spielpunkte == Constants.MatchPoints.exactResult.rawValue }.count
                    if exactA == exactB {
                        let correctDiffA = tipperA.tipps.filter { $0.spielpunkte == Constants.MatchPoints.correctDiff.rawValue }.count
                        let correctDiffB = tipperB.tipps.filter { $0.spielpunkte == Constants.MatchPoints.correctDiff.rawValue }.count
                        if correctDiffA == correctDiffB {
                            self.winner = positionA < positionB ? 1 : 2
                        } else {
                            self.winner = correctDiffA > correctDiffB ? 1 : 2
                        }
                    } else {
                        self.winner = exactA > exactB ? 1 : 2
                    }
                }
            } else {
                self.winner = pointsA > pointsB ? 1 : 2
            }
        } else {
            self.winner = 0
        }
        
    }

    init(withWildcard spielnummer: Int, tipper: Tippspieler, position: Int) {
        self.spielnummer = spielnummer
        self.tipperA = tipper
        self.tipperB = Tippspieler(name: "Freilos", tipps: [], punkte: 0, position: 0, bonus: 0, siege: 0, gesamtpunkte: -1, spieltagssieger: nil)
        self.positionA = position
        self.positionB = 0
        self.punkteA = nil
        self.punkteB = nil
        self.winner = 1
    }
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
            let points = $0.tipps.reduce(0) { x,y in x + y.points }
            let wins = $0.tipps.filter { tipp in tipp.goalsFor > tipp.goalsAgainst }.count
            let draws = $0.tipps.filter { tipp in tipp.goalsFor == tipp.goalsAgainst }.count
            let losses = $0.tipps.filter { tipp in tipp.goalsFor < tipp.goalsAgainst }.count
            let tipp = UserTipp(goalsFor: goalsFor, goalsAgainst: goalsAgainst, points: points)
            return AggregatedUserTipp(name: $0.name, tipp: tipp, siege: wins, unentschieden: draws, niederlagen: losses)
        }
        .sorted {
            let points0 = $0.siege * 3 + $0.unentschieden * 1
            let points1 = $1.siege * 3 + $1.unentschieden * 1
            let count0 = $0.siege + $0.unentschieden + $0.niederlagen
            let count1 = $1.siege + $1.unentschieden + $1.niederlagen
            let pointsAvg0 = Double(points0) / Double(Swift.max(count0, 1))
            let pointsAvg1 = Double(points1) / Double(Swift.max(count1, 1))
            if descending {
                if points0 != points1 { return points0 > points1 }
                if $0.siege != $1.siege { return $0.siege > $1.siege }
                if $0.unentschieden != $1.unentschieden { return $0.unentschieden > $1.unentschieden }
                if $0.niederlagen != $1.niederlagen { return $0.niederlagen < $1.niederlagen } // Just for my inner Monk
                if $0.tipp.difference != $1.tipp.difference { return $0.tipp.difference > $1.tipp.difference}
                if $0.tipp.goalsFor != $1.tipp.goalsFor { return $0.tipp.goalsFor > $1.tipp.goalsFor }
            } else {
                if pointsAvg0 != pointsAvg1 { return pointsAvg0 < pointsAvg1 }
                if count0 != count1 { return count0 > count1 }
                if $0.niederlagen != $1.niederlagen { return $0.niederlagen > $1.niederlagen }
                if $0.unentschieden != $1.unentschieden { return $0.unentschieden > $1.unentschieden }
                if $0.siege != $1.siege { return $0.siege < $1.siege } // see above
                if $0.tipp.difference != $1.tipp.difference { return $0.tipp.difference < $1.tipp.difference}
                if $0.tipp.goalsFor != $1.tipp.goalsFor { return $0.tipp.goalsFor < $1.tipp.goalsFor }
            }
            return $0.name < $1.name
        }
    }

    var summedUpTippPoints: [TendenzCounter] {
        self.map { userTipps -> TendenzCounter in
            let points = userTipps.tipps.reduce(0) { x,y in x + y.points }
            return TendenzCounter(name: userTipps.name, heimsiege: points, gastsiege: 0, unentschieden: 0)
        }
        .sortTotal()
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

    func countGoals(most: Bool) -> [TendenzCounter] {
        let all = self.map { userTipps -> TendenzCounter in
            let home = userTipps.tipps.reduce(0) { $0 + $1.goalsFor }
            let away = userTipps.tipps.reduce(0) { $0 + $1.goalsAgainst }

            let avg = round((Double(home) + Double(away)) / Double(Swift.max(userTipps.tipps.count, 1)) * 100.0) / 100.0

            return TendenzCounter(name: userTipps.name, heimsiege: home, gastsiege: away, unentschieden: 0, average: avg)
        }
        return all.sortAverage(descending: most)
    }

    func averagePointsPerTipp(most: Bool) -> [TendenzCounter] {
        let all = self.map { userTipps -> TendenzCounter in
            let points = userTipps.tipps.reduce(0) { $0 + $1.points }
            let avg = round(Double(points) / Double(Swift.max(userTipps.tipps.count, 1)) * 100.0) / 100.0
            return TendenzCounter(name: userTipps.name, heimsiege: points, gastsiege: 0, unentschieden: userTipps.tipps.count, average: avg)
        }
        return all.sortAverage(descending: most)
    }
}

extension Array where Element: TotalEquatable {
    func getTop(_ x: Int, total: Bool = false) -> [Element] {
        guard x > 0, self.count > x else { return self }
        let elementX = self[x - 1]

        var i = x
        while (i < self.count && (total ? self[i] %% elementX : self[i] == elementX)) {
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

    func sortTotal(descending: Bool = true) -> [TendenzCounter] {
        self.sorted {
            let total0 = $0.heimsiege + $0.gastsiege
            let total1 = $1.heimsiege + $1.gastsiege
            if total0 != total1 { return descending ? total0 > total1 : total0 < total1 }
            if $0.heimsiege != $1.heimsiege { return descending ? $0.heimsiege > $1.heimsiege : $0.heimsiege < $1.heimsiege }
            return $0.name < $1.name
        }
    }

    func sortAverage(descending: Bool = true) -> [TendenzCounter] {
        self.filter { $0.heimsiege + $0.gastsiege > 0 }
            .sorted {
                if let avg0 = $0.average, let avg1 = $1.average, avg0 != avg1 { return descending ? avg0 > avg1 : avg0 < avg1 }
                if $0.heimsiege != $1.heimsiege { return descending ? $0.heimsiege > $1.heimsiege : $0.heimsiege < $1.heimsiege }
                return $0.name < $1.name
            }
    }

    var cutOffEmpty: [TendenzCounter] {
        self.filter { $0.heimsiege + $0.gastsiege + $0.unentschieden > 0 }
    }
}
