import Vapor

struct MatchdayController {
    let matchdays: [Spieltag]

    init() {
        var matchdays: [Spieltag] = []

        for index in 1..<35 {
            guard let fileContent = FileManager.default.contents(atPath: "Resources/Matchdays/diabyarmy\(index).json"),
                  let matchday = try? JSONDecoder().decode(Spieltag.self, from: fileContent)
            else {
                self.matchdays = matchdays
                return
            }
            matchdays.append(matchday)
        }

        self.matchdays = matchdays
    }
}
