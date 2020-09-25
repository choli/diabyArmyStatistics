import Vapor

struct HomepageController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        routes.get(use: getHomeStats)
    }

    private func getHomeStats(req: Request) throws -> EventLoopFuture<View> {
        let stats = StatisticsController()
        guard let levOptimists = try? stats.getAggregatedTipps(for: "Lev", optimist: true, req: req),
              let levPessimists = try? stats.getAggregatedTipps(for: "Lev", optimist: false, req: req),
              let cologne = try? stats.getAggregatedTipps(for: "Köln", optimist: true, req: req),
              let homeTipps = try? stats.getTendencies(by: .heimsieg, req: req),
              let drawTipps = try? stats.getTendencies(by: .unentschieden, req: req),
              let awayTipps = try? stats.getTendencies(by: .gastsieg, req: req),
              let twoToOne = try? stats.getSpecificResult(teamX: 2, teamY: 1, req: req),
              let oneDiff = try? stats.getResultDifference(difference: 1, req: req)
        else { fatalError("This should not happen") }

        let allEvents: [EventLoopFuture<StatisticObject>] = [levOptimists,
                                                             levPessimists,
                                                             cologne,
                                                             homeTipps,
                                                             drawTipps,
                                                             awayTipps,
                                                             twoToOne,
                                                             oneDiff
                                                            ]

         return EventLoopFuture.whenAllSucceed(allEvents, on: req.eventLoop)
            .flatMap { tipps -> EventLoopFuture<View> in
                return req.view.render("stats", ["opt": tipps[0],
                                                "pess": tipps[1],
                                                "col": tipps[2],
                                                "home": tipps[3],
                                                "draw": tipps[4],
                                                "away": tipps[5],
                                                "twoOne": tipps[6],
                                                "oneDiff": tipps[7]])
            }
            .flatMapErrorThrowing { error -> View in throw error }
    }

}
