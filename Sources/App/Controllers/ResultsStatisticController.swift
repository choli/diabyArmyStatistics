import Vapor

struct ResultsStatisticsController {
    let mdc: MatchdayController
    init(mdc: MatchdayController) {
        self.mdc = mdc
    }

    func getAggregatedResults(for team: String) -> AggregatedUserTipp {
        let results = self.getAllResults(of: team)
        var wins = 0, draws = 0, losses = 0, goalsFor = 0, goalsAgainst = 0
        for game in results {
            if game.heimteam == team {
                if game.heim > game.gast { wins += 1 }
                if game.heim == game.gast { draws += 1 }
                if game.heim < game.gast { losses += 1 }
                goalsFor += game.heim
                goalsAgainst += game.gast
            } else if game.gastteam == team {
                if game.heim < game.gast { wins += 1 }
                if game.heim == game.gast { draws += 1 }
                if game.heim > game.gast { losses += 1 }
                goalsFor += game.gast
                goalsAgainst += game.heim
            } else {
                fatalError("This should not happen")
            }
        }
        let tipp = UserTipp(goalsFor: goalsFor, goalsAgainst: goalsAgainst, points: 0)
        return AggregatedUserTipp(name: team, tipp: tipp, siege: wins, unentschieden: draws, niederlagen: losses)
    }

    func getSpecificResult(teamX: Int, teamY: Int) -> TendenzCounter {
        let results = self.allResults.values.reduce([], +)
        let home = results.filter { $0.heim == teamX && $0.gast == teamY }.count
        let away = results.filter { $0.gast == teamX && $0.heim == teamY }.count
        return TendenzCounter(name: "Tatsächlich", heimsiege: home, gastsiege: away, unentschieden: 0)
    }

    func getResultDifference(difference: Int) -> TendenzCounter {
        let results = self.allResults.values.reduce([], +)
        let home = results.filter { $0.heim - $0.gast == difference }.count
        let away = results.filter { $0.gast - $0.heim == difference }.count
        return TendenzCounter(name: "Tatsächlich", heimsiege: home, gastsiege: away, unentschieden: 0)
    }

    private var allResults: [Int: [Spiel]] {
        return self.mdc.matchdays.reduce(into: [:]) { $0[$1.spieltag] = $1.resultate }
    }

    private func getAllResults(of team: String) -> [Spiel] {
        return self.allResults.compactMap { (_, results) in
            results.first { $0.heimteam == team || $0.gastteam == team }
        }
    }
}
