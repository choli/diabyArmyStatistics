import Vapor

struct HomepageController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        routes.get(use: getHomeStats)
    }

    private func getHomeStats(req: Request) throws -> EventLoopFuture<View> {
        req.parameters.set("client", to: "diabyarmy")
        let userStats = UserStatisticsController()
        let roundStats = RoundStatisticsController()

        let levExact = userStats.getExactTipps(for: "Lev", req: req)
        let correctTendencies = userStats.getCorrectTendencies(by: .total, req: req)
        let levOptimists = userStats.getAggregatedTipps(for: "Lev", optimist: true, req: req)
        let levPessimists = userStats.getAggregatedTipps(for: "Lev", optimist: false, req: req)
        let cologne = userStats.getAggregatedTipps(for: "Köln", optimist: true, req: req)
        let homeTipps = userStats.getTendencies(by: .heimsieg, req: req)
        let drawTipps = userStats.getTendencies(by: .unentschieden, req: req)
        let awayTipps = userStats.getTendencies(by: .gastsieg, req: req)
        let twoToOne = userStats.getSpecificResult(teamX: 2, teamY: 1, req: req)
        let oneDiff = userStats.getResultDifference(difference: 1, req: req)
        let mostGoals = userStats.getTotalGoals(most: true, req: req)
        let fewestGoals = userStats.getTotalGoals(most: false, req: req)
        let missed = userStats.getMissedTipps(req: req)

        let empty = roundStats.getNumberOfNonTippers(req: req)

        let tipps: [StatisticObject] = [levExact,
                                        correctTendencies,
                                        levOptimists,
                                        levPessimists,
                                        cologne,
                                        homeTipps,
                                        drawTipps,
                                        awayTipps,
                                        twoToOne,
                                        oneDiff,
                                        mostGoals,
                                        fewestGoals,
                                        missed,

                                        empty
                                        ]

        return req.view.render("stats", ["exact": tipps[0],
                                         "tendencies": tipps[1],
                                         "opt": tipps[2],
                                         "pess": tipps[3],
                                         "col": tipps[4],
                                         "home": tipps[5],
                                         "draw": tipps[6],
                                         "away": tipps[7],
                                         "twoOne": tipps[8],
                                         "oneDiff": tipps[9],
                                         "mostGoals": tipps[10],
                                         "fewestGoals": tipps[11],
                                         "missed": tipps[12],

                                         "empty":tipps[13]])

    }
}
