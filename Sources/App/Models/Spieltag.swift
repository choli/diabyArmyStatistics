import Vapor

struct Spiel: Content {
    let heimteam: String
    let gastteam: String
    let heim: Int
    let gast: Int
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

struct TeamTipp: Content {
    let goalsFor: Int
    let goalsAgainst: Int

    // Computed properties
    var difference: Int {
        return goalsFor - goalsAgainst
    }
}

struct TeamTipps: Content {
    let name: String
    let tipps: [TeamTipp]
}

struct AggregatedTeamTipp: Content {
    let name: String
    let tipp: TeamTipp

    func equalTo(_ other: AggregatedTeamTipp) -> Bool {
        return self.tipp.goalsFor == other.tipp.goalsFor && self.tipp.goalsAgainst == other.tipp.goalsAgainst
    }
}

extension Array where Element == TeamTipps {
    func summedUpAndSorted(descending: Bool = true) -> [AggregatedTeamTipp] {
        return self.map {
            let goalsFor = $0.tipps.reduce(0) { x,y in x + y.goalsFor }
            let goalsAgainst = $0.tipps.reduce(0) { x,y in x + y.goalsAgainst }
            let tipp = TeamTipp(goalsFor: goalsFor, goalsAgainst: goalsAgainst)
            return AggregatedTeamTipp(name: $0.name, tipp: tipp)
        }
        .sorted {
            if $0.tipp.difference == $1.tipp.difference {
                if $0.tipp.goalsFor == $1.tipp.goalsFor {
                    return $0.name < $1.name
                } else {
                    return ($0.tipp.goalsFor > $1.tipp.goalsFor) == descending
                }
            } else {
                return ($0.tipp.difference > $1.tipp.difference) == descending
            }
        }
    }
}

extension Array where Element == AggregatedTeamTipp {
    func getTop(_ x: Int) -> [AggregatedTeamTipp] {
        guard x > 0, self.count > x else { return self }
        let elementX = self[x - 1]

        var i = x
        while (i < self.count && self[i].equalTo(elementX)) {
            i += 1
        }

        return Array(self.prefix(i))
    }

}
