import Vapor
import Leaf

func routes(_ app: Application) throws {
    try app.register(collection: HomepageController())
    try app.register(collection: MatchdayController())
}
