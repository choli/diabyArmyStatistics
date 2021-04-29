import Vapor

struct SingleTeamStatisticController: RouteCollection {
    let mdc: MatchdayController
    init(mdc: MatchdayController) {
        self.mdc = mdc
    }

    func boot(routes: RoutesBuilder) throws {

        routes.get("team", ":team") { (req) -> EventLoopFuture<View> in
            guard let team = req.parameters.get("team")
            else { throw Abort(.badRequest, reason: "Team not provided.") }

            let userStats = UserStatisticsController(mdc: self.mdc)
            let resultsStats = ResultsStatisticsController(mdc: self.mdc)

            let results = resultsStats.getAggregatedResults(for: team)

            return req.view.render(
                "teamStats",
                ["team": StatisticObject.singleString(team),
                 "exact": userStats.getExactTipps(for: team),
                 "optimists": userStats.getAggregatedTipps(for: team, optimist: true),
                 "pessimists": userStats.getAggregatedTipps(for: team, optimist: false),
                 "result": StatisticObject.singleAggregatedUserTipp(results),
                 "points": userStats.getPoints(for: team)]
            )
        }

        routes.get("difference", ":diff") { (req) -> EventLoopFuture<View> in
            guard let diffString = req.parameters.get("diff")
            else { throw Abort(.badRequest, reason: "A number is needed.") }

            guard let diff = Int(diffString), diff >= 0
            else { throw Abort(.badRequest, reason: "Argument is not a positive number.") }

            let userStats = UserStatisticsController(mdc: self.mdc)
            let resultsStats = ResultsStatisticsController(mdc: self.mdc)

            var results: [StatisticObject] = []
            for i in 0..<5 {
                let userTipps = userStats.getRawSpecificResult(teamX: i, teamY: i+diff)
                let actualResults = resultsStats.getSpecificResult(teamX: i, teamY: i+diff)
                let wrapper = TendenzCounterWithResult(result: actualResults, tipps: userTipps)
                results.append(StatisticObject.tendenzCounterWithResult(wrapper))
            }

            let diffTipps = userStats.getRawResultDifference(difference: diff)
            let diffResults = resultsStats.getResultDifference(difference: diff)
            let diffWrapper = TendenzCounterWithResult(result: diffResults, tipps: diffTipps)
            let diffObj = StatisticObject.tendenzCounterWithResult(diffWrapper)

            return req.view.render(
                "differenceStat",
                ["diff": StatisticObject.singleInt(diff),
                 "results": diffObj,
                 "resultsTab": StatisticObject.statsObjectArray(results)]
            )
        }
    }
}
