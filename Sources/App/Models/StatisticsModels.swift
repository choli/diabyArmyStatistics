import Vapor

enum StatisticObject: Content {
    case aggregatedUserTipp([AggregatedUserTipp])
    case singleAggregatedUserTipp(AggregatedUserTipp)
    case tendenzCounter([TendenzCounter])
    case tendenzCounterWithResult(TendenzCounterWithResult)
    case roundStatistics([RoundStatisticsObject])
    case knockOutDuels([KnockOutDuel])
    case singleString(String)
    case singleInt(Int)
    case statsObjectArray([StatisticObject])

    func encode(to encoder: Encoder) throws {
        switch self {
        case .aggregatedUserTipp(let aggregatedTipp):
            try aggregatedTipp.encode(to: encoder)
        case .singleAggregatedUserTipp(let singleAggregatedUserTipp):
            try singleAggregatedUserTipp.encode(to: encoder)
        case .tendenzCounter(let tendenzCounter):
            try tendenzCounter.encode(to: encoder)
        case .tendenzCounterWithResult(let tendenzCounterWithResult):
            try tendenzCounterWithResult.encode(to: encoder)
        case .roundStatistics(let rounds):
            try rounds.encode(to: encoder)
        case .knockOutDuels(let knockOutDuels):
            try knockOutDuels.encode(to: encoder)
        case .singleString(let string):
            try string.encode(to: encoder)
        case .singleInt(let int):
            try int.encode(to: encoder)
        case .statsObjectArray(let statsObjectArray):
            try statsObjectArray.encode(to: encoder)
        }
    }

    init(from decoder: Decoder) throws {
        fatalError("why do i need to decode?")
    }
}

struct RoundStatisticsObject: Content {
    let spieltag: Int
    let total: Int
}
