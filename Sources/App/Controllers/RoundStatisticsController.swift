import Vapor

struct RoundStatisticsController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
    }

    func getNumberOfNonTippers(req: Request) throws -> EventLoopFuture<StatisticObject> {
        return MatchdayController().getAllMatchdays(req: req)
            .flatMapThrowing { matchdays -> StatisticObject in
                var nonTippers: [RoundStatisticsObject] = []
                for matchday in matchdays {
                    let emptyTippers = matchday.tippspieler.filter { $0.tipps.isEmpty }
                    nonTippers.append(RoundStatisticsObject(spieltag: matchday.spieltag, total: emptyTippers.count))
                }
                return StatisticObject.roundStatistics(nonTippers)
            }
    }
}
