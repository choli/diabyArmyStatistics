import Vapor

struct MatchdayStatisticsController: RouteCollection {
    let mdc: MatchdayController
    init(mdc: MatchdayController) {
        self.mdc = mdc
    }

    func boot(routes: RoutesBuilder) throws {

        routes.get("matchdays") { (req) -> EventLoopFuture<View> in
            return req.view.render(
                "matchdayStats",
                ["matchdays": getMatchdayFacts()]
            )
        }
    }

    func getAveragePointsPerMatchday(most: Bool) -> StatisticObject {
        let tipps = self.getAllPointsOfUsersOfMatchdays()
        let result = tipps.averagePointsPerTipp(most: most).getTop(5)
        return StatisticObject.tendenzCounter(result)
    }

    private func getMatchdayFacts() -> StatisticObject {
        let mdFacts = mdc.matchdays.map { matchday -> SpieltagFacts in
            let matchdayWinners = matchday.tippspieler.filter { $0.spieltagssieger == true }.map { $0.name }
            let actualTipper = matchday.tippspieler.filter { $0.tipps.count > 0 }
            let avgPoints = round(Double(actualTipper.reduce(0) { $0 + $1.punkte }) / Double(actualTipper.count) * 100.0) / 100.0
            return SpieltagFacts(spieltag: matchday.spieltag, spieltagssieger: matchdayWinners, punkteAvg: avgPoints)
        }
        return StatisticObject.spieltagFacts(mdFacts)
    }

    private func getAllPointsOfUsersOfMatchdays() -> [UserTipps] {
        var matchdayTipps: [String: [UserTipp]] = [:]

        mdc.matchdays.forEach { matchday in
            let key = "\(matchday.spieltag). Spieltag"
            let actualTipper = matchday.tippspieler.filter { $0.tipps.count > 0 }
            matchdayTipps[key] = actualTipper.reduce([]) { $0 + [UserTipp(goalsFor: 0, goalsAgainst: 0, points: $1.punkte)] }
        }
        return matchdayTipps.map { UserTipps(name: $0.key, tipps: $0.value) }
    }

    private func getAllTippsOfMatchdays() -> [UserTipps] {
        var matchdayTipps: [String: [UserTipp]] = [:]

        mdc.matchdays.forEach { matchday in
            let key = "\(matchday.spieltag). Spieltag"
            let actualTipper = matchday.tippspieler.filter { $0.tipps.count > 0 }
            matchdayTipps[key] = actualTipper.reduce([]) { $0 + $1.tipps.map { tipp in tipp.asUserTipp } }
        }
        return matchdayTipps.map { UserTipps(name: $0.key, tipps: $0.value) }
    }
}
