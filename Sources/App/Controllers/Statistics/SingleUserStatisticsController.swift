import Vapor

struct SingleUserStatisticsController: RouteCollection {
    let mdc: MatchdayController
    init(mdc: MatchdayController) {
        self.mdc = mdc
    }

    func boot(routes: RoutesBuilder) throws {
        routes.get("user") { (req) -> EventLoopFuture<View> in
            guard let users = self.mdc.matchdays.last?.tippspieler
                    .sorted(by: { $0.name.caseInsensitiveCompare($1.name) == ComparisonResult.orderedAscending })
                    .map({ StatisticObject.singleString($0.name) }), users.count > 0
            else { throw Abort(.badRequest, reason: "No users found.") }

            return req.view.render(
                "userOverview",
                ["users": StatisticObject.statsObjectArray(users)]
            )
        }

        routes.get("user", ":user") { (req) -> EventLoopFuture<View> in
            guard let user = req.parameters.get("user")
            else { throw Abort(.badRequest, reason: "User not provided.") }

            let userTipps = self.mdc.matchdays.compactMap { $0.tippspieler.first { $0.name == user } }.reduce([Spiel]()) { $0 + $1.tipps }

            return req.view.render(
                "userStats",
                ["username": StatisticObject.singleString(user),
                 "pointsPerTipp": self.getCorrectTipps(from: userTipps),
                 "avgPointsPerTipp": self.getAvgPointsPerTipp(from: userTipps),
                 "mostTippedResults": self.getMostTippedResults(from: userTipps),
                 "mostPointsPerTeam": self.getMostPointsPerTeam(from: userTipps, most: true),
                 "fewestPointsPerTeam": self.getMostPointsPerTeam(from: userTipps, most: false)
                ]
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

    private func getMostPointsPerTeam(from tipps: [Spiel], most: Bool) -> StatisticObject {
        var tippDict: [String: Int] = [:]
        for tipp in tipps {
            //home
            let home = tipp.heimteam
            if let previous = tippDict[home] {
                tippDict[home] = previous + tipp.spielpunkte
            } else {
                tippDict[home] = tipp.spielpunkte
            }

            //away
            let away = tipp.gastteam
            if let previous = tippDict[away] {
                tippDict[away] = previous + tipp.spielpunkte
            } else {
                tippDict[away] = tipp.spielpunkte
            }
        }

        let entries = tippDict.sorted(by: { most ? $0.value > $1.value : $0.value < $1.value }).map {
            TendenzCounter(name: $0.key, heimsiege: $0.value, gastsiege: 0, unentschieden: 0)
        }

        return StatisticObject.tendenzCounter(entries.getTop(5))
    }

    private func getCorrectTipps(from tipps: [Spiel]) -> StatisticObject {
        let full = Constants.MatchPoints.exactResult.rawValue
        let medium = Constants.MatchPoints.correctDiff.rawValue
        let low = Constants.MatchPoints.correctWinner.rawValue
        let first = self.getTendenzCounter(for: tipps.filter { $0.spielpunkte == full }, title: "\(full) Punkte")
        let second = self.getTendenzCounter(for: tipps.filter { $0.spielpunkte == medium }, title: "\(medium) Punkte")
        let third = self.getTendenzCounter(for: tipps.filter { $0.spielpunkte == low }, title: "\(low) Punkte")
        let fourth = self.getTendenzCounter(for: tipps.filter { $0.spielpunkte == 0 }, title: "0 Punkte")

        return StatisticObject.tendenzCounter([first, second, third, fourth])
    }

    private func getAvgPointsPerTipp(from tipps: [Spiel]) -> StatisticObject {
        let points = tipps.reduce(0) { $0 + $1.spielpunkte }
        let gamesHome = tipps.filter({ $0.heim > $0.gast })
        let pointsHome = gamesHome.reduce(0) { $0 + $1.spielpunkte }
        let gamesAway = tipps.filter({ $0.heim < $0.gast })
        let pointsAway = gamesAway.reduce(0) { $0 + $1.spielpunkte }
        let gamesDraw = tipps.filter({ $0.heim == $0.gast })
        let pointsDraw = gamesDraw.reduce(0) { $0 + $1.spielpunkte }

        let avg = StatisticObject.singleString("\(round(Double(points) / Double(max(tipps.count, 1)) * 100.0) / 100.0)")
        let avgHome = StatisticObject.singleString("\(round(Double(pointsHome) / Double(max(gamesHome.count, 1)) * 100.0) / 100.0)")
        let avgDraw = StatisticObject.singleString("\(round(Double(pointsDraw) / Double(max(gamesDraw.count, 1)) * 100.0) / 100.0)")
        let avgAway = StatisticObject.singleString("\(round(Double(pointsAway) / Double(max(gamesAway.count, 1)) * 100.0) / 100.0)")
        return StatisticObject.statsObjectArray([avg, avgHome, avgDraw, avgAway])
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
