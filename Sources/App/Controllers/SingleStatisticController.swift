import Vapor

struct SingleStatisticController: RouteCollection {
    
    func boot(routes: RoutesBuilder) throws {
        let matchdayRoute = routes.grouped(":client")

        matchdayRoute.get("experten", ":team") { (req) -> EventLoopFuture<View> in
            guard let team = req.parameters.get("team")
            else { throw Abort(.badRequest, reason: "Team not provided.") }

            return req.view.render(
                "exactTippsStat",
                ["team": StatisticObject.singleString(team),
                 "exact": UserStatisticsController().getExactTipps(for: team, req: req)]
            )
        }

        matchdayRoute.get("optimisten", ":team") { (req) -> EventLoopFuture<View> in
            guard let team = req.parameters.get("team")
            else { throw Abort(.badRequest, reason: "Team not provided.") }

            return req.view.render(
                "goalDiffStat",
                ["team": StatisticObject.singleString(team),
                 "category": StatisticObject.singleString("Optimisten"),
                 "categoryAdj": StatisticObject.singleString("optimistischsten"),
                 "results": UserStatisticsController().getAggregatedTipps(for: team, optimist: true, req: req)]
            )
        }

        matchdayRoute.get("pessimisten", ":team") { (req) -> EventLoopFuture<View> in
            guard let team = req.parameters.get("team")
            else { throw Abort(.badRequest, reason: "Team not provided.") }

            return req.view.render(
                "goalDiffStat",
                ["team": StatisticObject.singleString(team),
                 "category": StatisticObject.singleString("Pessimisten"),
                 "categoryAdj": StatisticObject.singleString("pessimistischsten"),
                 "results": UserStatisticsController().getAggregatedTipps(for: team, optimist: false, req: req)]
            )
        }

        matchdayRoute.get("resultat", ":first", ":second") { (req) -> EventLoopFuture<View> in
            guard let firstString = req.parameters.get("first"), let secondString = req.parameters.get("second")
            else { throw Abort(.badRequest, reason: "Two numbers needed.") }

            guard let first = Int(firstString), let second = Int(secondString)
            else { throw Abort(.badRequest, reason: "Argument is not a number.") }

            return req.view.render(
                "resultsTippsStat",
                ["first": StatisticObject.singleString(firstString),
                 "second": StatisticObject.singleString(secondString),
                 "results": UserStatisticsController().getSpecificResult(teamX: first, teamY: second, req: req)]
            )
        }

        matchdayRoute.get("differenz", ":diff") { (req) -> EventLoopFuture<View> in
            guard let diffString = req.parameters.get("diff")
            else { throw Abort(.badRequest, reason: "A number is needed.") }

            guard let diff = Int(diffString)
            else { throw Abort(.badRequest, reason: "Argument is not a number.") }

            return req.view.render(
                "differenceStat",
                ["diff": StatisticObject.singleString(diffString),
                 "results": UserStatisticsController().getResultDifference(difference: diff, req: req)]
            )
        }
    }
}
