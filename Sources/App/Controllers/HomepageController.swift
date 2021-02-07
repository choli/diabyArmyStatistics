import Vapor

struct HomepageController: RouteCollection {
    let mdc: MatchdayController
    init(mdc: MatchdayController) {
        self.mdc = mdc
    }

    func boot(routes: RoutesBuilder) throws {
        routes.get(use: getHomeStats)
        routes.get("halloffame") { (req) -> EventLoopFuture<View> in
            return req.view.render("hallOfFame", ["":""])
        }
    }

    private func getHomeStats(req: Request) throws -> EventLoopFuture<View> {
        let userStats = UserStatisticsController(mdc: mdc)
        let mdStats = MatchdayStatisticsController(mdc: mdc)

        return req.view.render(
            "stats",
            ["exactLev": userStats.getExactTipps(for: "Lev"),
             "exactAll": userStats.getExactTipps(),
             "tendencies": userStats.getCorrectTendencies(by: .total),
             "opt": userStats.getAggregatedTipps(for: "Lev", optimist: true),
             "pess": userStats.getAggregatedTipps(for: "Lev", optimist: false),
             "col": userStats.getAggregatedTipps(for: "Köln", optimist: true),
             "levpoints": userStats.getPoints(for: "Lev"),
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
