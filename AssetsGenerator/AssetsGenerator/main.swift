//
//  main.swift
//  AssetsGenerator
//
//  Created by Alexander Osokin on 14.01.2022.
//

import Foundation

//Select me!
let assets: Assets = .solana

let pathToAssets = "/Users/alexander.osokin/repos/github/assets/blockchains/\(assets.rawValue)/assets"
let jsonFileName = "info.json"
let resultJsonFileSuffix = "Tokens.json"
let assetsFolders = try! FileManager.default.contentsOfDirectory(at: URL(fileURLWithPath: pathToAssets), includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])

let twTokens = assetsFolders.map { path -> TWToken in
    let jsonPath = path.appendingPathComponent(jsonFileName)
    let fileContents = try! Data(contentsOf: jsonPath)
    let twToken = try! JSONDecoder().decode(TWToken.self, from: fileContents)
    return twToken
}

let tokens = twTokens.map { Token(from: $0) }

let encoder = JSONEncoder()
encoder.outputFormatting = .prettyPrinted
let jsonData = try! encoder.encode(tokens)
let jsonString = String(data: jsonData, encoding: .utf8)!

print("File saved to:")
let outputPath = "\(FileManager.default.currentDirectoryPath)/\(assets.rawValue)\(resultJsonFileSuffix)"
print(outputPath)
try! jsonString.write(toFile: outputPath, atomically: true, encoding: .utf8)

//print(jsonString)
