import Vapor

struct MatchdayController {
    
    func getAllMatchdays(req: Request) -> [Spieltag] {
        guard let client = req.parameters.get("client")
        else { assertionFailure("Couldn't find client in request."); return [] }
        return self.getAllMatchdays(client: client, req: req)
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

    func getAllMatchdays(client: String, req: Request) -> [Spieltag] {
        var matchdays: [Spieltag] = []

        for index in 0..<34 {
            matchdays.append(self.getMatchday(index + 1, client: client, req: req, force: false))
        }
        
        return matchdays.filter  { !$0.resultate.isEmpty }
    }
}
