import Foundation
#if !DEBUG
import FoundationXML
import FoundationNetworking
#endif

public class MyXMLParser: NSObject, XMLParserDelegate {

    private var xmlParser: XMLParser!
    private var currentString = ""

    // matchday object holders
    private var readingMatchday = false

    private var readingPlayer = false
    private var helperDict: [PlayerStep: Any] = [:]
    private var currentStep: PlayerStep = .none

    // MARK: - Put proper matchday in here <---- 👈🏽 🐸
    private var completeMatchday = Spieltag(spieltag: 29)

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
        case spieltagssieger
    }

    var parsedSpieltag: Bool {
        let semaphore = DispatchSemaphore (value: 0)

        let matchday = self.completeMatchday.spieltag
        var previousContent = Data()

        for offset in stride(from: 20, through: 400, by: 20) {
            self.getXmlData(for: matchday, offset: offset) { data in
                guard let contentData = data else { fatalError() }
                guard contentData != previousContent else { semaphore.signal(); return }
                previousContent = contentData

                self.xmlParser = XMLParser(data: contentData)
                self.xmlParser.delegate = self
                self.xmlParser.parse()

                let encoder = JSONEncoder()
                encoder.outputFormatting = .prettyPrinted
                let matchdayJsonData = try! encoder.encode(self.completeMatchday)

                let json = String(data: matchdayJsonData, encoding: .utf8)!

                self.writeJson(json, for: matchday)
            }
        }

        semaphore.wait()
        return success
    }

    private func writeJson(_ json: String, for matchday: Int) {
        let fileUrl = URL(fileURLWithPath: "/Users/choli/Documents/workspace/diabyArmy/Resources/Matchdays/diabyarmy\(matchday).json")
        try! json.write(to: fileUrl, atomically: true, encoding: .utf8)
    }

    private func getXmlData(for matchday: Int, offset: Int, completion: @escaping (Data?) -> Void) {
        let semaphore = DispatchSemaphore (value: 0)

        var request = URLRequest(url: URL(string: "https://www.kicktipp.de/diabyarmy/tippuebersicht?&spieltagIndex=\(matchday)&offset=\(offset)")!,timeoutInterval: Double.infinity)
        request.addValue("www.kicktipp.de", forHTTPHeaderField: "Host")
        request.addValue("text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8", forHTTPHeaderField: "Accept")
        // Adds login from intercepted headers
        //request.addValue("kurzname=diabyarmy; login=***; JSESSIONID=***; kt_browser_timezone=Europe%2FZurich; kurzname=diabyarmy; kurzname=diabyarmy; login=***; JSESSIONID=***", forHTTPHeaderField: "Cookie")
        request.addValue("de-ch", forHTTPHeaderField: "Accept-Language")

        request.httpMethod = "GET"

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, let fullContent = String(data: data, encoding: .utf8) else {
                print(String(describing: error))
                completion(nil)
                return
            }

            var trimmedString = self.crawlNecessaryTableOnly(from: fullContent)
            trimmedString = trimmedString.replacingOccurrences(of: "&e", with: "&amp;e")
            trimmedString = trimmedString.replacingOccurrences(of: "&r", with: "&amp;r")

            completion(trimmedString.data(using: .utf8))
            semaphore.signal()
        }

        task.resume()
        semaphore.wait()

    }

    private func crawlNecessaryTableOnly(from string: String) -> String {
        let string2 = "<table id=\"ranking\""
        let index2 = string.range(of: string2)!.lowerBound

        return String(string[index2...])
    }

    public func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        if let classes = attributeDict["class"] {
            if classes.hasPrefix("ereignis") {
                self.readingMatchday = true
                self.currentString = String(classes.suffix(1)) + ";"
            } else if classes.hasPrefix("clickable kicktipp") {
                if classes.contains("sptsieger") {
                    self.helperDict[.spieltagssieger] = true
                }
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
//        assertionFailure("ERROR: \(parseError.localizedDescription)")
        print("whats the error:\n\(parseError.localizedDescription)")
    }

    // Parser functions
    private func parseMatch() {
        let strings = self.currentString.split(separator: ";").map { String($0) }
        if strings[3] == "-", strings[5] == "-" {
            return
        }
        guard let heim = Int(strings[3]), let gast = Int(strings[5]), let key = Int(strings[0])
        else { fatalError("Match not complete") }

        if self.completeMatchday.resultate.contains(where: { $0.heimteam == strings[1] && $0.gastteam == strings[2] }) {
            return
        }

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
        case .spieltagssieger:
            break
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

        guard !self.completeMatchday.tippspieler.contains(where: { $0.name == name }) else { return }

        let player = Tippspieler(name: name, punkte: punkte, position: position, bonus: bonus, siege: Decimal(Double(siegeString.replacingOccurrences(of: ",", with: ".")) ?? 0), gesamtpunkte: gesamt, spieltagssieger: helperDict[.spieltagssieger] as? Bool)
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
