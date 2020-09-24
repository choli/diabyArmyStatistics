import Vapor

struct StatisticsController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
//        let statsRoute = routes.grouped("statistics")
        
//        statsRoute.get("levOptimists", use: getLevOptimists)
//        statsRoute.get("levPessimists", use: getLevPessimists)
//        statsRoute.get("cologne", use: getCologne)
    }

    func getAggregatedTipps(for team: String, optimist: Bool, req: Request) throws -> EventLoopFuture<StatisticObject> {
        return self.getAllTippResults(of: team, req: req)
            .flatMapThrowing { tipps -> StatisticObject in
                let result = tipps.summedUpAndSorted(descending: optimist).getTop(5)
                return StatisticObject.aggregatedUserTipp(result)
            }
    }

    func getTendencies(by tendency: Tendenz, req: Request) throws -> EventLoopFuture<StatisticObject> {
        return self.getAllTipsOfUsers(req: req)
            .flatMapThrowing { tipps -> StatisticObject in
                let result = tipps.convertedToTendencies.sorted(by: tendency).getTop(5)
                return StatisticObject.tendenzCounter(result)
            }
    }

    private func getAllTipsOfUsers(req: Request) -> EventLoopFuture<[UserTipps]> {
        return MatchdayController().getAllMatchdays(req: req)
            .flatMapThrowing { matchdays -> [UserTipps] in
                var userTipps: [String: [UserTipp]] = [:]
                for matchday in matchdays {
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
    }

    private func getAllTipps(of team: String, req: Request) -> EventLoopFuture<[String: [Spiel]]> {
        return MatchdayController().getAllMatchdays(req: req)
            .flatMapThrowing { matchdays -> [String: [Spiel]] in
                var userTipps: [String: [Spiel]] = [:]
                for matchday in matchdays {
                    for tippspieler in matchday.tippspieler {
                        guard let teamTipp = tippspieler.tipps.first(where: { $0.heimteam == team || $0.gastteam == team })
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
            .flatMapErrorThrowing { error -> [String: [Spiel]] in
                throw error
            }
    }

    private func getAllTippResults(of team: String, req: Request) -> EventLoopFuture<[UserTipps]> {
        return self.getAllTipps(of: team, req: req)
            .flatMapThrowing { tipps -> [UserTipps] in
                return tipps.map { (name, userTipps) -> UserTipps in
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
}
