import Vapor

struct HomepageController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        routes.get(use: getHomeStats)
    }

    private func getHomeStats(req: Request) throws -> EventLoopFuture<View> {
        guard let levOptimists = try? StatisticsController().getLevOptimists(req: req),
              let levPessimists = try? StatisticsController().getLevPessimists(req: req),
              let cologne = try? StatisticsController().getCologne(req: req)
        else { fatalError("This should not happen") }


        return EventLoopFuture.whenAllSucceed([levOptimists, levPessimists, cologne], on: req.eventLoop)
            .flatMap { tipps -> EventLoopFuture<View> in
                return req.view.render("base", ["opt": tipps[0],
                                                "pess": tipps[1],
                                                "col": tipps[2]])
            }
            .flatMapErrorThrowing { (error) -> View in throw error }



    }

}
