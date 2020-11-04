import Vapor

struct HomepageController: RouteCollection {
    let mdc: MatchdayController
    init(mdc: MatchdayController) {
        self.mdc = mdc
    }

    func boot(routes: RoutesBuilder) throws {
        routes.get(use: getHomeStats)
    }

    private func getHomeStats(req: Request) throws -> EventLoopFuture<View> {
        let userStats = UserStatisticsController(mdc: self.mdc)

        return req.view.render(
            "stats",
            ["exactLev": userStats.getExactTipps(for: "Lev", req: req),
             "exactAll": userStats.getExactTipps(req: req),
             "tendencies": userStats.getCorrectTendencies(by: .total, req: req),
             "opt": userStats.getAggregatedTipps(for: "Lev", optimist: true, req: req),
             "pess": userStats.getAggregatedTipps(for: "Lev", optimist: false, req: req),
             "col": userStats.getAggregatedTipps(for: "Köln", optimist: true, req: req),
             "home": userStats.getTendencies(by: .heimsieg, req: req),
             "draw": userStats.getTendencies(by: .unentschieden, req: req),
             "away": userStats.getTendencies(by: .gastsieg, req: req),
             "twoOne": userStats.getSpecificResult(teamX: 2, teamY: 1, req: req),
             "oneDiff": userStats.getResultDifference(difference: 1, req: req),
             "mostGoals": userStats.getTotalGoals(most: true, req: req),
             "fewestGoals": userStats.getTotalGoals(most: false, req: req),
             "missed": userStats.getMissedTipps(req: req)
            ]
        )
    }
}
