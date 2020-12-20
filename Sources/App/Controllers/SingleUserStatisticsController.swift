import Vapor

struct SingleUserStatisticsController: RouteCollection {
    let mdc: MatchdayController
    init(mdc: MatchdayController) {
        self.mdc = mdc
    }

    func boot(routes: RoutesBuilder) throws {

        routes.get("user", ":user") { (req) -> EventLoopFuture<View> in
            guard let user = req.parameters.get("user")
            else { throw Abort(.badRequest, reason: "User not provided.") }

            let userTipps = self.mdc.matchdays.compactMap { $0.tippspieler.first { $0.name == user } }.reduce([Spiel]()) { $0 + $1.tipps }

            return req.view.render(
                "userStats",
                ["username": StatisticObject.singleString(user),
                 "pointsPerTipp": self.getCorrectTipps(from: userTipps),
                 "mostTippedResults": self.getMostTippedResults(from: userTipps)]
            )
        }
    }

    private func getMostTippedResults(from tipps: [Spiel]) -> StatisticObject {
        var tippDict: [String: Int] = [:]
        for tipp in tipps {
            let key = "\(tipp.heim)-\(tipp.gast)"
            if let previous = tippDict[key] {
                tippDict[key] = previous + 1
            } else {
                tippDict[key] = 1
            }
        }

        let entries = tippDict.sorted(by: { $0.value > $1.value }).map {
            TendenzCounter(name: $0.key, heimsiege: $0.value, gastsiege: 0, unentschieden: 0)
        }

        return StatisticObject.tendenzCounter(entries.getTop(5))
    }

    private func getCorrectTipps(from tipps: [Spiel]) -> StatisticObject {
        let first = self.getTendenzCounter(for: tipps.filter { $0.spielpunkte == 4 }, title: "4 Punkte")
        let second = self.getTendenzCounter(for: tipps.filter { $0.spielpunkte == 3 }, title: "3 Punkte")
        let third = self.getTendenzCounter(for: tipps.filter { $0.spielpunkte == 2 }, title: "2 Punkte")
        let fourth = self.getTendenzCounter(for: tipps.filter { $0.spielpunkte == 0 }, title: "0 Punkte")

        return StatisticObject.tendenzCounter([first, second, third, fourth])
    }

    private func getTendenzCounter(for tipps: [Spiel], title: String) -> TendenzCounter {
        return TendenzCounter(name: title,
                       heimsiege: tipps.filter { $0.heim > $0.gast }.count,
                       gastsiege: tipps.filter { $0.heim < $0.gast }.count,
                       unentschieden: tipps.filter { $0.heim == $0.gast }.count)
    }

    private func getTippedTendencies(from tipps: [Spiel]) -> StatisticObject {
        return StatisticObject.tendenzCounter([])
    }
    
}