import Vapor
import Leaf
import Fluent
import FluentPostgresDriver

// configures your application
public func configure(_ app: Application) throws {

    app.views.use(.leaf)

    app.leaf.tags[IsEmptyTag.name] = IsEmptyTag()
    // uncomment to serve files from /Public folder
    // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))

    let dbURL: String?
    dbURL = Environment.get("DATABASE_URL")
    guard let databaseURL = dbURL , var postgresConfig = PostgresConfiguration(url: databaseURL) else { fatalError() }
    postgresConfig.tlsConfiguration = .forClient(certificateVerification: .none)
    app.databases.use(.postgres(configuration: postgresConfig), as: .psql)
    app.migrations.add(SessionRecord.migration)
    app.migrations.add(CreateCups())
    app.migrations.add(CreateRegistration())

    app.sessions.use(.fluent(.psql))
    app.middleware.use(app.sessions.middleware)

    // register routes
    try routes(app)
}
