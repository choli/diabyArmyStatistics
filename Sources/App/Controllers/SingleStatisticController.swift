import Vapor

struct SingleStatisticController: RouteCollection {
    
    func boot(routes: RoutesBuilder) throws {
        let matchdayRoute = routes.grouped(":client")

        matchdayRoute.get("team", ":team") { (req) -> EventLoopFuture<View> in
            guard let team = req.parameters.get("team")
            else { throw Abort(.badRequest, reason: "Team not provided.") }

            let userStats = UserStatisticsController()

            return req.view.render(
                "teamStats",
                ["team": StatisticObject.singleString(team),
                 "exact": userStats.getExactTipps(for: team, req: req),
                 "optimists": userStats.getAggregatedTipps(for: team, optimist: true, req: req),
                 "pessimists": userStats.getAggregatedTipps(for: team, optimist: false, req: req)]
            )
        }

        matchdayRoute.get("difference", ":diff") { (req) -> EventLoopFuture<View> in
            guard let diffString = req.parameters.get("diff")
            else { throw Abort(.badRequest, reason: "A number is needed.") }

            guard let diff = Int(diffString), diff >= 0
            else { throw Abort(.badRequest, reason: "Argument is not a positive number.") }

            var results: [StatisticObject] = []
            for i in 0..<5 {
                results.append(UserStatisticsController().getSpecificResult(teamX: i, teamY: i+diff, req: req))
            }

            return req.view.render(
                "differenceStat",
                ["diff": StatisticObject.singleInt(diff),
                 "results": UserStatisticsController().getResultDifference(difference: diff, req: req),
                 "resultsTab": StatisticObject.statsObjectArray(results)]
            )
        }
    }
}
