import Foundation

//remove scores per player: sub.p --> display.none

public class MyXMLParser: NSObject, XMLParserDelegate {

    private var xmlParser: XMLParser!
    private var currentString = ""

    // matchday object holders
    private var completeMatchday = Spieltag()

    private var readingMatchday = false

    private var readingPlayer = false
    private var helperDict: [PlayerStep: Any] = [:]
    private var currentStep: PlayerStep = .none

    private enum PlayerStep: Hashable {
        case none
        case position
        case positionsdifferenz(Bool)
        case name
        case ereignis(Int)
        case spieltagspunkte
        case bonus
        case siege
        case gesamtpunkte
    }

    var parsedSpieltag: Bool {
        // get the file path for the passed file in the playground bundle

        guard let contentData = FileManager.default.contents(atPath: "/Users/choli/Documents/workspace/diabyArmyParser/diabyArmyParser/Resources/sp11.xml")
        else { return false }

        self.xmlParser = XMLParser(data: contentData)
        self.xmlParser.delegate = self
        let success = self.xmlParser.parse()

        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let matchdayJsonData = try! encoder.encode(self.completeMatchday)
        print(String(data: matchdayJsonData, encoding: .utf8)!)

        return success
    }

    public func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        if let classes = attributeDict["class"] {
            if classes.hasPrefix("ereignis") {
                self.readingMatchday = true
                self.currentString = String(classes.suffix(1)) + ";"
            } else if classes.hasPrefix("clickable kicktipp") {
                self.readingPlayer = true
                self.currentString = ""
            } else if self.readingPlayer {
                self.setPlayerParsingState(element: elementName, classes: classes)
            }
        }
    }

    public func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if self.readingMatchday {
            if elementName == "th" {
                self.parseMatch()
                self.readingMatchday = false
            } else {
                self.currentString += ";"
            }
        } else if self.readingPlayer {
            if elementName == "tr" {
                self.parsePlayer()
                self.readingPlayer = false
                self.helperDict = [:]
                self.currentStep = .none
            } else if elementName == "td" {
                self.parsePlayerPart(element: elementName)
                self.currentString = ""
            }
        }
    }

    public func parser(_ parser: XMLParser, foundCharacters string: String) {
        let string = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard string.count > 0 else { return }
        self.currentString += string
    }

    public func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
        assertionFailure("ERROR: \(parseError.localizedDescription)")
    }

    // Parser functions
    private func parseMatch() {
        let strings = self.currentString.split(separator: ";").map { String($0) }
        if strings[3] == "-", strings[5] == "-" {
            return
        }
        guard let heim = Int(strings[3]), let gast = Int(strings[5]), let key = Int(strings[0])
        else { fatalError("Match not complete") }

        let result = Spiel(heimteam: strings[1],
                           gastteam: strings[2],
                           heim: heim,
                           gast: gast,
                           key: key)

        self.completeMatchday.resultate.append(result)
    }

    private func setPlayerParsingState(element: String, classes: String) {
        if element == "td" {
            if classes.hasPrefix("positionsdifferenz") {
                self.currentStep = .positionsdifferenz(!classes.hasSuffix("down"))
            } else if classes.hasPrefix("position") {
                self.currentStep = .position
            } else if classes.hasSuffix("name") {
                self.currentStep = .name
            } else if classes.contains("ereignis"), let matchday = Int(classes.suffix(1)) {
                self.currentStep = .ereignis(matchday)
            } else if classes.hasPrefix("spieltagspunkte") {
                self.currentStep = .spieltagspunkte
            } else if classes.hasPrefix("bonus") {
                self.currentStep = .bonus
            } else if classes.hasPrefix("siege") {
                self.currentStep = .siege
            } else if classes.hasPrefix("gesamtpunkte")  {
                self.currentStep = .gesamtpunkte
            }
        } else if element == "sub" {
            self.currentString += ":"
        }
    }

    private func parsePlayerPart(element: String) {
        switch self.currentStep {
        case .none:
            break
        case .position:
            self.helperDict[.position] = self.currentString
        case .positionsdifferenz(let positive):
            self.helperDict[.positionsdifferenz(positive)] = self.currentString
        case .name:
            self.helperDict[.name] = self.currentString
        case .ereignis(let matchday):
            self.helperDict[.ereignis(matchday)] = self.currentString
        case .spieltagspunkte:
            self.helperDict[.spieltagspunkte] = self.currentString
        case .bonus:
            self.helperDict[.bonus] = self.currentString
        case .siege:
            self.helperDict[.siege] = self.currentString
        case .gesamtpunkte:
            self.helperDict[.gesamtpunkte] = self.currentString
        }
    }

    private func parsePlayer() {
        guard  let name = self.helperDict[.name] as? String,
               let punkteString = self.helperDict[.spieltagspunkte] as? String, let punkte = Int(punkteString),
               let positionString = self.helperDict[.position] as? String, let position = Int(positionString),
               let bonusString = self.helperDict[.bonus] as? String, let bonus = Int(bonusString),
               let siegeString = self.helperDict[.siege] as? String,
               let gesamtString = self.helperDict[.gesamtpunkte] as? String, let gesamt = Int(gesamtString)
        else { fatalError("not all fields here") }
        let player = Tippspieler(name: name, punkte: punkte, position: position, bonus: bonus, siege: Decimal(Double(siegeString.replacingOccurrences(of: ",", with: ".")) ?? 0), gesamtpunkte: gesamt)
        for key in self.helperDict.keys.map({ $0 as PlayerStep }) {
            switch key {
            case .positionsdifferenz(let positive):
                guard let diffString = self.helperDict[.positionsdifferenz(positive)] as? String
                else { fatalError("couldn't parse diff of \(name) properly") }

                let diff = Int(diffString) ?? 0
                player.positiondiff = positive ? diff : -diff

            case .ereignis(let matchday):
                guard matchday < self.completeMatchday.resultate.count else {
                    print("matchday \(matchday) not played yet")
                    continue
                }
                guard let match = self.completeMatchday.resultate.first(where: { $0.matchkey == matchday }),
                      let resultString = self.helperDict[.ereignis(matchday)] as? String
                else { fatalError("couldn't parse matchday \(matchday) of \(name) properly") }

                let goals = resultString.split(separator: ":")
                if goals.count < 2 { continue }
                guard let heim = Int(goals[0]), let gast = Int(goals[1])
                else { fatalError("couldn't parse matchday \(matchday) of \(name) properly") }

                var spielpunkte = 0
                if goals.count >= 3, let points = Int(goals[2]) { spielpunkte = points }

                let spiel = Spiel(heimteam: match.heimteam,
                                  gastteam: match.gastteam,
                                  heim: heim,
                                  gast: gast,
                                  spielpunkte: spielpunkte,
                                  key: matchday)
                player.tipps.append(spiel)
            default:
                break
            }
        }
        self.completeMatchday.tippspieler.append(player)
    }
}
