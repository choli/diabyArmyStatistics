import Vapor

struct HomepageController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        routes.get(use: getHomeStats)
    }

    private func getHomeStats(req: Request) throws -> EventLoopFuture<View> {
        let userStats = UserStatisticsController()
        let roundStats = RoundStatisticsController()
        guard let levExact = try? userStats.getExactTipps(for: "Lev", req: req),
              let correctTendencies = try? userStats.getCorrectTendencies(by: .total, req: req),
              let levOptimists = try? userStats.getAggregatedTipps(for: "Lev", optimist: true, req: req),
              let levPessimists = try? userStats.getAggregatedTipps(for: "Lev", optimist: false, req: req),
              let cologne = try? userStats.getAggregatedTipps(for: "Köln", optimist: true, req: req),
              let homeTipps = try? userStats.getTendencies(by: .heimsieg, req: req),
              let drawTipps = try? userStats.getTendencies(by: .unentschieden, req: req),
              let awayTipps = try? userStats.getTendencies(by: .gastsieg, req: req),
              let twoToOne = try? userStats.getSpecificResult(teamX: 2, teamY: 1, req: req),
              let oneDiff = try? userStats.getResultDifference(difference: 1, req: req),
              let missed = try? userStats.getMissedTipps(req: req),

              let empty = try? roundStats.getNumberOfNonTippers(req: req)

        else { fatalError("This should not happen") }

        let allEvents: [EventLoopFuture<StatisticObject>] = [levExact,
                                                             correctTendencies,
                                                             levOptimists,
                                                             levPessimists,
                                                             cologne,
                                                             homeTipps,
                                                             drawTipps,
                                                             awayTipps,
                                                             twoToOne,
                                                             oneDiff,
                                                             missed,

                                                             empty
                                                            ]

         return EventLoopFuture.whenAllSucceed(allEvents, on: req.eventLoop)
            .flatMap { tipps -> EventLoopFuture<View> in
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
                                                 "missed": tipps[10],


                                                 "empty":tipps[11]])
            }
            .flatMapErrorThrowing { error -> View in throw error }
    }

}
