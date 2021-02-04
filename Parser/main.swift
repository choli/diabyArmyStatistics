
import Foundation

let parser = MyXMLParser()
let success = parser.parsedSpieltag

print("done \(success ? "successfully" : "with errors")")
