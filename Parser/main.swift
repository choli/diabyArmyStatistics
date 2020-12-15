//
//  main.swift
//  diabyArmyParser
//
//  Created by Sandro Kolly on 28.10.20.
//

import Foundation

let parser = MyXMLParser()
let success = parser.parsedSpieltag

print("done \(success ? "successfully" : "with errors")")
