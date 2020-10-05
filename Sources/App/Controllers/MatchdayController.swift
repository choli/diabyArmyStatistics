import Vapor

struct MatchdayController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let matchdayRoute = routes.grouped(":client", "matchday")

        try matchdayRoute.register(collection: UserStatisticsController())
        matchdayRoute.get(":matchday", use: getMatchday)
        matchdayRoute.get("all", use: getAllMatchdays)
    }

    private func getMatchday(req: Request) throws -> Spieltag {

        guard let client = req.parameters.get("client"),
              let matchdayString = req.parameters.get("matchday"),
              let matchday = Int(matchdayString)
        else { assertionFailure("This matchday doesn't exist")
            throw RequestErrorObject(error: .unknownMatchday)
        }

        return self.getMatchday(matchday, client: client, req: req)
    }

    func getMatchday(_ matchday: Int, client: String, req: Request, force: Bool = true) -> Spieltag {

        guard let fileContent = FileManager.default.contents(atPath: "Resources/Matchdays/\(client)\(matchday).json"),
              let spieltag = try? JSONDecoder().decode(Spieltag.self, from: fileContent)
        else {
            if force {
                assertionFailure("This matchday was not played yet.")
                return Spieltag(resultate: [], tippspieler: [], spieltag: matchday)
            } else {
                return Spieltag(resultate: [], tippspieler: [], spieltag: matchday)
            }
        }
        return spieltag
    }

    func getAllMatchdays(req: Request) -> [Spieltag] {
        guard let client = req.parameters.get("client")
        else { assertionFailure("Couldn't find client in request."); return [] }
        return self.getAllMatchdays(client: client, req: req)
    }

    func getAllMatchdays(client: String, req: Request) -> [Spieltag] {
        var matchdays: [Spieltag] = []

        for index in 0..<34 {
            matchdays.append(self.getMatchday(index + 1, client: client, req: req, force: false))
        }
        
        return matchdays.filter  { !$0.resultate.isEmpty }
    }
}
