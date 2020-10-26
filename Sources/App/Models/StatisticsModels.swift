import Vapor

enum StatisticObject: Content {
    case aggregatedUserTipp([AggregatedUserTipp])
    case tendenzCounter([TendenzCounter])
    case roundStatistics([RoundStatisticsObject])
    case singleString(String)
    case singleInt(Int)
    case statsObjectArray([StatisticObject])

    func encode(to encoder: Encoder) throws {
        switch self {
        case .aggregatedUserTipp(let aggregatedTipp):
            try? aggregatedTipp.encode(to: encoder)
        case .tendenzCounter(let tendenzCounter):
            try? tendenzCounter.encode(to: encoder)
        case .roundStatistics(let rounds):
            try? rounds.encode(to: encoder)
        case .singleString(let string):
            try? string.encode(to: encoder)
        case .singleInt(let int):
            try? int.encode(to: encoder)
        case .statsObjectArray(let statsObjectArray):
            try? statsObjectArray.encode(to: encoder)
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
