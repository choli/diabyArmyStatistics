import Vapor

struct TagTeamController: RouteCollection {
    let mdc: MatchdayController
    init(mdc: MatchdayController) {
        self.mdc = mdc
    }

    func boot(routes: RoutesBuilder) throws {

        routes.get("tagteam", ":round") { (req) -> EventLoopFuture<View> in
            guard let roundString = req.parameters.get("round"), let round = Int(roundString), round > 0
            else { throw Abort(.badRequest, reason: "Round not provided.") }

            let duels = self.getDuels(round, start: 31, tieBreaker: .mehrExakteTipps, filename: "tagteamtest")
            let dropDowns = self.getDropDownMenu(for: "tagteam", duels: duels.count, in: round)

            return req.view.render(
                "Pokal/tagTeam",
                [
                    "duels": StatisticObject.tagTeamDuels(duels),
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

    private func getDuels(_ round: Int, start: Int, tieBreaker: TagTeamDuel.TieBreaker, filename: String) -> [TagTeamDuel] {
        guard round > 1
        else { return self.getFirstRoundDuels(start: start, tieBreaker: tieBreaker, filename: filename) }

        let round = self.getDuelsInRound(round, start: start, tieBreaker: tieBreaker, filename: filename)
        return round
    }

    private func getDuelsInRound(_ round: Int, start: Int, tieBreaker: TagTeamDuel.TieBreaker, filename: String) -> [TagTeamDuel] {
        let previousDuels = round == 2 ?
            self.getFirstRoundDuels(start: start, tieBreaker: tieBreaker, filename: filename) :
            self.getDuelsInRound(round - 1, start: start, tieBreaker: tieBreaker, filename: filename)
        let maxId = previousDuels.map { $0.spielnummer }.max()!

        let resultMD = self.mdc.matchdays.first(where: { $0.spieltag == start + round - 1 })
        var duels: [TagTeamDuel] = []

        for i in 0..<(previousDuels.count / 2) {
            let first = previousDuels[2 * i]
            let second = previousDuels[2 * i + 1]
            let new = self.getNewDuel(from: first, against: second, matchNumber: maxId + i + 1, results: resultMD, tieBreaker: tieBreaker)
            duels.append(new)
        }

        return duels
    }

    private func getNewDuel(from first: TagTeamDuel, against second: TagTeamDuel, matchNumber: Int, results: Spieltag?, tieBreaker: TagTeamDuel.TieBreaker) -> TagTeamDuel {
        var tipperAa: Tippspieler
        var tipperAb: Tippspieler
        var teamnameA: String
        if first.winner == 0 {
            tipperAa = Tippspieler(name: "Sieger*innen Spiel \(first.spielnummer)", tipps: [], punkte: 0, position: 0, bonus: 0, siege: 0, gesamtpunkte: 0, spieltagssieger: nil)
            tipperAb = Tippspieler(name: "Sieger*innen Spiel \(first.spielnummer)", tipps: [], punkte: 0, position: 0, bonus: 0, siege: 0, gesamtpunkte: 0, spieltagssieger: nil)
            teamnameA = "Sieger*innen Spiel \(first.spielnummer)"
        } else {
            if first.winner == 1 {
                tipperAa = first.tipperAa
                tipperAa.drawTipper = first.tipperAa.drawTipper
                tipperAb = first.tipperAb
                tipperAb.drawTipper = first.tipperAb.drawTipper
                teamnameA = first.teamnameA
            } else {
                tipperAa = first.tipperAa
                tipperAa.drawTipper = first.tipperAa.drawTipper
                tipperAb = first.tipperAb
                tipperAb.drawTipper = first.tipperAb.drawTipper
                teamnameA = first.teamnameB
            }
        }

        var tipperBa: Tippspieler
        var tipperBb: Tippspieler
        var teamnameB: String
        if second.winner == 0 {
            tipperBa = Tippspieler(name: "Sieger*in Spiel \(second.spielnummer)", tipps: [], punkte: 0, position: 0, bonus: 0, siege: 0, gesamtpunkte: 0, spieltagssieger: nil)
            tipperBb = Tippspieler(name: "Sieger*in Spiel \(second.spielnummer)", tipps: [], punkte: 0, position: 0, bonus: 0, siege: 0, gesamtpunkte: 0, spieltagssieger: nil)
            teamnameB = "Sieger*in Spiel \(second.spielnummer)"
        } else {
            if second.winner == 1 {
                tipperBa = second.tipperAa
                tipperBa.drawTipper = second.tipperAb.drawTipper
                tipperBb = second.tipperAb
                tipperBb.drawTipper = second.tipperAb.drawTipper
                teamnameB = second.teamnameA
            } else {
                tipperBa = second.tipperBa
                tipperBa.drawTipper = second.tipperBa.drawTipper
                tipperBb = second.tipperBb
                tipperBb.drawTipper = second.tipperBb.drawTipper
                teamnameB = second.teamnameB
            }
        }

        if let results = results,
           var updateTipperAa = results.tippspieler.first(where: { $0.name == tipperAa.name }),
           var updateTipperAb = results.tippspieler.first(where: { $0.name == tipperAb.name }),
           var updateTipperBa = results.tippspieler.first(where: { $0.name == tipperBa.name }),
           var updateTipperBb = results.tippspieler.first(where: { $0.name == tipperBb.name })
        {
            updateTipperAa.drawTipper = tipperAa.drawTipper
            updateTipperAb.drawTipper = tipperAb.drawTipper
            updateTipperBa.drawTipper = tipperBa.drawTipper
            updateTipperBb.drawTipper = tipperBb.drawTipper
            let pointsAa = results.tippspieler.first(where: { $0.name == tipperAa.name })?.punkte ?? 0
            let pointsAb = results.tippspieler.first(where: { $0.name == tipperAb.name })?.punkte ?? 0
            let pointsBa = results.tippspieler.first(where: { $0.name == tipperBa.name })?.punkte ?? 0
            let pointsBb = results.tippspieler.first(where: { $0.name == tipperBb.name })?.punkte ?? 0
            let pointsA = pointsAa + pointsAb
            let pointsB = pointsBa + pointsBb
            return TagTeamDuel(
                spielnummer: matchNumber,
                teamnameA: teamnameA,
                teamnameB: teamnameB,
                tipperAa: updateTipperAa,
                tipperAb: updateTipperAb,
                tipperBa: updateTipperBa,
                tipperBb: updateTipperBb,
                punkteA: pointsA,
                punkteB: pointsB,
                tieBreaker: tieBreaker
            )
        } else {
            return TagTeamDuel(
                spielnummer: matchNumber,
                teamnameA: teamnameA,
                teamnameB: teamnameB,
                tipperAa: tipperAa,
                tipperAb: tipperAb,
                tipperBa: tipperBa,
                tipperBb: tipperBb,
                punkteA: nil,
                punkteB: nil,
                tieBreaker: tieBreaker
            )
        }
    }

    private func getFirstRoundDuels(start: Int, tieBreaker: TagTeamDuel.TieBreaker, filename: String) -> [TagTeamDuel] {
        guard let firstMatchday = self.mdc.matchdays.first(where: { $0.spieltag == start - 1 }) else { fatalError("First start matchday is MD2") }

        let drawOrder: [DrawTagTeam]
            guard let fileContent = FileManager.default.contents(atPath: "Resources/Draws/\(filename).json"),
              let spieler = try? JSONDecoder().decode(DrawTagTeamArray.self, from: fileContent)
            else { fatalError("Couldn't read file with draws") }
        drawOrder = spieler.drawnTeams

        let tippers = firstMatchday.tippspieler
            .filter {
                let mapped = drawOrder.reduce([String]()) { res, team in
                    var res2 = res
                    res2.append(team.teamplayerA.name)
                    res2.append(team.teamplayerB.name)
                    return res2
                }
                return mapped.contains($0.name)
            }
            .sorted(by: { a,b in
                guard let indexA = drawOrder.firstIndex(where: { $0.teamplayerA.name == a.name || $0.teamplayerB.name == a.name }),
                      let indexB = drawOrder.firstIndex(where: { $0.teamplayerA.name == b.name || $0.teamplayerB.name == b.name })
                else { fatalError("Couldn't find \(a.name) or \(b.name) in draw array.")}
                return indexA == indexB ? drawOrder[indexA].teamplayerA.name == a.name : indexA < indexB
            })

        guard tippers.count == drawOrder.count * 2 else {
            for drawTeam in drawOrder {
                if !tippers.contains(where: { $0.name == drawTeam.teamplayerA.name || $0.name == drawTeam.teamplayerB.name }) {
                    print("falsch geschrieben: Mitglied aus " + drawTeam.teamname)
                }
            }
            fatalError("Missing tippers in first matchday that appeared in draw")
        }

        let participants = Int(pow(2,ceil(log2(Double(tippers.count / 2)))))
        let nonWildcardDuelsCount = (participants / 2) - (participants - (tippers.count / 2))
        let resultMD = self.mdc.matchdays.first(where: { $0.spieltag == start })
        var duels: [TagTeamDuel] = []

        func fetchTipper(_ index: Int) -> Tippspieler {
            var tipper = tippers[index]
            let teamplayerA = drawOrder.first(where: { $0.teamplayerA.name == tipper.name })?.teamplayerA
            let teamplayerB = drawOrder.first(where: { $0.teamplayerB.name == tipper.name })?.teamplayerB
            tipper.drawTipper = teamplayerA != nil ? teamplayerA : teamplayerB
            return tipper
        }

        for i in 0..<nonWildcardDuelsCount {
            let tipperAa = fetchTipper(4 * i)
            let tipperAb = fetchTipper(4 * i + 1)
            let tipperBa = fetchTipper(4 * i + 2)
            let tipperBb = fetchTipper(4 * i + 3)

            if let results = resultMD,
               var updateTipperAa = results.tippspieler.first(where: { $0.name == tipperAa.name }),
               var updateTipperAb = results.tippspieler.first(where: { $0.name == tipperAb.name }),
               var updateTipperBa = results.tippspieler.first(where: { $0.name == tipperBa.name }),
               var updateTipperBb = results.tippspieler.first(where: { $0.name == tipperBb.name })
            {
                updateTipperAa.drawTipper = tipperAa.drawTipper
                updateTipperAb.drawTipper = tipperAb.drawTipper
                updateTipperBa.drawTipper = tipperBa.drawTipper
                updateTipperBb.drawTipper = tipperBb.drawTipper
                let pointsA = updateTipperAa.punkte + updateTipperAb.punkte
                let pointsB = updateTipperBa.punkte + updateTipperBb.punkte
                duels.append(
                    TagTeamDuel(spielnummer: i + 1,
                                teamnameA: drawOrder[i].teamname,
                                teamnameB: drawOrder[i + 1].teamname,
                                tipperAa: updateTipperAa,
                                tipperAb: updateTipperAb,
                                tipperBa: updateTipperBa,
                                tipperBb: updateTipperBb,
                                punkteA: pointsA,
                                punkteB: pointsB,
                                tieBreaker: tieBreaker
                    )
                )
            } else {
                duels.append(
                    TagTeamDuel(spielnummer: i + 1,
                                teamnameA: drawOrder[i].teamname,
                                teamnameB: drawOrder[i + 1].teamname,
                                tipperAa: tipperAa,
                                tipperAb: tipperAb,
                                tipperBa: tipperBa,
                                tipperBb: tipperBb,
                                punkteA: nil,
                                punkteB: nil,
                                tieBreaker: tieBreaker
                ))
            }
        }

        for i in (4 * nonWildcardDuelsCount)..<tippers.count {
            let tipperAa = fetchTipper(i)
            let tipperAb = fetchTipper(i + 1)
            duels.append(
                TagTeamDuel(withWildcard: i - nonWildcardDuelsCount,
                            teamname: drawOrder[i].teamname,
                            tipperAa: tipperAa,
                            tipperAb: tipperAb
                )
            )
        }

        return duels
    }
}
