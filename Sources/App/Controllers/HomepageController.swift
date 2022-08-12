import Vapor

struct HomepageController: RouteCollection {
    let mdc: MatchdayController
    init(mdc: MatchdayController) {
        self.mdc = mdc
    }

    func boot(routes: RoutesBuilder) throws {
        routes.get(use: getHomeStats)
        routes.get("halloffame") { (req) -> EventLoopFuture<View> in
            req.view.render("Pokal/hallOfFame", ["":""])
        }
        routes.get("girlclub") { (req) -> EventLoopFuture<View> in
            req.view.render("Fun/girlclub", ["":""])
        }
        routes.get("proclubs") { (req) -> Response in
            req.redirect(to: "https://twitch.tv/thediabyarmy", type: .normal)
        }
        routes.get("onlydragofans") { (req) -> Response in
            req.redirect(to: "https://twitter.com/nicoleg1904", type: .normal)
        }
    }

    private func getHomeStats(req: Request) throws -> EventLoopFuture<View> {
        let userStats = UserStatisticsController(mdc: mdc)
        let mdStats = MatchdayStatisticsController(mdc: mdc)

        return req.view.render(
            "Statistics/stats",
            ["exactB04": try userStats.getExactTipps(for: "B04", top: 4),
             "exactAll": try userStats.getExactTipps(),
             "tendencies": try userStats.getCorrectTendencies(by: .total),
             "opt": try userStats.getAggregatedTipps(for: "B04", optimist: true),
             "pess": try userStats.getAggregatedTipps(for: "B04", optimist: false),
             "col": try userStats.getAggregatedTipps(for: "KOE", optimist: true),
             "B04points": try userStats.getPoints(for: "B04"),
             "home": userStats.getTendencies(by: .heimsieg),
             "draw": userStats.getTendencies(by: .unentschieden),
             "away": userStats.getTendencies(by: .gastsieg),
             "twoOne": userStats.getSpecificResult(teamX: 2, teamY: 1),
             "oneDiff": userStats.getResultDifference(difference: 1),
             "mostGoals": userStats.getTotalGoals(most: true),
             "fewestGoals": userStats.getTotalGoals(most: false),
             "mostAvgPoints": userStats.getAveragePointsPerTipp(most: true),
             "fewestAvgPoints": userStats.getAveragePointsPerTipp(most: false),
             "easiestMatchdays": mdStats.getAveragePointsPerMatchday(most: true),
             "hardestMatchdays": mdStats.getAveragePointsPerMatchday(most: false),
             "missed": userStats.getMissedTipps()
            ]
        )
    }
}
