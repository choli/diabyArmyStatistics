import Vapor

enum StatisticObject: Content {
    case aggregatedUserTipp([AggregatedUserTipp])
    case singleAggregatedUserTipp(AggregatedUserTipp)
    case tendenzCounter([TendenzCounter])
    case tendenzCounterWithResult(TendenzCounterWithResult)
    case roundStatistics([RoundStatisticsObject])
    case dropDownDataObject([DropDownDataObject])
    case knockOutDuels([KnockOutDuel])
    case tagTeamDuels([TagTeamDuel])
    case singleString(String)
    case singleInt(Int)
    case singleBool(Bool)
    case statsObjectArray([StatisticObject])
    case drawUsers([DrawTipper])
    case spieltagFacts([SpieltagFacts])

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
        case .dropDownDataObject(let dropDowns):
            try dropDowns.encode(to: encoder)
        case .knockOutDuels(let knockOutDuels):
            try knockOutDuels.encode(to: encoder)
        case .tagTeamDuels(let tagTeamDuels):
            try tagTeamDuels.encode(to: encoder)
        case .singleString(let string):
            try string.encode(to: encoder)
        case .singleInt(let int):
            try int.encode(to: encoder)
        case .singleBool(let bool):
            try bool.encode(to: encoder)
        case .statsObjectArray(let statsObjectArray):
            try statsObjectArray.encode(to: encoder)
        case .drawUsers(let drawUsers):
            try drawUsers.encode(to: encoder)
        case .spieltagFacts(let spieltagFacts):
            try spieltagFacts.encode(to: encoder)
        }
    }

    init(from decoder: Decoder) throws {
        throw Abort(.badRequest, reason: "why do i need to decode?")
    }
}

struct RoundStatisticsObject: Content {
    let spieltag: Int
    let total: Int
}

struct DropDownDataObject: Content {
    let name: String
    let url: String
}
