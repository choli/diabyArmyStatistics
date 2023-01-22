import FluentKit
import Foundation
import Vapor

final class Cup: Model, Content {
    static let schema = "cups"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "name")
    var name: String

    @Field(key: "start")
    var start: Int

    @Field(key: "stateString")
    private var stateString: String

    @Children(for: \.$cup)
    var registrations: [Registration]

    init() { }

    init(id: UUID? = nil, name: String, start: Int, state: State) {
        self.id = id
        self.name = name
        self.start = start
        self.state = state
    }

    var state: State {
        get { State(rawValue: stateString) ?? .registrationNotYetOpen }
        set { stateString = newValue.rawValue }
    }

    enum State: String {
        case registrationOpen
        case registrationNotPublic
        case registrationNotYetOpen
        case registrationClosed
    }
}

struct CreateCups: Migration {
    // Prepares the database for storing Galaxy models.
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema("cups")
            .id()
            .field("name", .string)
            .field("start", .int)
            .field("stateString", .string)
            .create()
    }

    // Optionally reverts the changes made in the prepare method.
    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema("cups").delete()
    }
}

//INSERT INTO "public"."cups" (id,name,start,"stateString") VALUES (gen_random_uuid(),'apertura2223',21,'registrationNotYetOpen');
