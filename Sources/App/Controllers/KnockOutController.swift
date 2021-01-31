import Vapor

struct KnockOutController: RouteCollection {
    let mdc: MatchdayController
    init(mdc: MatchdayController) {
        self.mdc = mdc
    }

    func boot(routes: RoutesBuilder) throws {

        routes.get("apertura", ":round") { (req) -> EventLoopFuture<View> in
            guard let roundString = req.parameters.get("round"), let round = Int(roundString), round > 0
            else { throw Abort(.badRequest, reason: "Round not provided.") }

            let duels = self.getDuels(round, start: 8, tieBreaker: .gesamtpunkte, filename: "apertura2021")
            let dropDowns = self.getDropDownMenu(for: "apertura", duels: duels.count, in: round)

            return req.view.render(
                "apertura",
                [
                    "duels": StatisticObject.knockOutDuels(duels),
                    "title": StatisticObject.singleString(self.title(for: round, duels: duels.count)),
                    "dropDown": StatisticObject.dropDownDataObject(dropDowns)
                ]
            )
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
        case 4: return "Viertelfinale"
        case 8: return "Achtelfinale"
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

    private func getDuels(_ round: Int, start: Int, tieBreaker: KnockOutDuel.TieBreaker, filename: String) -> [KnockOutDuel] {
        guard round > 1
        else { return self.getFirstRoundDuels(start: start, tieBreaker: tieBreaker, filename: filename) }

        let round = self.getDuelsInRound(round, start: start, tieBreaker: tieBreaker, filename: filename)
        return round
    }

    private func getDuelsInRound(_ round: Int, start: Int, tieBreaker: KnockOutDuel.TieBreaker, filename: String) -> [KnockOutDuel] {
        let previousDuels = round == 2 ?
            self.getFirstRoundDuels(start: start, tieBreaker: tieBreaker, filename: filename) :
            self.getDuelsInRound(round - 1, start: start, tieBreaker: tieBreaker, filename: filename)
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
        let tipperA: Tippspieler
        if first.winner == 0 {
            tipperA = Tippspieler(name: "Sieger*in Spiel \(first.spielnummer)", tipps: [], punkte: 0, position: 0, bonus: 0, siege: 0, gesamtpunkte: 0)
        } else {
            tipperA = first.winner == 1 ? first.tipperA : first.tipperB
        }

        let tipperB: Tippspieler
        if second.winner == 0 {
            tipperB = Tippspieler(name: "Sieger*in Spiel \(second.spielnummer)", tipps: [], punkte: 0, position: 0, bonus: 0, siege: 0, gesamtpunkte: 0)
        } else {
            tipperB = second.winner == 1 ? second.tipperA : second.tipperB
        }

        if let results = results,
           let updateTipperA = results.tippspieler.first(where: { $0.name == tipperA.name }),
           let updateTipperB = results.tippspieler.first(where: { $0.name == tipperB.name })
        {
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

    private struct DrawArray: Codable {
        struct Tipper: Codable {
            let name: String
            let twitterHandle: String?
        }
        let tippspieler: [Tipper]
    }

    private func getFirstRoundDuels(start: Int, tieBreaker: KnockOutDuel.TieBreaker, filename: String) -> [KnockOutDuel] {
        guard let firstMatchday = self.mdc.matchdays.first(where: { $0.spieltag == start - 1 }) else { fatalError("First start matchday is MD2") }

        let drawOrder: [DrawArray.Tipper]
            guard let fileContent = FileManager.default.contents(atPath: "Resources/Draws/\(filename).json"),
              let spieler = try? JSONDecoder().decode(DrawArray.self, from: fileContent)
            else { fatalError("Couldn't read file with draws") }
        drawOrder = spieler.tippspieler

        let tippers = firstMatchday.tippspieler
            .filter { return drawOrder.map { $0.name }.contains($0.name) }
            .sorted(by: { a,b in
                guard let indexA = drawOrder.firstIndex(where: { $0.name == a.name }),
                      let indexB = drawOrder.firstIndex(where: { $0.name == b.name })
                else { fatalError("Couldn't find \(a.name) or \(b.name) in draw array.")}
                return indexA < indexB
            })

        guard tippers.count == drawOrder.count else { fatalError("Missing tippers in first matchday that appeared in draw") }

        let participants = Int(pow(2,ceil(log2(Double(tippers.count)))))

        let nonWildcardDuelsCount = (participants / 2) - (participants - tippers.count)

        let resultMD = self.mdc.matchdays.first(where: { $0.spieltag == start })

        var duels: [KnockOutDuel] = []

        for i in 0..<nonWildcardDuelsCount {
            let tipperA = tippers[2 * i]
            let tipperB = tippers[2 * i + 1]

            if let results = resultMD,
               let updateTipperA = results.tippspieler.first(where: { $0.name == tipperA.name }),
               let updateTipperB = results.tippspieler.first(where: { $0.name == tipperB.name })
            {
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
            let tipper = tippers[i]
            duels.append(KnockOutDuel(withWildcard: i - nonWildcardDuelsCount + 1, tipper: tipper, position: tipper.position))
        }

        return duels

    }
}
