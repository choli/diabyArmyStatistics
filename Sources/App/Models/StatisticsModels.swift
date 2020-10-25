import Vapor

enum StatisticObject: Content {
    case aggregatedUserTipp([AggregatedUserTipp])
    case tendenzCounter([TendenzCounter])
    case roundStatistics([RoundStatisticsObject])
    case singleString(String)

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
