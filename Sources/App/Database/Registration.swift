import FluentKit
import Foundation
import Vapor

final class Registration: Model, Content {
    static let schema = "registrations"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "twitterid")
    var twitterid: String

    @Field(key: "twittername")
    var twittername: String

    @Field(key: "kicktippname")
    var kicktippname: String

    @Field(key: "stateString")
    private var stateString: String

    @Parent(key: "cup_id")
    var cup: Cup

    init() { }

    init(id: UUID? = nil, twitterid: String, twittername: String, kicktippname: String, cupID: UUID, state: State = .unknown) {
        self.id = id
        self.twitterid = twitterid
        self.twittername = twittername
        self.kicktippname = kicktippname
        self.state = state
        self.$cup.id = cupID
    }

    var state: State {
        get { State(rawValue: stateString) ?? .unknown }
        set { stateString = newValue.rawValue }
    }

    enum State: String {
        case registered
        case kicktippNameMissing
        case matchingRequested
        case declined
        case unknown
    }

}

struct CreateRegistration: Migration {
    // Prepares the database for storing Galaxy models.
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema("registrations")
            .id()
            .field("twitterid", .string)
            .field("twittername", .string)
            .field("kicktippname", .string)
            .field("state", .string)
            .field("cup_id", .uuid, .references("cups", "id"))
            .create()
    }

    // Optionally reverts the changes made in the prepare method.
    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema("registrations").delete()
    }
}
