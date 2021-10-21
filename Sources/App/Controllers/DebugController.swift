import Vapor
import FluentKit

struct DebugController: RouteCollection {

    func boot(routes: RoutesBuilder) throws {

//        routes.get("addsDefinedCup") { req -> EventLoopFuture<View> in
//            return Cup(name: "test2122", start: 22, state: .registrationNotYetOpen)
//                .save(on: req.db)
//                .transform(to: req.view.render("Twitter/success", ["":""]))
//        }

//        routes.get("abcd", ":cupname") { (req) -> EventLoopFuture<EventLoopFuture<View>> in
//            guard let cupname = req.parameters.get("cupname")
//            else { return req.eventLoop.makeFailedFuture("Name not provided.") }
//
//            let cupELF = Cup.query(on: req.db)
//                .filter(\.$name == "\(cupname)\(Constants.Season.currentSeason)")
//                .first()
//
//            return cupELF.map({ cup in
//                cup?.state = .registrationOpen
//                return (cup?.save(on: req.db)
//                            .transform(to: req.view.render("Twitter/success", ["":""])))!
//            })
//        }


//        routes.get("drawOrder", ":cupname") { (req) -> EventLoopFuture<EventLoopFuture<View>> in
//            guard let cupname = req.parameters.get("cupname")
//            else { return req.eventLoop.makeFailedFuture("Name not provided.") }
//
//            let cupELF = Cup.query(on: req.db)
//                .filter(\.$name == "\(cupname)\(Constants.Season.currentSeason)")
//                .with(\.$registrations)
//                .all()
//
//            return cupELF.flatMapThrowing { cups -> EventLoopFuture<View> in
//                guard let cup = cups.first else { throw Abort(.badRequest, reason: "Nope, whats that?") }
//                let allRegs = cup.registrations
//
//                    return req.view.render("Pokal/Registration/liveDrawOrder", ["users":allRegs])
//            }
//        }


//        routes.post("drawOrder", ":cupname") { (req) -> EventLoopFuture<EventLoopFuture<View>> in
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


//        routes.get("duplicates", ":cupname") { (req) -> EventLoopFuture<EventLoopFuture<View>> in
//            guard let cupname = req.parameters.get("cupname")
//            else { return req.eventLoop.makeFailedFuture("Name not provided.") }
//
//            let cupELF = Cup.query(on: req.db)
//                .filter(\.$name == "\(cupname)\(Constants.Season.currentSeason)")
//                .with(\.$registrations)
//                .first()
//
//            return cupELF.flatMapThrowing { cup -> EventLoopFuture<View> in
//                guard let cup = cup else { fatalError("nope") }
//                let allRegs = cup.registrations
//                var validRegs = [Registration]()
//                var duplicatedRegs = [Registration]()
//
//                for reg in allRegs {
//                    if validRegs.contains(where: { reg1 in reg1.kicktippname == reg.kicktippname && reg1.twittername == reg.twittername }) {
//                        duplicatedRegs.append(reg)
//                    } else {
//                        validRegs.append(reg)
//                    }
//                }
//
//                for reg in duplicatedRegs {
////                    reg.delete(on: req.db)
//                }
//
//                    return req.view.render("Twitter/success", ["":""])
//            }
//        }


    }
}
