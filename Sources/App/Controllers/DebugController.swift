import Vapor
import FluentKit

struct DebugController: RouteCollection {

    func boot(routes: RoutesBuilder) throws {

//        routes.get("abcd1234") { req -> EventLoopFuture<View> in
//            return Cup(name: "supercopa2122", start: 2, state: .registrationNotYetOpen)
//                .save(on: req.db)
//                .transform(to: req.view.render("Twitter/success", ["":""]))
//        }

//        routes.get("abcd", ":cupname") { (req) -> EventLoopFuture<EventLoopFuture<View>> in
//            guard let cupname = req.parameters.get("cupname")
//            else { return req.eventLoop.makeFailedFuture("Name not provided.") }
//
//            let cupELF = Cup.query(on: req.db)
//                .filter(\.$name == "\(cupname)\(Constants.Season.currentSeason)")
//                .with(\.$registrations)
//                .all()
//
//            return cupELF.flatMapThrowing { cups -> EventLoopFuture<View> in
//                guard let cup = cups.first else { fatalError("nope") }
//                let allRegs = cup.registrations
//
//                    return req.view.render("Pokal/Registration/liveDrawOrder", ["users":allRegs])
//            }
//        }
//
//        routes.post("abcd", ":cupname") { (req) -> EventLoopFuture<EventLoopFuture<View>> in
//            guard let cupname = req.parameters.get("cupname"),
//                  let orders = try? req.content.decode([String:String].self)
//            else { return req.eventLoop.makeFailedFuture("Oh oh.") }
//
//            // check all unique
//
//            let cupELF = Cup.query(on: req.db)
//                .filter(\.$name == "\(cupname)\(Constants.Season.currentSeason)")
//                .with(\.$registrations)
//                .all()
//
//            return cupELF.flatMapThrowing { cups -> EventLoopFuture<View> in
//                let allRegs = cups.first!.registrations
//                for reg in allRegs {
//                    let newOrder = orders[reg.id!.uuidString]
//                    reg.order = Int(newOrder!)
//                    reg.save(on: req.db)
//                }
//                return req.view.render("Pokal/Registration/liveDrawOrder", ["users":allRegs])
//            }
//        }
    }
}
