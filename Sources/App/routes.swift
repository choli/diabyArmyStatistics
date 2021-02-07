import Vapor
import Leaf

func routes(_ app: Application) throws {
    let mdc = MatchdayController()
    try app.register(collection: HomepageController(mdc: mdc))
    try app.register(collection: ApiController(mdc: mdc))
    try app.register(collection: SingleTeamStatisticController(mdc: mdc))
    try app.register(collection: KnockOutController(mdc: mdc))
    try app.register(collection: SingleUserStatisticsController(mdc: mdc))
}
