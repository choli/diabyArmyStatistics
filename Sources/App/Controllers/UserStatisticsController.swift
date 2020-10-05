import Vapor

struct UserStatisticsController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let usersRoute = routes.grouped("users")

        usersRoute.get(":team", use: getExactTipps)
    }

    private func getExactTipps(req: Request) -> StatisticObject {
        guard let team = req.parameters.get("team") else { fatalError("no team defined") }
        return getExactTipps(for: team, req: req)
    }

    func getExactTipps(for team: String, req: Request) -> StatisticObject {
        let tipps = self.getAllTippResults(of: team, exactOnly: true, req: req)
        let result = tipps.convertedToTendencies.sorted(by: .total).getTop(5)
        return StatisticObject.tendenzCounter(result)
    }

    func getAggregatedTipps(for team: String, optimist: Bool, req: Request) -> StatisticObject {
        let tipps = self.getAllTippResults(of: team, exactOnly: false, req: req)
        let result = tipps.summedUpAndSorted(descending: optimist).getTop(5)
        return StatisticObject.aggregatedUserTipp(result)
    }

    func getTendencies(by tendency: Tendenz, req: Request) -> StatisticObject {
        let tipps = self.getAllTippsOfUsers(req: req)
        let result = tipps.convertedToTendencies.sorted(by: tendency).getTop(5)
        return StatisticObject.tendenzCounter(result)
    }

    func getCorrectTendencies(by tendency: Tendenz, req: Request) -> StatisticObject {
        let tendencies = self.getAllCorrectUserTendencies(req: req)
        let result = tendencies.sorted(by: tendency).getTop(5)
        return StatisticObject.tendenzCounter(result)
    }

    func getSpecificResult(teamX: Int, teamY: Int, req: Request) -> StatisticObject {
        let tipps = self.getAllTippsOfUsers(req: req)
        let result = tipps.countTipps(teamX: teamX, teamY: teamY).getTop(5)
        return StatisticObject.tendenzCounter(result)
    }

    func getResultDifference(difference: Int, req: Request) -> StatisticObject {
        let tipps = self.getAllTippsOfUsers(req: req)
        let result = tipps.countTipps(difference: difference).getTop(5)
        return StatisticObject.tendenzCounter(result)
    }

    func getTotalGoals(most: Bool, req: Request) -> StatisticObject {
        let tipps = self.getAllTippsOfUsers(req: req)
        let result = tipps.countGoals(most: most).getTop(5)
        return StatisticObject.tendenzCounter(result)
    }

    func getMissedTipps(req: Request) -> StatisticObject {
        var userTipps: [String: Int] = [:]
        MatchdayController().getAllMatchdays(req: req).forEach { matchday in
            for user in matchday.tippspieler where (user.tipps.count > 0 && user.tipps.count < matchday.resultate.count) {
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

    private func getAllCorrectUserTendencies(req: Request) -> [TendenzCounter] {
        var userTendencies: [String: [Tendenz: Int]] = [:]
        let emptyDict: [Tendenz: Int] = [.heimsieg: 0, .unentschieden: 0, .gastsieg: 0]
        MatchdayController().getAllMatchdays(req: req).forEach { matchday  in
            matchday.tippspieler.forEach { user in
                var currentUserTendencies: [Tendenz: Int]
                if let alreadyThere = userTendencies[user.name] {
                    currentUserTendencies = alreadyThere
                } else {
                    currentUserTendencies = emptyDict
                }

                let correct = user.tipps.getCorrectTippTendencies(for: matchday.resultate)
                guard let correctHome = correct[.heimsieg],
                      let correctDraw = correct[.unentschieden],
                      let correctAway = correct[.gastsieg]
                else { fatalError("New User added, not included, or parsing error for correct tendencies in matchday") }

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

    private func getAllTippsOfUsers(req: Request) -> [UserTipps] {
        var userTipps: [String: [UserTipp]] = [:]
        MatchdayController().getAllMatchdays(req: req).forEach { matchday in
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

    private func getAllTipps(of team: String, exactOnly: Bool, req: Request) -> [String: [Spiel]] {
        var userTipps: [String: [Spiel]] = [:]
        let matchdays = MatchdayController().getAllMatchdays(req: req).forEach { matchday in
            var matchResult: Spiel?
            if exactOnly {
                guard let result =  matchday.resultate.first(where: { $0.heimteam == team || $0.gastteam == team })
                else { assertionFailure("This team didn't play on this matchday"); return }
                matchResult = result
            }
            for tippspieler in matchday.tippspieler {
                guard let teamTipp = tippspieler.tipps.first(where: { $0.heimteam == team || $0.gastteam == team })
                else { continue }

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
        return userTipps
    }

    private func getAllTippResults(of team: String, exactOnly: Bool, req: Request) -> [UserTipps] {
        return self.getAllTipps(of: team, exactOnly: exactOnly, req: req).map { (name, userTipps) in
            var allTippResults: [UserTipp] = []
            for tipp in userTipps {
                if tipp.heimteam == team {
                    allTippResults.append(UserTipp(goalsFor: tipp.heim, goalsAgainst: tipp.gast))
                } else if tipp.gastteam == team {
                    allTippResults.append(UserTipp(goalsFor: tipp.gast, goalsAgainst: tipp.heim))
                } else {
                    fatalError("This should not happen")
                }
            }
            return UserTipps(name: name, tipps: allTippResults)
        }
    }
}
