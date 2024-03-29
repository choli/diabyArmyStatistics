import Vapor
import FluentKit

struct KnockOutController: RouteCollection {
    let mdc: MatchdayController
    init(mdc: MatchdayController) {
        self.mdc = mdc
    }

    func boot(routes: RoutesBuilder) throws {

        /* old ones
        routes.get("apertura", ":round") { (req) -> EventLoopFuture<View> in
            guard let roundString = req.parameters.get("round"), let round = Int(roundString), round > 0
            else { throw Abort(.badRequest, reason: "Round not provided.") }

            guard let fileContent = FileManager.default.contents(atPath: "Resources/Draws/apertura2021.json"),
                  let allRegistrations = try? JSONDecoder().decode(DrawTipperArray.self, from: fileContent)
            else { fatalError("Couldn't read file with draws") }

            let duels = self.getDuels(round, start: 8, tieBreaker: .gesamtpunkte, participants: allRegistrations.drawnUser)
            let dropDowns = self.getDropDownMenu(for: "apertura", duels: duels.count, in: round)

            return req.view.render(
                "Pokal/knockOut",
                [
                    "duels": StatisticObject.knockOutDuels(duels),
                    "title": StatisticObject.singleString(self.title(for: round, duels: duels.count)),
                    "dropDown": StatisticObject.dropDownDataObject(dropDowns)
                ]
            )
        }

        routes.get("clausura", ":round") { (req) -> EventLoopFuture<View> in
            guard let roundString = req.parameters.get("round"), let round = Int(roundString), round > 0
            else { throw Abort(.badRequest, reason: "Round not provided.") }

            guard let fileContent = FileManager.default.contents(atPath: "Resources/Draws/clausura2021.json"),
                  let allRegistrations = try? JSONDecoder().decode(DrawTipperArray.self, from: fileContent)
            else { fatalError("Couldn't read file with draws") }

            let duels = self.getDuels(round, start: 23, tieBreaker: .mehrExakteTipps, participants: allRegistrations.drawnUser)
            let dropDowns = self.getDropDownMenu(for: "clausura", duels: duels.count, in: round)

            return req.view.render(
                "Pokal/knockOut",
                [
                    "duels": StatisticObject.knockOutDuels(duels),
                    "title": StatisticObject.singleString(self.title(for: round, duels: duels.count)),
                    "dropDown": StatisticObject.dropDownDataObject(dropDowns)
                ]
            )
        }

        routes.get("clausura") { (req) -> EventLoopFuture<View> in
            guard let fileContent = FileManager.default.contents(atPath: "Resources/Draws/clausura2021.json"),
              let spieler = try? JSONDecoder().decode(DrawTipperArray.self, from: fileContent)
            else { throw Abort(.badRequest, reason: "No idea what happened") }

            let users = spieler.nonDrawnUser?.sorted { $0.name.caseInsensitiveCompare($1.name) == ComparisonResult.orderedAscending }

            let duels = getDuelsForDraw(spieler, firstMatchday: 23)
            return req.view.render(
                "Pokal/liveDraw",
                [
                    "notDrawn": StatisticObject.drawUsers(users ?? []),
                    "duels1": StatisticObject.knockOutDuels(duels.firstRound),
                    "duels2": StatisticObject.knockOutDuels(duels.secondRound),
                    "title1": StatisticObject.singleString(title(for: 1, duels: 2*duels.secondRound.count)),
                    "title2": StatisticObject.singleString(title(for: 2, duels: 2*duels.secondRound.count))
                ]
            )
        }
*/

        routes.get("cup", ":cupname", ":round") { (req) -> EventLoopFuture<EventLoopFuture<View>> in
            guard let cupname = req.parameters.get("cupname")
            else { throw Abort(.badRequest, reason: "Round not provided.") }

            guard let roundString = req.parameters.get("round"), let round = Int(roundString), round > 0
            else { throw Abort(.badRequest, reason: "Round not provided.") }

            let cupELF = Cup.query(on: req.db)
                .filter(\.$name == "\(cupname)\(Constants.Season.currentSeason)")
                .with(\.$registrations)
                .first()

            return cupELF.flatMapThrowing { cup -> EventLoopFuture<View> in
                guard let cup = cup
                else { throw Abort(.badRequest, reason: "Cup does not exist") }

                let participants = cup.registrations.map { DrawTipper(with: $0) }

                let users = participants
                    .filter { $0.order != nil }
                    .sorted { $0.order! < $1.order! }

                guard users.count == participants.count
                else { throw Abort(.badRequest, reason: "Auslosung ist noch nicht abgeschlossen") }

                let duels = try self.getDuels(round, start: cup.start, tieBreaker: .mehrExakteTipps, participants: users)

                let dropDowns = self.getDropDownMenu(for: "cup/"+cupname, duels: duels.count, in: round)

                return req.view.render(
                    "Pokal/knockOut",
                    [
                        "duels": StatisticObject.knockOutDuels(duels),
                        "title": StatisticObject.singleString(self.title(for: round, duels: duels.count)),
                        "dropDown": StatisticObject.dropDownDataObject(dropDowns)
                    ]
                )
            }
        }


        routes.get("cup", ":cupname") { (req) -> EventLoopFuture<EventLoopFuture<View>> in
            guard let cupname = req.parameters.get("cupname")
            else { throw Abort(.badRequest, reason: "Round not provided.") }

            let cupELF = Cup.query(on: req.db)
                .filter(\.$name == "\(cupname)\(Constants.Season.currentSeason)")
                .with(\.$registrations)
                .first()

            return cupELF.flatMapThrowing { cup -> EventLoopFuture<View> in
                guard let cup = cup
                else { return req.eventLoop.makeFailedFuture("Cup does not exist") }

                let participants = cup.registrations.map { DrawTipper(with: $0) }
                let drawnUsers = participants.filter { $0.order != nil }.sorted { $0.order! < $1.order! }
                let nonDrawnUsers = participants.filter { $0.order == nil }
                    .sorted { $0.name.caseInsensitiveCompare($1.name) == ComparisonResult.orderedAscending }

                let tipperArray = DrawTipperArray(nonDrawnUser: nonDrawnUsers, drawnUser: drawnUsers)
                let duels = try getDuelsForDraw(tipperArray, firstMatchday: cup.start)
                return req.view.render(
                    "Pokal/liveDraw",
                    [
                        "notDrawn": StatisticObject.drawUsers(nonDrawnUsers),
                        "duels1": StatisticObject.knockOutDuels(duels.firstRound),
                        "duels2": StatisticObject.knockOutDuels(duels.secondRound),
                        "title1": StatisticObject.singleString(title(for: 1, duels: 2*duels.secondRound.count)),
                        "title2": StatisticObject.singleString(title(for: 2, duels: 2*duels.secondRound.count))
                    ]
                )
            }
        }
    }

    private func getDropDownMenu(for url: String, duels: Int, in round: Int) -> [DropDownDataObject] {
        var items: [DropDownDataObject] = []

        let rounds = Int(log2(Double(duels))) + round

        for i in 1..<(rounds + 1) {
            let duelsInRound = Int(pow(2,Double(rounds - i)))
            items.append(DropDownDataObject(
                            name: self.title(for: i, duels: duelsInRound),
                            url: "/\(url)/\(i)")
            )
        }

        return items
    }

    private func title(for round: Int, duels: Int) -> String {
        switch duels {
        case 1: return "Finale"
        case 2: return "Halbfinale"
        case 3,4: return "Viertelfinale"
        case 5,6,7,8: return "Achtelfinale"
        default: break
        }

        switch round {
        case 1: return "Erste Runde"
        case 2: return "Zweite Runde"
        case 3: return "Dritte Runde"
        case 4: return "Vierte Runde"
        case 5: return "Fünfte Runde"
        default: break
        }

        return ""
    }

    private func getDuels(_ round: Int, start: Int, tieBreaker: KnockOutDuel.TieBreaker, participants: [DrawTipper]) throws -> [KnockOutDuel] {
        guard round > 1
        else { return try self.getFirstRoundDuels(start: start, tieBreaker: tieBreaker, participants: participants) }

        let round = try self.getDuelsInRound(round, start: start, tieBreaker: tieBreaker, participants: participants)
        return round
    }

    private func getDuelsInRound(_ round: Int, start: Int, tieBreaker: KnockOutDuel.TieBreaker, participants: [DrawTipper]) throws -> [KnockOutDuel] {
        let previousDuels = round == 2 ?
            try self.getFirstRoundDuels(start: start, tieBreaker: tieBreaker, participants: participants) :
            try self.getDuelsInRound(round - 1, start: start, tieBreaker: tieBreaker, participants: participants)
        let maxId = previousDuels.map { $0.spielnummer }.max()!

        let resultMD = self.mdc.matchdays.first(where: { $0.spieltag == start + round - 1 })
        var duels: [KnockOutDuel] = []

        for i in 0..<(previousDuels.count / 2) {
            let first = previousDuels[2 * i]
            let second = previousDuels[2 * i + 1]
            let new = self.getNewDuel(from: first, against: second, matchNumber: maxId + i + 1, results: resultMD, tieBreaker: tieBreaker)
            duels.append(new)
        }

        return duels
    }

    private func getNewDuel(from first: KnockOutDuel, against second: KnockOutDuel, matchNumber: Int, results: Spieltag?, tieBreaker: KnockOutDuel.TieBreaker) -> KnockOutDuel {
        var tipperA: Tippspieler
        if first.winner == 0 {
            tipperA = Tippspieler(name: "Sieger*in Spiel \(first.spielnummer)", tipps: [], punkte: 0, position: 0, bonus: 0, siege: 0, gesamtpunkte: 0, spieltagssieger: nil)
        } else {
            if first.winner == 1 {
                tipperA = first.tipperA
                tipperA.drawTipper = first.tipperA.drawTipper
            } else {
                tipperA = first.tipperB
                tipperA.drawTipper = first.tipperB.drawTipper
            }
        }

        var tipperB: Tippspieler
        if second.winner == 0 {
            tipperB = Tippspieler(name: "Sieger*in Spiel \(second.spielnummer)", tipps: [], punkte: 0, position: 0, bonus: 0, siege: 0, gesamtpunkte: 0, spieltagssieger: nil)
        } else {
            if second.winner == 1 {
                tipperB = second.tipperA
                tipperB.drawTipper = second.tipperA.drawTipper
            } else {
                tipperB = second.tipperB
                tipperB.drawTipper = second.tipperB.drawTipper
            }
        }

        if let results = results,
           var updateTipperA = results.tippspieler.first(where: { $0.name == tipperA.name }),
           var updateTipperB = results.tippspieler.first(where: { $0.name == tipperB.name })
        {
            updateTipperA.drawTipper = tipperA.drawTipper
            updateTipperB.drawTipper = tipperB.drawTipper
            let pointsA = results.tippspieler.first(where: { $0.name == tipperA.name })?.punkte ?? 0
            let pointsB = results.tippspieler.first(where: { $0.name == tipperB.name })?.punkte ?? 0
            return KnockOutDuel(
                spielnummer: matchNumber,
                tipperA: updateTipperA,
                tipperB: updateTipperB,
                positionA: tipperA.position,
                positionB: tipperB.position,
                punkteA: pointsA,
                punkteB: pointsB,
                tieBreaker: tieBreaker
            )
        } else {
            return KnockOutDuel(
                spielnummer: matchNumber,
                tipperA: tipperA,
                tipperB: tipperB,
                positionA: tipperA.position,
                positionB: tipperB.position,
                punkteA: nil,
                punkteB: nil,
                tieBreaker: tieBreaker
            )
        }


    }

    private func getFirstRoundDuels(start: Int, tieBreaker: KnockOutDuel.TieBreaker, participants: [DrawTipper]) throws -> [KnockOutDuel] {
        guard let firstMatchday = self.mdc.matchdays.first(where: { $0.spieltag == start - 1 }) else { throw Abort(.badRequest, reason: "First start matchday is MD2") }

        let drawOrder = participants

        let tippers = try firstMatchday.tippspieler
            .filter { return drawOrder.map { $0.name }.contains($0.name) }
            .sorted(by: { a,b in
                guard let indexA = drawOrder.firstIndex(where: { $0.name == a.name }),
                      let indexB = drawOrder.firstIndex(where: { $0.name == b.name })
                else { throw Abort(.badRequest, reason: "Couldn't find \(a.name) or \(b.name) in draw array.")}
                return indexA < indexB
            })

        guard tippers.count == drawOrder.count else {
            for drawUser in drawOrder {
                if !tippers.contains(where: { $0.name == drawUser.name }) {
                    print("falsch geschrieben: " + drawUser.name)
                }
            }
            throw Abort(.badRequest, reason: "Missing tippers in first matchday that appeared in draw")
        }

        let participants = Int(pow(2,ceil(log2(Double(tippers.count)))))
        let nonWildcardDuelsCount = (participants / 2) - (participants - tippers.count)
        let resultMD = self.mdc.matchdays.first(where: { $0.spieltag == start })
        var duels: [KnockOutDuel] = []

        func fetchTipper(_ index: Int) -> Tippspieler {
            var tipper = tippers[index]
            tipper.drawTipper = drawOrder.first(where: { $0.name == tipper.name })
            return tipper
        }

        for i in 0..<nonWildcardDuelsCount {
            let tipperA = fetchTipper(2 * i)
            let tipperB = fetchTipper(2 * i + 1)

            if let results = resultMD,
               var updateTipperA = results.tippspieler.first(where: { $0.name == tipperA.name }),
               var updateTipperB = results.tippspieler.first(where: { $0.name == tipperB.name })
            {
                updateTipperA.drawTipper = tipperA.drawTipper
                updateTipperB.drawTipper = tipperB.drawTipper
                let pointsA = updateTipperA.punkte
                let pointsB = updateTipperB.punkte
                duels.append(KnockOutDuel(
                    spielnummer: i + 1,
                    tipperA: updateTipperA,
                    tipperB: updateTipperB,
                    positionA: tipperA.position,
                    positionB: tipperB.position,
                    punkteA: pointsA,
                    punkteB: pointsB,
                    tieBreaker: tieBreaker
                ))
            } else {
                duels.append(KnockOutDuel(
                    spielnummer: i + 1,
                    tipperA: tipperA,
                    tipperB: tipperB,
                    positionA: tipperA.position,
                    positionB: tipperB.position,
                    punkteA: nil,
                    punkteB: nil,
                    tieBreaker: tieBreaker
                ))
            }
        }

        for i in (2 * nonWildcardDuelsCount)..<tippers.count {
            let tipper = fetchTipper(i)
            duels.append(KnockOutDuel(withWildcard: i - nonWildcardDuelsCount + 1, tipper: tipper, position: tipper.position))
        }

        return duels
    }
}

extension KnockOutController { // Helper for draw

    private func getDuelsForDraw(_ draw: DrawTipperArray, firstMatchday: Int) throws -> (firstRound: [KnockOutDuel], secondRound: [KnockOutDuel]) {
        let drawOrder = draw.drawnUser
        let numberOfParticipants = draw.drawnUser.count + (draw.nonDrawnUser?.count ?? 0)

        guard let firstMatchday = self.mdc.matchdays.first(where: { $0.spieltag == firstMatchday - 1 }) else { return (firstRound: [], secondRound: []) } // old behaviour: fatalError("First start matchday is MD2")

        let tippers = try firstMatchday.tippspieler
            .filter { return drawOrder.map { $0.name }.contains($0.name) }
            .sorted(by: { a,b in
                guard let indexA = drawOrder.firstIndex(where: { $0.name == a.name }),
                      let indexB = drawOrder.firstIndex(where: { $0.name == b.name })
                else { throw Abort(.badRequest, reason: "Couldn't find \(a.name) or \(b.name) in draw array.")}
                return indexA < indexB
            })

        let participants = Int(pow(2,ceil(log2(Double(numberOfParticipants)))))
        let firstRoundDuelsCount = (participants / 2) - (participants - numberOfParticipants)
        var duels: [KnockOutDuel] = []

        func fetchTipper(_ index: Int) -> Tippspieler {
            var tipper = tippers[index]
            tipper.drawTipper = drawOrder.first(where: { $0.name == tipper.name })
            return tipper
        }

        for i in 0..<min(firstRoundDuelsCount, tippers.count/2) {
            let tipperA = fetchTipper(2 * i)
            let tipperB = fetchTipper(2 * i + 1)

            duels.append(KnockOutDuel(
                spielnummer: i + 1,
                tipperA: tipperA,
                tipperB: tipperB,
                positionA: tipperA.position,
                positionB: tipperB.position,
                punkteA: nil,
                punkteB: nil,
                tieBreaker: .mehrExakteTipps
            ))
        }


        var duels2: [KnockOutDuel] = []

        if 2 * firstRoundDuelsCount < tippers.count {
            for i in (2 * firstRoundDuelsCount)..<tippers.count  {
                let tipper = fetchTipper(i)
                duels.append(KnockOutDuel(withWildcard: i - firstRoundDuelsCount + 1, tipper: tipper, position: tipper.position))
            }

            // Round 2:

            for i in 0..<(duels.count / 2) {
                let first = duels[2 * i]
                let second = duels[2 * i + 1]
                duels2.append(getNewDuel(from: first, against: second, matchNumber: i + participants/2 + 1, results: nil, tieBreaker: .mehrExakteTipps))
            }
        }

        duels = Array(duels[0..<(min(duels.count, firstRoundDuelsCount))])

        return (firstRound: duels, secondRound: duels2)
    }


}
