import Vapor

struct SingleStatisticController: RouteCollection {
    let mdc: MatchdayController
    init(mdc: MatchdayController) {
        self.mdc = mdc
    }

    func boot(routes: RoutesBuilder) throws {

        routes.get("team", ":team") { (req) -> EventLoopFuture<View> in
            guard let team = req.parameters.get("team")
            else { throw Abort(.badRequest, reason: "Team not provided.") }

            let userStats = UserStatisticsController(mdc: self.mdc)

            return req.view.render(
                "teamStats",
                ["team": StatisticObject.singleString(team),
                 "exact": userStats.getExactTipps(for: team),
                 "optimists": userStats.getAggregatedTipps(for: team, optimist: true),
                 "pessimists": userStats.getAggregatedTipps(for: team, optimist: false),
                 "points": userStats.getPoints(for: team)]
            )
        }

        routes.get("difference", ":diff") { (req) -> EventLoopFuture<View> in
            guard let diffString = req.parameters.get("diff")
            else { throw Abort(.badRequest, reason: "A number is needed.") }

            guard let diff = Int(diffString), diff >= 0
            else { throw Abort(.badRequest, reason: "Argument is not a positive number.") }

            let userStats = UserStatisticsController(mdc: self.mdc)

            var results: [StatisticObject] = []
            for i in 0..<5 {
                results.append(userStats.getSpecificResult(teamX: i, teamY: i+diff))
            }

            return req.view.render(
                "differenceStat",
                ["diff": StatisticObject.singleInt(diff),
                 "results": userStats.getResultDifference(difference: diff),
                 "resultsTab": StatisticObject.statsObjectArray(results)]
            )
        }
    }
}
