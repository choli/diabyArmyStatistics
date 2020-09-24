import Vapor

struct MatchdayController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let matchdayRoute = routes.grouped("matchday")

        matchdayRoute.get(":matchday", use: getMatchday)
        matchdayRoute.get("all", use: getAllMatchdays)
    }

    private func getMatchday(req: Request) throws -> EventLoopFuture<Spieltag> {
        guard let matchdayString = req.parameters.get("matchday"),
              let matchday = Int(matchdayString)
        else { return req.eventLoop.makeFailedFuture(RequstError.unknownMatchday) }

        return self.getMatchday(matchday, req: req)
    }

    func getMatchday(_ matchday: Int, req: Request, force: Bool = true) -> EventLoopFuture<Spieltag> {
        return req.fileio.collectFile(at: "Resources/Matchdays/matchday\(matchday).json")
            .flatMapThrowing { buffer -> Spieltag in
                guard let spieltag = try? JSONDecoder().decode(Spieltag.self, from: buffer)
                else { throw RequstError.couldNotParseMatchday }
                return spieltag
            }
            .flatMapErrorThrowing { error -> Spieltag in
                guard force else { return Spieltag(resultate: [], tippspieler: [], spieltag: matchday) }
                throw RequstError.matchdayNotRegistered
            }
    }

    func getAllMatchdays(req: Request) -> EventLoopFuture<[Spieltag]> {
        var matchdayFutures: [EventLoopFuture<Spieltag>] = []

        for index in 0..<34 {
            matchdayFutures.append(self.getMatchday(index + 1, req: req, force: false))
        }

        return EventLoopFuture.whenAllSucceed(matchdayFutures, on: req.eventLoop)
            .flatMapThrowing { matchdays -> [Spieltag] in
                return matchdays.filter { !$0.resultate.isEmpty }
            }
            .flatMapErrorThrowing { error -> [Spieltag] in
                throw error
            }
    }
}
