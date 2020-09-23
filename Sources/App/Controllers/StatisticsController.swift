import Vapor

struct StatisticsController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let statsRoute = routes.grouped("statistics")

        statsRoute.get("levOptimists", use: getLevOptimists)
        statsRoute.get("levPessimists", use: getLevPessimists)
        statsRoute.get("cologne", use: getCologne)
    }

    func getLevOptimists(req: Request) throws -> EventLoopFuture<[AggregatedTeamTipp]> {
        let cologne = "Lev"
        return self.getAllTippResults(of: cologne, req: req)
            .flatMapThrowing { tipps -> [AggregatedTeamTipp] in
                tipps.summedUpAndSorted(descending: true).getTop(5)
            }
    }

    func getLevPessimists(req: Request) throws -> EventLoopFuture<[AggregatedTeamTipp]> {
        let cologne = "Lev"
        return self.getAllTippResults(of: cologne, req: req)
            .flatMapThrowing { tipps -> [AggregatedTeamTipp] in
                tipps.summedUpAndSorted(descending: false).getTop(5)
            }
    }

    func getCologne(req: Request) throws -> EventLoopFuture<[AggregatedTeamTipp]> {
        let cologne = "Köln"
        return self.getAllTippResults(of: cologne, req: req)
            .flatMapThrowing { tipps -> [AggregatedTeamTipp] in
                tipps.summedUpAndSorted(descending: true).getTop(5)
            }
    }

    private func getAllTipps(of team: String, req: Request) -> EventLoopFuture<[String: [Spiel]]> {
        return MatchdayController.getAllMatchdays(req: req)
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

    private func getAllTippResults(of team: String, req: Request) -> EventLoopFuture<[TeamTipps]> {
        return self.getAllTipps(of: team, req: req)
            .flatMapThrowing { tipps -> [TeamTipps] in
                return tipps.map { (name, userTipps) -> TeamTipps in
                    var allTippResults: [TeamTipp] = []
                    for tipp in userTipps {
                        if tipp.heimteam == team {
                            allTippResults.append(TeamTipp(goalsFor: tipp.heim, goalsAgainst: tipp.gast))
                        } else if tipp.gastteam == team {
                            allTippResults.append(TeamTipp(goalsFor: tipp.gast, goalsAgainst: tipp.heim))
                        } else {
                            fatalError("This should not happen")
                        }
                    }
                    return TeamTipps(name: name, tipps: allTippResults)
                }
            }
    }
}
