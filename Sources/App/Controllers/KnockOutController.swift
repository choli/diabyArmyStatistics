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

            let duels = self.getDuels(round, start: 8, participants: 64, filter: ["choli"])

            return req.view.render(
                "apertura",
                [
                    "duels": StatisticObject.knockOutDuels(duels),
                    "title": StatisticObject.singleString(self.title(for: round, participants: 64))
                ]
            )
        }
    }

    private func title(for round: Int, participants: Int) -> String {
        let rounds = Int(log2(Double(participants)))
        switch rounds - round {
        case 0: return "Finale"
        case 1: return "Halbfinale"
        case 2: return "Viertelfinale"
        case 3: return "Achtelfinale"
        default: break
        }

        switch round {
        case 1: return "Erste Runde"
        case 2: return "Zweite Runde"
        case 3: return "Dritte Runde"
        case 4: return "Vierte Runde"
        default: break
        }

        return ""
    }

    private func getDuels(_ round: Int, start: Int, participants: Int, filter: [String]? = nil) -> [KnockOutDuel] {
        guard round > 1
        else { return self.getFirstRoundDuels(start: start, participants: participants, filter: filter ?? []) }

        let round = self.getDuelsInRound(round, start: start, participants: participants, filter: filter ?? [])
        return round
    }

    private func getDuelsInRound(_ round: Int, start: Int, participants: Int, filter: [String]) -> [KnockOutDuel] {
        let previousDuels = round == 2 ?
            self.getFirstRoundDuels(start: start, participants: participants, filter: filter) :
            self.getDuelsInRound(round - 1, start: start, participants: participants, filter: filter)
        let maxId = previousDuels.map { $0.spielnummer }.max()!

        let resultMD = self.mdc.matchdays.first(where: { $0.spieltag == start + round - 1 })
        var duels: [KnockOutDuel] = []

        for i in 0..<(previousDuels.count / 2) {
            let first = previousDuels[2 * i]
            let second = previousDuels[2 * i + 1]
            let new = self.getNewDuel(from: first, against: second, matchNumber: maxId + i + 1, results: resultMD)
            duels.append(new)
        }

        return duels
    }

    private func getNewDuel(from first: KnockOutDuel, against second: KnockOutDuel, matchNumber: Int, results: Spieltag?) -> KnockOutDuel {
        let tipperA: Tippspieler
        if let firstPointsA = first.punkteA, let firstPointsB = first.punkteB {
            if firstPointsA == firstPointsB {
                tipperA = first.tipperA.gesamtpunkte > first.tipperB.gesamtpunkte ? first.tipperA : first.tipperB
            } else {
                tipperA = firstPointsA > firstPointsB ? first.tipperA : first.tipperB
            }
        } else {
            tipperA = Tippspieler(name: "Sieger*in Spiel \(first.spielnummer)", tipps: [], punkte: 0, position: 0, bonus: 0, siege: 0, gesamtpunkte: 0)
        }

        let tipperB: Tippspieler
        if let secondPointsA = second.punkteA, let secondPointsB = second.punkteB {
            if secondPointsA == secondPointsB {
                tipperB = second.tipperA.gesamtpunkte > second.tipperB.gesamtpunkte ? second.tipperA : second.tipperB
            } else {
                tipperB = secondPointsA > secondPointsB ? second.tipperA : second.tipperB
            }
        } else {
            tipperB = Tippspieler(name: "Sieger*in Spiel \(second.spielnummer)", tipps: [], punkte: 0, position: 0, bonus: 0, siege: 0, gesamtpunkte: 0)
        }

        if let results = results {
            let pointsA = results.tippspieler.first(where: { $0.name == tipperA.name })?.punkte ?? 0
            let pointsB = results.tippspieler.first(where: { $0.name == tipperB.name })?.punkte ?? 0
            return KnockOutDuel(
                spielnummer: matchNumber,
                tipperA: tipperA,
                tipperB: tipperB,
                punkteA: pointsA,
                punkteB: pointsB
            )
        } else {
            return KnockOutDuel(
                spielnummer: matchNumber,
                tipperA: tipperA,
                tipperB: tipperB,
                punkteA: nil,
                punkteB: nil
            )
        }


    }

    private func getFirstRoundDuels(start: Int, participants: Int, filter: [String]) -> [KnockOutDuel] {
        guard let firstMatchday = self.mdc.matchdays.first(where: { $0.spieltag == start - 1 }),
              log2(Double(participants)).truncatingRemainder(dividingBy: 1) == 0 else { fatalError("Wrong setup") }
        let tippers = firstMatchday.tippspieler
            .filter { !filter.contains($0.name) }
            .sorted(by: { a,b in
                let pseudoA = String(a.name.data(using: .utf8)!.base64EncodedString().reversed())
                let pseudoB = String(b.name.data(using: .utf8)!.base64EncodedString().reversed())
                return pseudoA < pseudoB
            })

        let resultMD = self.mdc.matchdays.first(where: { $0.spieltag == start })

        var duels: [KnockOutDuel] = []

        for i in 0..<(participants / 2) {
            let tipperA = tippers[2 * i]
            let tipperB = tippers[2 * i + 1]

            if let results = resultMD {
                let pointsA = results.tippspieler.first(where: { $0.name == tipperA.name })?.punkte ?? 0
                let pointsB = results.tippspieler.first(where: { $0.name == tipperB.name })?.punkte ?? 0
                duels.append(KnockOutDuel(
                    spielnummer: i + 1,
                    tipperA: tipperA,
                    tipperB: tipperB,
                    punkteA: pointsA,
                    punkteB: pointsB
                ))
            } else {
                duels.append(KnockOutDuel(
                    spielnummer: i + 1,
                    tipperA: tipperA,
                    tipperB: tipperB,
                    punkteA: nil,
                    punkteB: nil
                ))
            }
        }

        return duels

    }
}
