import Vapor

struct MatchdayStatisticsController {
    let mdc: MatchdayController
    init(mdc: MatchdayController) {
        self.mdc = mdc
    }

    func getAveragePointsPerMatchday(most: Bool) -> StatisticObject {
        let tipps = self.getAllPointsOfUsersOfMatchdays()
        let result = tipps.averagePointsPerTipp(most: most).getTop(5)
        return StatisticObject.tendenzCounter(result)
    }

    private func getAllPointsOfUsersOfMatchdays() -> [UserTipps] {
        var matchdayTipps: [String: [UserTipp]] = [:]

        self.mdc.matchdays.forEach { matchday in
            let key = "\(matchday.spieltag). Spieltag"
            matchdayTipps[key] = matchday.tippspieler.reduce([]) { $0 + [UserTipp(goalsFor: 0, goalsAgainst: 0, points: $1.punkte)] }
        }
        return matchdayTipps.map { UserTipps(name: $0.key, tipps: $0.value) }
    }

    private func getAllTippsOfMatchdays() -> [UserTipps] {
        var matchdayTipps: [String: [UserTipp]] = [:]

        self.mdc.matchdays.forEach { matchday in
            let key = "\(matchday.spieltag). Spieltag"
            matchdayTipps[key] = matchday.tippspieler.reduce([]) { $0 + $1.tipps.map { tipp in tipp.asUserTipp } }
        }
        return matchdayTipps.map { UserTipps(name: $0.key, tipps: $0.value) }
    }
}
