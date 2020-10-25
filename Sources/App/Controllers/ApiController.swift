import Vapor

struct ApiController: RouteCollection {
    
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

        guard let client = req.parameters.get("client"),
              let matchdayString = req.parameters.get("matchday"),
              let matchday = Int(matchdayString)
        else { assertionFailure("This matchday doesn't exist")
            throw RequestErrorObject(error: .unknownMatchday)
        }

        return MatchdayController().getMatchday(matchday, client: client, req: req)
    }

    private func getAllMatchdays(req: Request) -> [Spieltag] {
        var matchdays: [Spieltag] = []
        MatchdayController().getAllMatchdays(req: req) { matchday in
            matchdays.append(matchday)
        }
        return matchdays
    }

    private func getExactTipps(req: Request) -> StatisticObject {
        guard let team = req.parameters.get("team") else { fatalError("no team defined") }
        return UserStatisticsController().getExactTipps(for: team, req: req)
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

        return UserStatisticsController().getAggregatedTipps(for: team, optimist: opt, req: req)
    }
}

struct RequestVariables {
    let client: String
    let team: String?
}

private extension PathComponent {
    func isConstantComponent(_ component: String) -> Bool {
        guard case let .constant(constant) = self else { return false }
        return constant == component
    }
}
