import Vapor

struct MatchdayController {

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

    func getAllMatchdays(req: Request, matchdayCompletion: (Spieltag) -> Void) {
        guard let client = req.parameters.get("client")
        else { assertionFailure("Couldn't find client in request."); return }

        var nextMatchday = 1
        while true {
            let matchday = self.getMatchday(nextMatchday, client: client, req: req, force: false)
            guard !matchday.resultate.isEmpty else { break }
            req.logger.notice("Matchday: \(nextMatchday), games: \(matchday.resultate.count)")
            matchdayCompletion(matchday)
            nextMatchday += 1
        }
    }
}
