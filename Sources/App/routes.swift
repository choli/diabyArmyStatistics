import Vapor

func routes(_ app: Application) throws {
    app.get { req in
        return "It works!"
    }

    app.get("round", ":round") { req -> EventLoopFuture<Spieltag> in
        guard let round = req.parameters.get("round")
        else { return req.eventLoop.makeFailedFuture(RequstErrors.unknownRound) }
        let future = req.fileio.collectFile(at: "Public/round\(round).json")
            .flatMapThrowing { buffer -> Spieltag in
                guard let spieltag = try? JSONDecoder().decode(Spieltag.self, from: buffer)
                else { throw RequstErrors.couldNotParseRound }
                return spieltag
            }
            .flatMapErrorThrowing { error -> Spieltag in
                throw RequstErrors.roundNotRegistered
            }

        return future
    }
}

enum RequstErrors: Error {
    case unknownRound
    case roundNotRegistered
    case couldNotParseRound
}
