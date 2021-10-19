import Vapor

struct UserStatisticsController {
    let mdc: MatchdayController
    init(mdc: MatchdayController) {
        self.mdc = mdc
    }
    
    func getExactTipps(for team: String? = nil) throws -> StatisticObject {
        let tipps = try self.getAllTippResults(of: team, exactOnly: true)
        let result = tipps.convertedToTendencies.sorted(by: .total).getTop(5, total: true)
        return StatisticObject.tendenzCounter(result)
    }

    func getAggregatedTipps(for team: String, optimist: Bool) throws -> StatisticObject {
        let tipps = try self.getAllTippResults(of: team, exactOnly: false)
        let result = tipps.summedUpAndSorted(descending: optimist).getTop(5)
        return StatisticObject.aggregatedUserTipp(result)
    }

    func getTendencies(by tendency: Tendenz) -> StatisticObject {
        let tipps = self.getAllTippsOfUsers()
        let result = tipps.convertedToTendencies.sorted(by: tendency).getTop(5)
        return StatisticObject.tendenzCounter(result)
    }

    func getCorrectTendencies(by tendency: Tendenz) throws -> StatisticObject {
        let tendencies = try self.getAllCorrectUserTendencies()
        let result = tendencies.sorted(by: tendency).getTop(5, total: true)
        return StatisticObject.tendenzCounter(result)
    }

    func getRawSpecificResult(teamX: Int, teamY: Int) -> [TendenzCounter] {
        self.getAllTippsOfUsers().countTipps(teamX: teamX, teamY: teamY).getTop(5, total: true).cutOffEmpty
    }

    func getSpecificResult(teamX: Int, teamY: Int) -> StatisticObject {
        StatisticObject.tendenzCounter(self.getRawSpecificResult(teamX: teamX, teamY: teamY))
    }

    func getRawResultDifference(difference: Int) -> [TendenzCounter] {
        self.getAllTippsOfUsers().countTipps(difference: difference).getTop(5, total: true).cutOffEmpty
    }

    func getResultDifference(difference: Int) -> StatisticObject {
        StatisticObject.tendenzCounter(self.getRawResultDifference(difference: difference))
    }

    func getTotalGoals(most: Bool) -> StatisticObject {
        let tipps = self.getAllTippsOfUsers()
        let result = tipps.countGoals(most: most).getTop(5)
        return StatisticObject.tendenzCounter(result)
    }

    func getAveragePointsPerTipp(most: Bool) -> StatisticObject {
        let tipps = self.getAllTippsOfUsers()
        let result = tipps.averagePointsPerTipp(most: most).getTop(5)
        return StatisticObject.tendenzCounter(result)
    }

    func getPoints(for team: String) throws -> StatisticObject {
        let tipps = try self.getAllTippResults(of: team, exactOnly: false)
        let result = tipps.summedUpTippPoints.getTop(5)
        return StatisticObject.tendenzCounter(result)
    }

    func getMissedTipps() -> StatisticObject {
        var userTipps: [String: Int] = [:]
        self.mdc.matchdays.forEach { matchday in
            for user in matchday.tippspieler where user.tipps.count < matchday.resultate.count {
                if let currentUserTipps = userTipps[user.name] {
                    userTipps[user.name] = currentUserTipps + (matchday.resultate.count - user.tipps.count)
                } else {
                    userTipps[user.name] = matchday.resultate.count - user.tipps.count
                }
            }
        }
        let tendencies = userTipps.map { TendenzCounter(name: $0.key, heimsiege: $0.value, gastsiege: 0, unentschieden: 0) }
            .sorted(by: .total).getTop(5)
        return StatisticObject.tendenzCounter(tendencies)
    }

    private func getAllCorrectUserTendencies() throws -> [TendenzCounter] {
        var userTendencies: [String: [Tendenz: Int]] = [:]
        let emptyDict: [Tendenz: Int] = [.heimsieg: 0, .unentschieden: 0, .gastsieg: 0]
        try self.mdc.matchdays.forEach { matchday in
            try matchday.tippspieler.forEach { user in
                var currentUserTendencies: [Tendenz: Int]
                if let alreadyThere = userTendencies[user.name] {
                    currentUserTendencies = alreadyThere
                } else {
                    currentUserTendencies = emptyDict
                }

                let correct = try user.tipps.getCorrectTippTendencies(for: matchday.resultate)
                guard let correctHome = correct[.heimsieg],
                      let correctDraw = correct[.unentschieden],
                      let correctAway = correct[.gastsieg]
                else { throw Abort(.badRequest, reason: "New User added, not included, or parsing error for correct tendencies in matchday") }

                currentUserTendencies[.heimsieg]! += correctHome
                currentUserTendencies[.unentschieden]! += correctDraw
                currentUserTendencies[.gastsieg]! += correctAway

                userTendencies[user.name] = currentUserTendencies
            }
        }
        return userTendencies.map { TendenzCounter(name: $0.key,
                                                   heimsiege: $0.value[.heimsieg]!,
                                                   gastsiege: $0.value[.gastsieg]!,
                                                   unentschieden: $0.value[.unentschieden]!) }
    }

    private func getAllTippsOfUsers() -> [UserTipps] {
        var userTipps: [String: [UserTipp]] = [:]
        self.mdc.matchdays.forEach { matchday in
            matchday.tippspieler.forEach { user in
                if var currentUserTipps = userTipps[user.name] {
                    currentUserTipps.append(contentsOf: user.tipps.map { $0.asUserTipp })
                    userTipps[user.name] = currentUserTipps
                } else {
                    userTipps[user.name] = user.tipps.map { $0.asUserTipp }
                }
            }
        }
        return userTipps.map { UserTipps(name: $0.key, tipps: $0.value) }
    }

    private func getAllTipps(of team: String?, exactOnly: Bool) -> [String: [Spiel]] {
        if let team = team {
            return self.getAllTipps(of: team, exactOnly: exactOnly)
        } else {
            return self.getAllTipps(exactOnly: exactOnly)
        }
    }

    private func getAllTipps(of team: String, exactOnly: Bool) -> [String: [Spiel]] {
        var userTipps: [String: [Spiel]] = [:]
        self.mdc.matchdays.forEach { matchday in
            for tippspieler in matchday.tippspieler {
                guard let teamTipp = tippspieler.tipps.first(where: { $0.heimteam == team || $0.gastteam == team }),
                      (!exactOnly || teamTipp.spielpunkte == Constants.MatchPoints.exactResult.rawValue)
                else { continue }

                if var tipps = userTipps[tippspieler.name] {
                    tipps.append(teamTipp)
                    userTipps[tippspieler.name] = tipps
                } else {
                    userTipps[tippspieler.name] = [teamTipp]
                }
            }
        }
        return userTipps
    }

    private func getAllTipps(exactOnly: Bool) -> [String: [Spiel]] {
        var userTipps: [String: [Spiel]] = [:]
        self.mdc.matchdays.forEach { matchday in
            for tippspieler in matchday.tippspieler {
                for teamTipp in tippspieler.tipps {
                    var matchResult: Spiel?
                    if exactOnly {
                        guard let result =  matchday.resultate.first(where: { $0.heimteam == teamTipp.heimteam && $0.gastteam == teamTipp.gastteam })
                        else { assertionFailure("This game didn't happen on this matchday"); return }
                        matchResult = result
                    }

                    if exactOnly {
                        guard let matchResult = matchResult,
                              matchResult.heim == teamTipp.heim,
                              matchResult.gast == teamTipp.gast
                        else { continue }
                    }

                    if var tipps = userTipps[tippspieler.name] {
                        tipps.append(teamTipp)
                        userTipps[tippspieler.name] = tipps
                    } else {
                        userTipps[tippspieler.name] = [teamTipp]
                    }
                }
            }
        }
        return userTipps
    }

    private func getAllTippResults(of team: String?, exactOnly: Bool) throws -> [UserTipps] {
        return try self.getAllTipps(of: team, exactOnly: exactOnly).map { (name, userTipps) in
            var allTippResults: [UserTipp] = []
            for tipp in userTipps {
                if tipp.heimteam == team {
                    allTippResults.append(tipp.asUserTipp)
                } else if tipp.gastteam == team {
                    allTippResults.append(UserTipp(goalsFor: tipp.gast, goalsAgainst: tipp.heim, points: tipp.spielpunkte))
                } else {
                    guard team == nil else { throw Abort(.badRequest, reason: "This should not happen") }
                    allTippResults.append(tipp.asUserTipp)
                }
            }
            return UserTipps(name: name, tipps: allTippResults)
        }
    }
}
