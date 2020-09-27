import Vapor

enum StatisticObject: Encodable {
    case aggregatedUserTipp([AggregatedUserTipp])
    case tendenzCounter([TendenzCounter])
    case roundStatistics([RoundStatisticsObject])

    func encode(to encoder: Encoder) throws {
        switch self {
        case .aggregatedUserTipp(let aggregatedTipp):
            try? aggregatedTipp.encode(to: encoder)
        case .tendenzCounter(let tendenzCounter):
            try? tendenzCounter.encode(to: encoder)
        case .roundStatistics(let rounds):
            try? rounds.encode(to: encoder)
        }
    }
}

struct RoundStatisticsObject: Content {
    let spieltag: Int
    let total: Int
}
