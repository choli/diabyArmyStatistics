import Vapor

struct RoundStatisticsController {

    func getNumberOfNonTippers(req: Request) -> StatisticObject {
        var roundStats: [RoundStatisticsObject] = []
        MatchdayController().getAllMatchdays(req: req) { matchday in
            let emptyTippers = matchday.tippspieler.filter { $0.tipps.isEmpty }
            roundStats.append(RoundStatisticsObject(spieltag: matchday.spieltag, total: emptyTippers.count))
        }
        return StatisticObject.roundStatistics(roundStats)
    }
}
