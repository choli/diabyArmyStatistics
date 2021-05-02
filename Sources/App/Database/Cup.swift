import FluentKit
import Foundation
import Vapor

final class Cup: Model, Content {
    static let schema = "cups"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "name")
    var user: String

    @Field(key: "start")
    var start: Int

    init() { }

    init(id: UUID? = nil, user: String, start: Int) {
        self.id = id
        self.user = user
        self.start = start
    }
}

struct CreateCups: Migration {
    // Prepares the database for storing Galaxy models.
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema("cups")
            .id()
            .field("name", .string)
            .field("start", .int)
            .create()
    }

    // Optionally reverts the changes made in the prepare method.
    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema("cups").delete()
    }
}
