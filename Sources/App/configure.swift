import Vapor
import Leaf

// configures your application
public func configure(_ app: Application) throws {

    app.views.use(.leaf)

    app.leaf.tags[IsEmptyTag.name] = IsEmptyTag()
    // uncomment to serve files from /Public folder
    // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))

    // register routes
    try routes(app)
}
