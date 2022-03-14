//
//  main.swift
//  AssetsGenerator
//
//  Created by Alexander Osokin on 14.01.2022.
//

import Foundation

var verbose = true

func log(_ string: String) {
    if verbose {
        print(string)
    }
}
///Users/alexander.osokin/Library/Developer/Xcode/DerivedData/AssetsGenerator-cpdytibrrxrpafddymdcsbldpqtp/Build/Products/Debug

func readExistingAssets(asset: Asset) -> [TangemToken] {
    let fileName = asset.fileName
    
    let pathToExistingAssets = "/Users/alexander.osokin/repos/tangem/tangem-ios/Tangem/Resources/"
    let existingAssetsURL = URL(fileURLWithPath: pathToExistingAssets)
    let existingAssetFileURL = existingAssetsURL.appendingPathComponent(fileName)
    let existingTokens = (try? JSONDecoder().decode([TangemToken].self, from: Data(contentsOf: existingAssetFileURL))) ?? []
    
//    let existingTokensWithImages = existingTokens.map { token -> TangemToken in
//        var mutableToken = token
//        let contract = token.contractAddress.trimmingCharacters(in: .whitespacesAndNewlines)
//        let imageUrl = "https://raw.githubusercontent.com/trustwallet/assets/master/blockchains/\(asset.twAssetsPath)/assets/\(contract)/logo.png"
//        mutableToken.customIconUrl = imageUrl
//        return mutableToken
//    }
    
    return existingTokens
}

func run(asset: Asset) async throws -> (Int, Int) {
    log("-------------------------------------------------------------------")
    log("Start tokens processing for \(asset.rawValue)")

    let assetTokens = try await asset.readTokens()
//        .filter({ !$0.name.isEmpty })
//        .filter({ !$0.symbol.isEmpty })
    
    log("Read \(assetTokens.count) tokens from lists")
  
    let existingTokens = readExistingAssets(asset: asset)
    log("Read \(existingTokens.count) existing tokens")
    
    var finalTokenList = assetTokens
//    var missingDonors = 0
//    var conflicted = 0
//    if !asset.isTestnet {
//        // check with CoinGecko
//        let cg = CoinGecko()
//        let cgList = try await cg.load()
//        let cgTokens = cgList[asset.cgPlatform]!
//
//        log("Read \(cgTokens.count) tokens from CoinGecko")
//
//        let filteredTokens = cgTokens.filter { token in
//            let price = token.usdPrice ?? -1
//            if price.rounded() >= 0.01 {
//            //    log("\(price)")
//                return true
//            }
//
//            return false
//        }.compactMap { cgToken -> TangemToken? in
//            guard let platformContract = cgToken.platforms[asset.cgPlatform], var contract = platformContract else {
//                fatalError()
//            }
//
//            var manualDecimals: Int? = nil
//
//            if asset == .polygon {
//                if contract == "0x9fb83c0635de2e815fd1c21b3a292277540c2e8d" { //fix polygon busd
//                    contract = "0xdab529f40e671a1d4bf91361c21bf9f0c9712ab7"
//                }
//
//                if contract == "0x6ab6d61428fde76768d7b45d8bfeec19c6ef91a8"//Anyswap
//                    || contract == "0x1a3acf6d19267e2d3e7f898f42803e90c9219062" //"Frax Share"
//                {
//                    manualDecimals = 18
//                }
//            }
//
//            if let assetToken = assetTokens.first(where: { $0.contractAddress.lowercased() == contract.lowercased() })  {
//                return TangemToken(name: cgToken.name.trimmingCharacters(in: .whitespacesAndNewlines),
//                                   symbol: cgToken.symbol.trimmingCharacters(in: .whitespacesAndNewlines).uppercased(),
//                                   contractAddress: contract.trimmingCharacters(in: .whitespacesAndNewlines),
//                                   decimalCount: assetToken.decimalCount,
//                                   customIconUrl: assetToken.customIconUrl)
//            }
//
//            if let fixedDecimals = asset.fixedDecimals ?? manualDecimals {
//                return TangemToken(name: cgToken.name.trimmingCharacters(in: .whitespacesAndNewlines),
//                                   symbol: cgToken.symbol.trimmingCharacters(in: .whitespacesAndNewlines).uppercased(),
//                                   contractAddress: contract.trimmingCharacters(in: .whitespacesAndNewlines),
//                                   decimalCount: fixedDecimals,
//                                   customIconUrl: nil)
//            }
//
//            missingDonors += 1
//
//            if let possibleAssetToken = assetTokens.first(where: { $0.symbol.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == cgToken.symbol.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() && $0.name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == cgToken.name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }) {
//                //log("Conflict detected.\nCGToken: \(cgToken.jsonDescription) \nwith: \(possibleAssetToken.jsonDescription)")
//                conflicted += 1
//                return nil
//            }
//
//
//            //log("Can't find donor token for \(cgToken.name) (\(contract))")
//            return nil
//        }
//        log("\(missingDonors) missed tokens.")
//        finalTokenList = Set(filteredTokens)
//    } else {
//        finalTokenList = Set(assetTokens)
//    }
    
    // Restore tokens
    let deletedTokens = Set(existingTokens).subtracting(finalTokenList)
    log("\(deletedTokens.count) deleted tokens restored.")
    var restoredCount = 0
    for deletedToken in deletedTokens {
        if let existingIndex = finalTokenList.firstIndex(where: { $0 == deletedToken }) {
            log("Token updated from: \(deletedToken.jsonDescription)\nto: \(finalTokenList[existingIndex].jsonDescription)")
        } else {
            //  log("Token restored: \(deletedToken.name) (\(deletedToken.contractAddress))")
            finalTokenList.append(deletedToken)
            restoredCount += 1
        }
    }
    
    let newTokens = Set(finalTokenList).subtracting(existingTokens)
    log("\(newTokens.count) new tokens added.")
    
    //compare
    
//    for token in finalTokenList {
//        if let oldToken = existingTokens.first(where: { $0 == token }) {
//            if oldToken.decimalCount != token.decimalCount {
//                log("Token decimals changed from: \(oldToken.jsonDescription)\nto: \(token.jsonDescription)")
//            }
//        }
//    }
    
    //print new
    newTokens.filter{ $0.decimalCount == 0 }.forEach { token in
        log(token.jsonDescription)
    }
    
    
    
    //write new assets
    let tokens = finalTokenList// Array(finalTokenList).sorted(by: { $0.name < $1.name })
    let newAssetsFileURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath).appendingPathComponent(asset.fileName)
    try! tokens.jsonDescription.write(to: newAssetsFileURL, atomically: true, encoding: .utf8)
    log("\(tokens.count) tokens saved to: \(newAssetsFileURL.absoluteString)")
    return (tokens.count, restoredCount)
}


func mainTask() {
    Task {
        do {
            //  _ = try await CoinGecko().load(forced: true)
            var totalTokensCount = 0
            var totalRestoredCount = 0

            for asset in Asset.productionCases {
                let result = try await run(asset: asset)
                print("\(asset.rawValue) tokens: \(result.0). Restored \(result.1)")
                totalTokensCount += result.0
                totalRestoredCount += result.1
            }

            print("Total tokens: \(totalTokensCount)")
            print("Total restored: \(totalRestoredCount)")
        } catch {
            print(error)
        }
        exit(0)
    }
}

//func mapTangem() {
//    Task {
//        do {
//            let reader = TokenReader()
//            var totalTokensCount = 0
//
//            for asset in Asset.productionCases {
//                let result = try await reader.loadTangem(asset: asset)
//                let sorted = result.sorted(by: { $0.name < $1.name })
//                let newAssetsFileURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath).appendingPathComponent(asset.fileName)
//                try! sorted.jsonDescription.write(to: newAssetsFileURL, atomically: true, encoding: .utf8)
//                log("\(sorted.count) tokens saved to: \(newAssetsFileURL.absoluteString)")
//               // print("\(asset.rawValue) tokens: \(result.count)")
//                totalTokensCount += result.count
//            }
//
//            print("Total tokens: \(totalTokensCount)")
//
//        } catch {
//            print(error)
//        }
//        exit(0)
//    }
//}

mainTask()
//mapTangem()
dispatchMain()
