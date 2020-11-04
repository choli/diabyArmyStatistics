import Vapor
import Leaf

func routes(_ app: Application) throws {
    let mdc = MatchdayController()
    try app.register(collection: HomepageController(mdc: mdc))
    try app.register(collection: ApiController(mdc: mdc))
    try app.register(collection: SingleStatisticController(mdc: mdc))
}
