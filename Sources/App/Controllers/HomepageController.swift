import Vapor

struct HomepageController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        routes.get(use: getHomeStats)
    }

    private func getHomeStats(req: Request) throws -> EventLoopFuture<View> {
        let userStats = UserStatisticsController()
        let roundStats = RoundStatisticsController()
        guard let levExact = try? userStats.getExactTipps(for: "Lev", req: req),
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
                                                 "opt": tipps[1],
                                                 "pess": tipps[2],
                                                 "col": tipps[3],
                                                 "home": tipps[4],
                                                 "draw": tipps[5],
                                                 "away": tipps[6],
                                                 "twoOne": tipps[7],
                                                 "oneDiff": tipps[8],
                                                 "missed": tipps[9],

                                                 "empty":tipps[10]])
            }
            .flatMapErrorThrowing { error -> View in throw error }
    }

}
