import Vapor

struct RoundStatisticsController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
    }

    func getNumberOfNonTippers(req: Request) -> StatisticObject {
        let matchdays = MatchdayController().getAllMatchdays(req: req)
        let roundStats = matchdays.map { matchday -> RoundStatisticsObject in
            let emptyTippers = matchday.tippspieler.filter { $0.tipps.isEmpty }
            return RoundStatisticsObject(spieltag: matchday.spieltag, total: emptyTippers.count)
        }
        return StatisticObject.roundStatistics(roundStats)
    }
}
