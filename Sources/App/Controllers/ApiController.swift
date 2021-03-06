import Vapor

struct ApiController: RouteCollection {
    let mdc: MatchdayController
    init(mdc: MatchdayController) {
        self.mdc = mdc
    }
    
    func boot(routes: RoutesBuilder) throws {
        let matchdayRoute = routes.grouped("api", ":client")
        matchdayRoute.get("all", use: getAllMatchdays)
        matchdayRoute.get("matchday", ":matchday", use: getMatchday)

        let usersRoute = matchdayRoute.grouped("users")

        usersRoute.get("experts", ":team", use: getExactTipps)
        usersRoute.get("optimists", ":team", use: getAggregatedTipps)
        usersRoute.get("pessimists", ":team", use: getAggregatedTipps)
    }

    private func getMatchday(req: Request) throws -> Spieltag {

        guard let matchdayString = req.parameters.get("matchday"),
              let matchday = Int(matchdayString),
              matchday > 0, matchday < 35
        else { assertionFailure("This matchday doesn't exist")
            throw RequestErrorObject(error: .unknownMatchday)
        }

        return self.mdc.matchdays[matchday - 1]
    }

    private func getAllMatchdays(_: Request) -> [Spieltag] {
        return self.mdc.matchdays
    }

    private func getExactTipps(req: Request) -> StatisticObject {
        guard let team = req.parameters.get("team") else { fatalError("no team defined") }
        return UserStatisticsController(mdc: self.mdc).getExactTipps(for: team)
    }

    func getAggregatedTipps(req: Request) -> StatisticObject {
        let optimists = "optimists"
        let pessimists = "pessimists"
        guard let team = req.parameters.get("team") else { fatalError("no team defined") }
        guard let paths = req.route?.path else { fatalError("empty paths, not cool") }

        let opt: Bool
        if (paths.first(where: { $0.isConstantComponent(optimists) }) != nil) {
            opt = true
        } else if (paths.first(where: { $0.isConstantComponent(pessimists) }) != nil) {
            opt = false
        } else {
            fatalError("Wrong path in here")
        }

        return UserStatisticsController(mdc: self.mdc).getAggregatedTipps(for: team, optimist: opt)
    }
}

private extension PathComponent {
    func isConstantComponent(_ component: String) -> Bool {
        guard case let .constant(constant) = self else { return false }
        return constant == component
    }
}
