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

    guard let databaseURL = Environment.get("DATABASE_URL"), var postgresConfig = PostgresConfiguration(url: databaseURL)
    else { fatalError("DB setup not working") }

    postgresConfig.tlsConfiguration = .makeClientConfiguration()
    postgresConfig.tlsConfiguration?.certificateVerification = .none
    app.databases.use(.postgres(configuration: postgresConfig), as: .psql)
    app.migrations.add(CreateCups())
    app.migrations.add(CreateRegistration())

    app.middleware.use(app.sessions.middleware)

    // register routes
    try routes(app)
}
