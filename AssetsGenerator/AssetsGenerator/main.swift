//
//  main.swift
//  AssetsGenerator
//
//  Created by Alexander Osokin on 14.01.2022.
//

import Foundation
//Input
let assets: Assets = .ethereumTestnet

//Constants
let pathToAssets = "/Users/alexander.osokin/repos/github/assets/blockchains/\(assets.assetsPath)/assets"
let pathToExistingAssets = "/Users/alexander.osokin/Library/Developer/Xcode/DerivedData/AssetsGenerator-cpdytibrrxrpafddymdcsbldpqtp/Build/Products/Debug/old"
let jsonFileName = "info.json"
let assetsFileName = "\(assets.rawValue).json"

let pathToAvaxTokensList = "/Users/alexander.osokin/repos/tangem/tokenlists/defi.tokenlist.json"
let pathToAvaxTestnetTokensList = "/Users/alexander.osokin/repos/tangem/tokenlists/fuji.tokenlist.json"

print("Start tokens processing for \(assets.rawValue)")


//read avalancheTestnet
if assets == .avalancheTestnet {
    let fileURL = URL(fileURLWithPath: pathToAvaxTestnetTokensList)
    let tokenList = try! JSONDecoder().decode(TokenList.self, from: Data(contentsOf: fileURL))
    print("Read \(tokenList.tokens.count) avalanche testnet tokens")
    
    let tokens = tokenList.tokens
        .filter({ $0.chainId == assets.avalancheChainId })
        .map { NewToken(from: $0 )}
        .sorted(by: { $0.name < $1.name })
    
    let newAssetsFileURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath).appendingPathComponent(assetsFileName)
    try! tokens.jsonDescription.write(to: newAssetsFileURL, atomically: true, encoding: .utf8)
    print("\(tokens.count) \(assets.rawValue) tokens saved to: \(newAssetsFileURL.absoluteString)")
    exit(0)
}


// just convert to the new format
if assets == .bscTestnet || assets == .solanaTestnet || assets == .binanceTestnet || assets == .ethereumTestnet {
    let existingAssetsURL = URL(fileURLWithPath: pathToExistingAssets)
    let existingAssetFileURL = existingAssetsURL.appendingPathComponent(assetsFileName)
    let existingTokens = (try? JSONDecoder().decode([NewToken].self, from: Data(contentsOf: existingAssetFileURL))) ?? []
    let tokens = Array(existingTokens).sorted(by: { $0.name < $1.name })
    let newAssetsFileURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath).appendingPathComponent(assetsFileName)
    try! tokens.jsonDescription.write(to: newAssetsFileURL, atomically: true, encoding: .utf8)
    print("\(tokens.count) \(assets.rawValue) tokens saved to: \(newAssetsFileURL.absoluteString)")
    exit(0)
}

//read tw assets
let assetsURL = URL(fileURLWithPath: pathToAssets)
let assetsFolders = try! FileManager.default.contentsOfDirectory(at: assetsURL, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])

let twTokens = assetsFolders.map { path -> TWToken in
    let jsonPath = path.appendingPathComponent(jsonFileName)
    let fileContents = try! Data(contentsOf: jsonPath)
    let twToken = try! JSONDecoder().decode(TWToken.self, from: fileContents)
    return twToken
}

let inconsistentTokens = twTokens.filter { $0.type != assets.type }
if !inconsistentTokens.isEmpty {
    print("Found \(inconsistentTokens.count) inconsistent tokens:\n\(inconsistentTokens.jsonDescription)")
}

let forbiddenSymbols = ["\"", "0x", "(", "�", "$", "CM - "]

var readTokens = twTokens
    .filter({ $0.type == assets.type })
    .filter({ !$0.name.isEmpty })
    .filter({ !$0.symbol.isEmpty })
    .filter({ !$0.name.contains(forbiddenSymbols) })
    .filter({ !$0.symbol.contains(forbiddenSymbols) })
    .filter({ Int($0.name) == nil })
    .map { NewToken(from: $0) }

print("Read \(readTokens.count) tokens")

//read avalanche
if assets == .avalanche {
    let fileURL = URL(fileURLWithPath: pathToAvaxTokensList)
    let tokenList = try! JSONDecoder().decode(TokenList.self, from: Data(contentsOf: fileURL))
    print("Read \(tokenList.tokens.count) avalanche tokens")
    
    let additionalTokens = tokenList.tokens
        .filter({ $0.chainId == assets.avalancheChainId })
        .filter({ !$0.name.isEmpty })
        .filter({ !$0.symbol.isEmpty })
        .filter({ !$0.name.contains(forbiddenSymbols) })
        .filter({ !$0.symbol.contains(forbiddenSymbols) })
        .map { NewToken(from: $0 )}
    
    readTokens.append(contentsOf: additionalTokens)
}


// read existing assets
let existingAssetsURL = URL(fileURLWithPath: pathToExistingAssets)
let existingAssetFileURL = existingAssetsURL.appendingPathComponent(assetsFileName)
let existingTokens = (try? JSONDecoder().decode([NewToken].self, from: Data(contentsOf: existingAssetFileURL))) ?? []
print("Read \(existingTokens.count) existing tokens")

var completeTokensList = Set(readTokens)

// Merge lists
let newTokens = completeTokensList.subtracting(existingTokens)
guard newTokens.count > 0 else {
    print("Nothing to add. Exit")
    exit(0)
}

print("\(newTokens.count) new tokens found.")

let deletedTokens = Set(existingTokens).subtracting(completeTokensList)
print("\(deletedTokens.count) deleted tokens found.")

for deletedToken in deletedTokens {
    if let existingIndex = completeTokensList.firstIndex(where: { $0 == deletedToken }) {
        print("Token updated from: \(deletedToken.jsonDescription)\nto: \(completeTokensList[existingIndex].jsonDescription)")
    } else {
        print("Token restored: \(deletedToken.jsonDescription)")
        completeTokensList.insert(deletedToken)
    }
}
//write new assets
let tokens = Array(completeTokensList).sorted(by: { $0.name < $1.name })
let newAssetsFileURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath).appendingPathComponent(assetsFileName)
try! tokens.jsonDescription.write(to: newAssetsFileURL, atomically: true, encoding: .utf8)
print("\(tokens.count) \(assets.rawValue) tokens saved to: \(newAssetsFileURL.absoluteString)")

////print(jsonString)

//read existing
//var total = 0
//var readTokens1 = try! JSONDecoder().decode([Token].self, from: Data(contentsOf:  existingAssetsURL.appendingPathComponent("bsc.json")))
//print(readTokens1.count)
//total += readTokens1.count
//
//readTokens1 = try! JSONDecoder().decode([Token].self, from: Data(contentsOf: existingAssetsURL.appendingPathComponent("binance.json")))
//print(readTokens1.count)
//total += readTokens1.count
//
//readTokens1 = try! JSONDecoder().decode([Token].self, from: Data(contentsOf: existingAssetsURL.appendingPathComponent("ethereum.json")))
//print(readTokens1.count)
//total += readTokens1.count
//
//print("total: \(total)")

//bsc: 66 -> 2132
//binance: 138 -> 199
//eth: 407 -> 6385
//solana: 0 -> 47
//avalanche 0 -> 149
//polygon 0 -> 51
//total: 611 -> 9037


//AVALANCHE parse https://github.com/pangolindex/tokenlists/blob/main/defi.tokenlist.json
// https://github.com/pangolindex/tokenlists/blob/main/fuji.tokenlist.json




//bsc updates
/*
 Token updated from: {
   "decimalCount" : 18,
   "symbol" : "BTCST",
   "name" : "StandardBTCHashrateToken",
   "contractAddress" : "0x78650B139471520656b9E7aA7A5e9276814a38e9"
 }
 to: {
   "decimalCount" : 17,
   "symbol" : "BTCST",
   "name" : "StandardBTCHashrateToken",
   "contractAddress" : "0x78650B139471520656b9E7aA7A5e9276814a38e9"
 }
 Token updated from: {
   "decimalCount" : 18,
   "symbol" : "XRP",
   "name" : "Binance-Peg XRP",
   "contractAddress" : "0x1D2F0da169ceB9fC7B3144628dB156f3F6c60dBE"
 }
 to: {
   "decimalCount" : 18,
   "symbol" : "XRP",
   "name" : "Binance-Peg XRP Token",
   "contractAddress" : "0x1D2F0da169ceB9fC7B3144628dB156f3F6c60dBE"
 }
 Token updated from: {
   "decimalCount" : 18,
   "symbol" : "VOYRME",
   "name" : "VOYR",
   "contractAddress" : "0x33a887Cf76383be39DC51786e8f641c9D6665D84"
 }
 to: {
   "decimalCount" : 9,
   "symbol" : "VOYRME",
   "name" : "VOYR",
   "contractAddress" : "0x33a887Cf76383be39DC51786e8f641c9D6665D84"
 }
 Token updated from: {
   "decimalCount" : 18,
   "symbol" : "BCH",
   "name" : "Binance-Peg Bitcoin Cash",
   "contractAddress" : "0x8fF795a6F4D97E7887C79beA79aba5cc76444aDf"
 }
 to: {
   "decimalCount" : 18,
   "symbol" : "BCH",
   "name" : "Binance-Peg Bitcoin Cash Token",
   "contractAddress" : "0x8fF795a6F4D97E7887C79beA79aba5cc76444aDf"
 }
 Token updated from: {
   "decimalCount" : 18,
   "symbol" : "LTC",
   "name" : "Binance-Peg Litecoin",
   "contractAddress" : "0x4338665CBB7B2485A8855A139b75D5e34AB0DB94"
 }
 to: {
   "decimalCount" : 18,
   "symbol" : "LTC",
   "name" : "Binance-Peg Litecoin Token",
   "contractAddress" : "0x4338665CBB7B2485A8855A139b75D5e34AB0DB94"
 }
 Token updated from: {
   "decimalCount" : 18,
   "symbol" : "XTZ",
   "name" : "Binance-Peg Tezos",
   "contractAddress" : "0x16939ef78684453bfDFb47825F8a5F714f12623a"
 }
 to: {
   "decimalCount" : 18,
   "symbol" : "XTZ",
   "name" : "Binance-Peg Tezos Token",
   "contractAddress" : "0x16939ef78684453bfDFb47825F8a5F714f12623a"
 }
 Token updated from: {
   "decimalCount" : 18,
   "symbol" : "BAND",
   "name" : "Binance-Peg Band Protocol",
   "contractAddress" : "0xAD6cAEb32CD2c308980a548bD0Bc5AA4306c6c18"
 }
 to: {
   "decimalCount" : 18,
   "symbol" : "BAND",
   "name" : "Binance-Peg Band Protocol Token",
   "contractAddress" : "0xAD6cAEb32CD2c308980a548bD0Bc5AA4306c6c18"
 }
 Token updated from: {
   "decimalCount" : 18,
   "symbol" : "YFII",
   "name" : "Binance-Peg YFII.finance",
   "contractAddress" : "0x7F70642d88cf1C4a3a7abb072B53B929b653edA5"
 }
 to: {
   "decimalCount" : 18,
   "symbol" : "YFII",
   "name" : "Binance-Peg YFII.finance Token",
   "contractAddress" : "0x7F70642d88cf1C4a3a7abb072B53B929b653edA5"
 }
 Token updated from: {
   "decimalCount" : 18,
   "symbol" : "USDT",
   "name" : "Binance-Peg Tether USD",
   "contractAddress" : "0x55d398326f99059fF775485246999027B3197955"
 }
 to: {
   "decimalCount" : 18,
   "symbol" : "USDT",
   "name" : "Binance-Peg BSC-USD",
   "contractAddress" : "0x55d398326f99059fF775485246999027B3197955"
 }
 Token updated from: {
   "decimalCount" : 18,
   "symbol" : "EGLD",
   "name" : "Elrond",
   "contractAddress" : "0xbF7c81FFF98BbE61B40Ed186e4AfD6DDd01337fe"
 }
 to: {
   "decimalCount" : 18,
   "symbol" : "EGLD",
   "name" : "Binance-Peg Elrond",
   "contractAddress" : "0xbF7c81FFF98BbE61B40Ed186e4AfD6DDd01337fe"
 }
 Token updated from: {
   "decimalCount" : 18,
   "symbol" : "DOT",
   "name" : "Binance-Peg Polkadot",
   "contractAddress" : "0x7083609fCE4d1d8Dc0C979AAb8c869Ea2C873402"
 }
 to: {
   "decimalCount" : 18,
   "symbol" : "DOT",
   "name" : "Binance-Peg Polkadot Token",
   "contractAddress" : "0x7083609fCE4d1d8Dc0C979AAb8c869Ea2C873402"
 }
 Token updated from: {
   "decimalCount" : 18,
   "symbol" : "ETH",
   "name" : "Ethereum Token",
   "contractAddress" : "0x2170Ed0880ac9A755fd29B2688956BD959F933F8"
 }
 to: {
   "decimalCount" : 18,
   "symbol" : "ETH",
   "name" : "Binance-Peg Ethereum",
   "contractAddress" : "0x2170Ed0880ac9A755fd29B2688956BD959F933F8"
 }
 Token updated from: {
   "decimalCount" : 18,
   "symbol" : "ALPHA",
   "name" : "Alpha Token",
   "contractAddress" : "0xa1faa113cbE53436Df28FF0aEe54275c13B40975"
 }
 to: {
   "decimalCount" : 18,
   "symbol" : "ALPHA",
   "name" : "Alpha Finance",
   "contractAddress" : "0xa1faa113cbE53436Df28FF0aEe54275c13B40975"
 }
 Token restored: {
   "decimalCount" : 18,
   "symbol" : "MATIC",
   "name" : "Matic Token",
   "contractAddress" : "0xcc42724c6683b7e57334c4e856f4c9965ed682bd"
 }
 Token updated from: {
   "decimalCount" : 18,
   "symbol" : "ATOM",
   "name" : "Binance-Peg Cosmos",
   "contractAddress" : "0x0Eb3a705fc54725037CC9e008bDede697f62F335"
 }
 to: {
   "decimalCount" : 18,
   "symbol" : "ATOM",
   "name" : "Binance-Peg Cosmos Token",
   "contractAddress" : "0x0Eb3a705fc54725037CC9e008bDede697f62F335"
 }
 Token updated from: {
   "decimalCount" : 6,
   "symbol" : "BLINK",
   "name" : "BLink Token",
   "contractAddress" : "0x63870A18B6e42b01Ef1Ad8A2302ef50B7132054F"
 }
 to: {
   "decimalCount" : 6,
   "symbol" : "BLINK",
   "name" : "BLinkToken",
   "contractAddress" : "0x63870A18B6e42b01Ef1Ad8A2302ef50B7132054F"
 }
 Token updated from: {
   "decimalCount" : 18,
   "symbol" : "BUSD",
   "name" : "BUSD",
   "contractAddress" : "0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56"
 }
 to: {
   "decimalCount" : 18,
   "symbol" : "BUSD",
   "name" : "Binance-Peg BUSD",
   "contractAddress" : "0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56"
 }
 Token updated from: {
   "decimalCount" : 18,
   "symbol" : "EOS",
   "name" : "Binance-Peg EOS",
   "contractAddress" : "0x56b6fB708fC5732DEC1Afc8D8556423A2EDcCbD6"
 }
 to: {
   "decimalCount" : 18,
   "symbol" : "EOS",
   "name" : "Binance-Peg EOS Token",
   "contractAddress" : "0x56b6fB708fC5732DEC1Afc8D8556423A2EDcCbD6"
 }
 Token updated from: {
   "decimalCount" : 18,
   "symbol" : "Cake",
   "name" : "PancakeSwap Token",
   "contractAddress" : "0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82"
 }
 to: {
   "decimalCount" : 18,
   "symbol" : "CAKE",
   "name" : "PancakeSwap Token",
   "contractAddress" : "0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82"
 }
 Token updated from: {
   "decimalCount" : 18,
   "symbol" : "ADA",
   "name" : "Binance-Peg Cardano",
   "contractAddress" : "0x3EE2200Efb3400fAbB9AacF31297cBdD1d435D47"
 }
 to: {
   "decimalCount" : 18,
   "symbol" : "ADA",
   "name" : "Binance-Peg Cardano Token",
   "contractAddress" : "0x3EE2200Efb3400fAbB9AacF31297cBdD1d435D47"
 }
 */


//binance updates
/*
 Token updated from: {
   "decimalCount" : 8,
   "symbol" : "CSM",
   "name" : "Consentium",
   "contractAddress" : "CSM-734"
 }
 to: {
   "decimalCount" : 8,
   "symbol" : "CSM",
   "name" : "“Consentium”",
   "contractAddress" : "CSM-734"
 }
 Token restored: {
   "decimalCount" : 8,
   "symbol" : "BIFI",
   "name" : "beefy.finance",
   "contractAddress" : "BIFI-290"
 }
 */



//eth updates
/*
 Token restored: {
   "decimalCount" : 6,
   "symbol" : "RC1U03",
   "name" : "RentalCoin 1.0",
   "contractAddress" : "0x7384db1aaa06364d1e6e67f5434391d3eea2a038"
 }
 Token restored: {
   "decimalCount" : 18,
   "symbol" : "BIX",
   "name" : "BIX Token",
   "contractAddress" : "0xb3104b4b9da82025e8b9f8fb28b3553ce2f67069"
 }
 Token restored: {
   "decimalCount" : 6,
   "symbol" : "CS",
   "name" : "Credits",
   "contractAddress" : "0x46b9ad944d1059450da1163511069c718f699d31"
 }
 Token restored: {
   "decimalCount" : 18,
   "symbol" : "RCN",
   "name" : "Ripio Credit",
   "contractAddress" : "0xf970b8e36e23f7fc3fd752eea86f8be8d83375a6"
 }
 Token updated from: {
   "decimalCount" : 18,
   "symbol" : "CFI",
   "name" : "Cofound.it",
   "contractAddress" : "0x12FEF5e57bF45873Cd9B62E9DBd7BFb99e32D73e"
 }
 to: {
   "decimalCount" : 18,
   "symbol" : "CFI",
   "name" : "Cofoundit",
   "contractAddress" : "0x12FEF5e57bF45873Cd9B62E9DBd7BFb99e32D73e"
 }
 Token updated from: {
   "decimalCount" : 9,
   "symbol" : "MARK",
   "name" : "Benchmark",
   "contractAddress" : "0x67c597624B17b16fb77959217360B7cD18284253"
 }
 to: {
   "decimalCount" : 9,
   "symbol" : "MARK",
   "name" : "Benchmark Protocol",
   "contractAddress" : "0x67c597624B17b16fb77959217360B7cD18284253"
 }
 Token restored: {
   "decimalCount" : 6,
   "symbol" : "WRC",
   "name" : "Worldcore",
   "contractAddress" : "0x72adadb447784dd7ab1f472467750fc485e4cb2d"
 }
 Token restored: {
   "decimalCount" : 18,
   "symbol" : "VEE",
   "name" : "BLOCKv",
   "contractAddress" : "0x340d2bde5eb28c1eed91b2f790723e3b160613b7"
 }
 Token restored: {
   "decimalCount" : 18,
   "symbol" : "EDO",
   "name" : "Eidoo",
   "contractAddress" : "0xced4e93198734ddaff8492d525bd258d49eb388e"
 }
 Token restored: {
   "decimalCount" : 8,
   "symbol" : "ENG",
   "name" : "Enigma",
   "contractAddress" : "0xf0ee6b27b759c9893ce4f094b49ad28fd15a23e4"
 }
 Token restored: {
   "decimalCount" : 8,
   "symbol" : "BTM",
   "name" : "Bytom",
   "contractAddress" : "0xcb97e65f07da24d46bcdd078ebebd7c6e6e3d750"
 }
 Token updated from: {
   "decimalCount" : 18,
   "symbol" : "REP",
   "name" : "Reputation",
   "contractAddress" : "0x1985365e9f78359a9B6AD760e32412f4a445E862"
 }
 to: {
   "decimalCount" : 18,
   "symbol" : "REP",
   "name" : "Augur",
   "contractAddress" : "0x1985365e9f78359a9B6AD760e32412f4a445E862"
 }
 Token updated from: {
   "decimalCount" : 18,
   "symbol" : "HOT",
   "name" : "HoloToken",
   "contractAddress" : "0x6c6EE5e31d828De241282B9606C8e98Ea48526E2"
 }
 to: {
   "decimalCount" : 18,
   "symbol" : "HOT",
   "name" : "Holo",
   "contractAddress" : "0x6c6EE5e31d828De241282B9606C8e98Ea48526E2"
 }
 Token updated from: {
   "decimalCount" : 18,
   "symbol" : "FCL",
   "name" : "Fractal Protocol Token",
   "contractAddress" : "0xF4d861575ecC9493420A3f5a14F85B13f0b50EB3"
 }
 to: {
   "decimalCount" : 18,
   "symbol" : "FCL",
   "name" : "Fractal",
   "contractAddress" : "0xF4d861575ecC9493420A3f5a14F85B13f0b50EB3"
 }
 Token restored: {
   "decimalCount" : 8,
   "symbol" : "VGX",
   "name" : "Voyager",
   "contractAddress" : "0x5af2be193a6abca9c8817001f45744777db30756"
 }
 Token updated from: {
   "decimalCount" : 18,
   "symbol" : "PTF",
   "name" : "PowerTrade Fuel Token",
   "contractAddress" : "0xC57d533c50bC22247d49a368880fb49a1caA39F7"
 }
 to: {
   "decimalCount" : 18,
   "symbol" : "PTF",
   "name" : "PowerTrade Fuel",
   "contractAddress" : "0xC57d533c50bC22247d49a368880fb49a1caA39F7"
 }
 Token updated from: {
   "decimalCount" : 18,
   "symbol" : "GRT",
   "name" : "Graph Token",
   "contractAddress" : "0xc944E90C64B2c07662A292be6244BDf05Cda44a7"
 }
 to: {
   "decimalCount" : 18,
   "symbol" : "GRT",
   "name" : "The Graph",
   "contractAddress" : "0xc944E90C64B2c07662A292be6244BDf05Cda44a7"
 }
 Token restored: {
   "decimalCount" : 18,
   "symbol" : "SEED",
   "name" : "Superbloom Network",
   "contractAddress" : "0x4e7bd88e3996f48e2a24d15e37ca4c02b4d134d2"
 }
 Token restored: {
   "decimalCount" : 18,
   "symbol" : "RDN",
   "name" : "Raiden Network",
   "contractAddress" : "0x255aa6df07540cb5d3d297f0d0d4d84cb52bc8e6"
 }
 Token restored: {
   "decimalCount" : 18,
   "symbol" : "AE",
   "name" : "Aeternity",
   "contractAddress" : "0x5ca9a71b1d01849c0a95490cc00559717fcf0d1d"
 }
 Token restored: {
   "decimalCount" : 18,
   "symbol" : "CRPT",
   "name" : "Crypterium",
   "contractAddress" : "0x08389495d7456e1951ddf7c3a1314a4bfb646d8b"
 }
 Token updated from: {
   "decimalCount" : 18,
   "symbol" : "ZEE",
   "name" : "ZeroSwapToken",
   "contractAddress" : "0x2eDf094dB69d6Dcd487f1B3dB9febE2eeC0dd4c5"
 }
 to: {
   "decimalCount" : 18,
   "symbol" : "ZEE",
   "name" : "ZeroSwap",
   "contractAddress" : "0x2eDf094dB69d6Dcd487f1B3dB9febE2eeC0dd4c5"
 }
 Token updated from: {
   "decimalCount" : 18,
   "symbol" : "UMX",
   "name" : "https:\/\/unimex.network\/",
   "contractAddress" : "0x10Be9a8dAe441d276a5027936c3aADEd2d82bC15"
 }
 to: {
   "decimalCount" : 18,
   "symbol" : "UMX",
   "name" : "UniMex Network",
   "contractAddress" : "0x10Be9a8dAe441d276a5027936c3aADEd2d82bC15"
 }
 Token restored: {
   "decimalCount" : 18,
   "symbol" : "MAN",
   "name" : "MATRIX AI Network",
   "contractAddress" : "0xe25bcec5d3801ce3a794079bf94adf1b8ccd802d"
 }
 Token updated from: {
   "decimalCount" : 18,
   "symbol" : "BAND",
   "name" : "BandToken",
   "contractAddress" : "0xBA11D00c5f74255f56a5E366F4F77f5A186d7f55"
 }
 to: {
   "decimalCount" : 18,
   "symbol" : "BAND",
   "name" : "Band Protocol",
   "contractAddress" : "0xBA11D00c5f74255f56a5E366F4F77f5A186d7f55"
 }
 Token updated from: {
   "decimalCount" : 18,
   "symbol" : "POOLZ",
   "name" : "$Poolz Finance",
   "contractAddress" : "0x69A95185ee2a045CDC4bCd1b1Df10710395e4e23"
 }
 to: {
   "decimalCount" : 18,
   "symbol" : "POOLZ",
   "name" : "Poolz Finance",
   "contractAddress" : "0x69A95185ee2a045CDC4bCd1b1Df10710395e4e23"
 }
 Token updated from: {
   "decimalCount" : 18,
   "symbol" : "APY",
   "name" : "APY Governance Token",
   "contractAddress" : "0x95a4492F028aa1fd432Ea71146b433E7B4446611"
 }
 to: {
   "decimalCount" : 18,
   "symbol" : "APY",
   "name" : "APY.Finance",
   "contractAddress" : "0x95a4492F028aa1fd432Ea71146b433E7B4446611"
 }
 Token updated from: {
   "decimalCount" : 8,
   "symbol" : "TIME",
   "name" : "Chronobank",
   "contractAddress" : "0x6531f133e6DeeBe7F2dcE5A0441aA7ef330B4e53"
 }
 to: {
   "decimalCount" : 8,
   "symbol" : "TIME",
   "name" : "Chronobank TIME (EOL)",
   "contractAddress" : "0x6531f133e6DeeBe7F2dcE5A0441aA7ef330B4e53"
 }
 Token restored: {
   "decimalCount" : 2,
   "symbol" : "GUSD",
   "name" : "Gemini Dollar",
   "contractAddress" : "0x056fd409e1d7a124bd7017459dfea2f387b6d5cd"
 }
 Token restored: {
   "decimalCount" : 18,
   "symbol" : "NCASH",
   "name" : "Nucleus Vision",
   "contractAddress" : "0x809826cceab68c387726af962713b64cb5cb3cca"
 }
 Token updated from: {
   "decimalCount" : 18,
   "symbol" : "Link",
   "name" : "ChainLink",
   "contractAddress" : "0x514910771AF9Ca656af840dff83E8264EcF986CA"
 }
 to: {
   "decimalCount" : 18,
   "symbol" : "LINK",
   "name" : "Chainlink",
   "contractAddress" : "0x514910771AF9Ca656af840dff83E8264EcF986CA"
 }
 Token restored: {
   "decimalCount" : 8,
   "symbol" : "QCX",
   "name" : "QuickX Protocol",
   "contractAddress" : "0xf9e5af7b42d31d51677c75bbbd37c1986ec79aee"
 }
 Token updated from: {
   "decimalCount" : 18,
   "symbol" : "SAND",
   "name" : "SAND",
   "contractAddress" : "0x3845badAde8e6dFF049820680d1F14bD3903a5d0"
 }
 to: {
   "decimalCount" : 18,
   "symbol" : "SAND",
   "name" : "The Sandbox",
   "contractAddress" : "0x3845badAde8e6dFF049820680d1F14bD3903a5d0"
 }
 Token updated from: {
   "decimalCount" : 8,
   "symbol" : "WAXE",
   "name" : "WAX Economic Token",
   "contractAddress" : "0x7a2Bc711E19ba6aff6cE8246C546E8c4B4944DFD"
 }
 to: {
   "decimalCount" : 8,
   "symbol" : "WAXE",
   "name" : "WAXE",
   "contractAddress" : "0x7a2Bc711E19ba6aff6cE8246C546E8c4B4944DFD"
 }
 Token restored: {
   "decimalCount" : 18,
   "symbol" : "PMTN",
   "name" : "Peer Mountain",
   "contractAddress" : "0xe91df2bb9bccd18c45f01843cab88768d64f2d32"
 }
 Token restored: {
   "decimalCount" : 18,
   "symbol" : "PAX",
   "name" : "Paxos Standard",
   "contractAddress" : "0x8e870d67f660d95d5be530380d0ec0bd388289e1"
 }
 Token restored: {
   "decimalCount" : 8,
   "symbol" : "IXT",
   "name" : "iXledger",
   "contractAddress" : "0xfca47962d45adfdfd1ab2d972315db4ce7ccf094"
 }
 Token restored: {
   "decimalCount" : 18,
   "symbol" : "BNB",
   "name" : "Binance Coin",
   "contractAddress" : "0xb8c77482e45f1f44de1745f52c74426c631bdd52"
 }
 Token restored: {
   "decimalCount" : 18,
   "symbol" : "RUFF",
   "name" : "RUFF",
   "contractAddress" : "0xf278c1ca969095ffddded020290cf8b5c424ace2"
 }
 Token updated from: {
   "decimalCount" : 18,
   "symbol" : "LUN",
   "name" : "Lunyr",
   "contractAddress" : "0xfa05A73FfE78ef8f1a739473e462c54bae6567D9"
 }
 to: {
   "decimalCount" : 18,
   "symbol" : "LUN",
   "name" : "Lunyr Token",
   "contractAddress" : "0xfa05A73FfE78ef8f1a739473e462c54bae6567D9"
 }
 Token updated from: {
   "decimalCount" : 18,
   "symbol" : "WPR",
   "name" : "WePower",
   "contractAddress" : "0x4CF488387F035FF08c371515562CBa712f9015d4"
 }
 to: {
   "decimalCount" : 18,
   "symbol" : "WPR",
   "name" : "WePower Token",
   "contractAddress" : "0x4CF488387F035FF08c371515562CBa712f9015d4"
 }
 Token updated from: {
   "decimalCount" : 18,
   "symbol" : "MIR",
   "name" : "Wrapped MIR Token",
   "contractAddress" : "0x09a3EcAFa817268f77BE1283176B946C4ff2E608"
 }
 to: {
   "decimalCount" : 18,
   "symbol" : "MIR",
   "name" : "Mirror Protocol",
   "contractAddress" : "0x09a3EcAFa817268f77BE1283176B946C4ff2E608"
 }
 Token updated from: {
   "decimalCount" : 18,
   "symbol" : "AAVE",
   "name" : "Aave Token",
   "contractAddress" : "0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9"
 }
 to: {
   "decimalCount" : 18,
   "symbol" : "AAVE",
   "name" : "Aave",
   "contractAddress" : "0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9"
 }
 Token updated from: {
   "decimalCount" : 18,
   "symbol" : "CREAM",
   "name" : "Cream",
   "contractAddress" : "0x2ba592F78dB6436527729929AAf6c908497cB200"
 }
 to: {
   "decimalCount" : 18,
   "symbol" : "CREAM",
   "name" : "Cream Finance",
   "contractAddress" : "0x2ba592F78dB6436527729929AAf6c908497cB200"
 }
 Token updated from: {
   "decimalCount" : 18,
   "symbol" : "K21",
   "name" : "k21.kanon.art",
   "contractAddress" : "0xB9d99C33eA2d86EC5eC6b8A4dD816EBBA64404AF"
 }
 to: {
   "decimalCount" : 18,
   "symbol" : "K21",
   "name" : "K21",
   "contractAddress" : "0xB9d99C33eA2d86EC5eC6b8A4dD816EBBA64404AF"
 }
 Token updated from: {
   "decimalCount" : 18,
   "symbol" : "SNX",
   "name" : "Synthetix Network Token",
   "contractAddress" : "0xC011a73ee8576Fb46F5E1c5751cA3B9Fe0af2a6F"
 }
 to: {
   "decimalCount" : 18,
   "symbol" : "SNX",
   "name" : "Synthetix",
   "contractAddress" : "0xC011a73ee8576Fb46F5E1c5751cA3B9Fe0af2a6F"
 }
 Token updated from: {
   "decimalCount" : 18,
   "symbol" : "sUSD",
   "name" : "Synth sUSD",
   "contractAddress" : "0x57Ab1ec28D129707052df4dF418D58a2D46d5f51"
 }
 to: {
   "decimalCount" : 18,
   "symbol" : "sUSD",
   "name" : "sUSD",
   "contractAddress" : "0x57Ab1ec28D129707052df4dF418D58a2D46d5f51"
 }
 Token updated from: {
   "decimalCount" : 18,
   "symbol" : "UFT",
   "name" : "UniLend Finance Token",
   "contractAddress" : "0x0202Be363B8a4820f3F4DE7FaF5224fF05943AB1"
 }
 to: {
   "decimalCount" : 18,
   "symbol" : "UFT",
   "name" : "UniLend",
   "contractAddress" : "0x0202Be363B8a4820f3F4DE7FaF5224fF05943AB1"
 }
 Token updated from: {
   "decimalCount" : 18,
   "symbol" : "COTI",
   "name" : "COTI Token",
   "contractAddress" : "0xDDB3422497E61e13543BeA06989C0789117555c5"
 }
 to: {
   "decimalCount" : 18,
   "symbol" : "COTI",
   "name" : "COTI",
   "contractAddress" : "0xDDB3422497E61e13543BeA06989C0789117555c5"
 }
 Token updated from: {
   "decimalCount" : 18,
   "symbol" : "PNT",
   "name" : "pNetwork Token",
   "contractAddress" : "0x89Ab32156e46F46D02ade3FEcbe5Fc4243B9AAeD"
 }
 to: {
   "decimalCount" : 18,
   "symbol" : "PNT",
   "name" : "pNetwork",
   "contractAddress" : "0x89Ab32156e46F46D02ade3FEcbe5Fc4243B9AAeD"
 }
 Token updated from: {
   "decimalCount" : 18,
   "symbol" : "TORN",
   "name" : "TornadoCash",
   "contractAddress" : "0x77777FeDdddFfC19Ff86DB637967013e6C6A116C"
 }
 to: {
   "decimalCount" : 18,
   "symbol" : "TORN",
   "name" : "Tornado Cash",
   "contractAddress" : "0x77777FeDdddFfC19Ff86DB637967013e6C6A116C"
 }
 Token restored: {
   "decimalCount" : 18,
   "symbol" : "BLANK",
   "name" : "Blank Token",
   "contractAddress" : "0xAec7e1f531Bb09115103C53ba76829910Ec48966"
 }
 Token updated from: {
   "decimalCount" : 18,
   "symbol" : "SNM",
   "name" : "SONM",
   "contractAddress" : "0x983F6d60db79ea8cA4eB9968C6aFf8cfA04B3c63"
 }
 to: {
   "decimalCount" : 18,
   "symbol" : "SNM",
   "name" : "SONM Token",
   "contractAddress" : "0x983F6d60db79ea8cA4eB9968C6aFf8cfA04B3c63"
 }
 Token restored: {
   "decimalCount" : 18,
   "symbol" : "DNT",
   "name" : "district0x",
   "contractAddress" : "0x0abdace70d3790235af448c88547603b945604ea"
 }
 Token restored: {
   "decimalCount" : 18,
   "symbol" : "ICX",
   "name" : "ICON",
   "contractAddress" : "0xb5a5f22694352c15b00323844ad545abb2b11028"
 }
 Token updated from: {
   "decimalCount" : 18,
   "symbol" : "GNO",
   "name" : "Gnosis Token",
   "contractAddress" : "0x6810e776880C02933D47DB1b9fc05908e5386b96"
 }
 to: {
   "decimalCount" : 18,
   "symbol" : "GNO",
   "name" : "Gnosis",
   "contractAddress" : "0x6810e776880C02933D47DB1b9fc05908e5386b96"
 }
 Token restored: {
   "decimalCount" : 2,
   "symbol" : "TEL",
   "name" : "Telcoin",
   "contractAddress" : "0x467bccd9d29f223bce8043b84e8c8b282827790f"
 }
 Token updated from: {
   "decimalCount" : 18,
   "symbol" : "ANT",
   "name" : "Aragon Network Token",
   "contractAddress" : "0xa117000000f279D81A1D3cc75430fAA017FA5A2e"
 }
 to: {
   "decimalCount" : 18,
   "symbol" : "ANT",
   "name" : "Aragon",
   "contractAddress" : "0xa117000000f279D81A1D3cc75430fAA017FA5A2e"
 }
 Token updated from: {
   "decimalCount" : 18,
   "symbol" : "ERN",
   "name" : "@EthernityChain $ERN Token",
   "contractAddress" : "0xBBc2AE13b23d715c30720F079fcd9B4a74093505"
 }
 to: {
   "decimalCount" : 18,
   "symbol" : "ERN",
   "name" : "Ethernity Chain",
   "contractAddress" : "0xBBc2AE13b23d715c30720F079fcd9B4a74093505"
 }
 Token restored: {
   "decimalCount" : 18,
   "symbol" : "HYDRO",
   "name" : "Hydro",
   "contractAddress" : "0xebbdf302c940c6bfd49c6b165f457fdb324649bc"
 }
 Token updated from: {
   "decimalCount" : 18,
   "symbol" : "VISR",
   "name" : "VISOR",
   "contractAddress" : "0xF938424F7210f31dF2Aee3011291b658f872e91e"
 }
 to: {
   "decimalCount" : 18,
   "symbol" : "VISR",
   "name" : "Visor.Finance",
   "contractAddress" : "0xF938424F7210f31dF2Aee3011291b658f872e91e"
 }
 Token restored: {
   "decimalCount" : 8,
   "symbol" : "CVC",
   "name" : "Civic",
   "contractAddress" : "0x41e5560054824ea6b0732e656e3ad64e20e94e45"
 }
 Token updated from: {
   "decimalCount" : 8,
   "symbol" : "WBTC",
   "name" : "Wrapped BTC",
   "contractAddress" : "0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599"
 }
 to: {
   "decimalCount" : 8,
   "symbol" : "WBTC",
   "name" : "Wrapped Bitcoin",
   "contractAddress" : "0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599"
 }
 Token restored: {
   "decimalCount" : 18,
   "symbol" : "APPC",
   "name" : "AppCoins",
   "contractAddress" : "0x1a7a8bd9106f2b8d977e08582dc7d24c723ab0db"
 }
 Token updated from: {
   "decimalCount" : 18,
   "symbol" : "NPXS",
   "name" : "Pundi X Token",
   "contractAddress" : "0xA15C7Ebe1f07CaF6bFF097D8a589fb8AC49Ae5B3"
 }
 to: {
   "decimalCount" : 18,
   "symbol" : "NPXS",
   "name" : "Pundi X (Old)",
   "contractAddress" : "0xA15C7Ebe1f07CaF6bFF097D8a589fb8AC49Ae5B3"
 }
 Token updated from: {
   "decimalCount" : 18,
   "symbol" : "PICKLE",
   "name" : "PickleToken",
   "contractAddress" : "0x429881672B9AE42b8EbA0E26cD9C73711b891Ca5"
 }
 to: {
   "decimalCount" : 18,
   "symbol" : "PICKLE",
   "name" : "Pickle Finance",
   "contractAddress" : "0x429881672B9AE42b8EbA0E26cD9C73711b891Ca5"
 }
 Token updated from: {
   "decimalCount" : 18,
   "symbol" : "wCRES",
   "name" : "Wrapped CRES",
   "contractAddress" : "0xa0afAA285Ce85974c3C881256cB7F225e3A1178a"
 }
 to: {
   "decimalCount" : 18,
   "symbol" : "wCRES",
   "name" : "Wrapped CrescoFin",
   "contractAddress" : "0xa0afAA285Ce85974c3C881256cB7F225e3A1178a"
 }
 Token updated from: {
   "decimalCount" : 8,
   "symbol" : "WAX",
   "name" : "WAX",
   "contractAddress" : "0x39Bb259F66E1C59d5ABEF88375979b4D20D98022"
 }
 to: {
   "decimalCount" : 8,
   "symbol" : "WAX",
   "name" : "Wax Token",
   "contractAddress" : "0x39Bb259F66E1C59d5ABEF88375979b4D20D98022"
 }
 Token updated from: {
   "decimalCount" : 6,
   "symbol" : "FRM",
   "name" : "Ferrum Network Token",
   "contractAddress" : "0xE5CAeF4Af8780E59Df925470b050Fb23C43CA68C"
 }
 to: {
   "decimalCount" : 6,
   "symbol" : "FRM",
   "name" : "Ferrum Network",
   "contractAddress" : "0xE5CAeF4Af8780E59Df925470b050Fb23C43CA68C"
 }
 Token updated from: {
   "decimalCount" : 18,
   "symbol" : "YFIM",
   "name" : "yfi.mobi",
   "contractAddress" : "0x2e2f3246b6c65CCc4239c9Ee556EC143a7E5DE2c"
 }
 to: {
   "decimalCount" : 18,
   "symbol" : "YFIM",
   "name" : "Yfi.mobi",
   "contractAddress" : "0x2e2f3246b6c65CCc4239c9Ee556EC143a7E5DE2c"
 }
 Token updated from: {
   "decimalCount" : 18,
   "symbol" : "KNC",
   "name" : "Kyber Network Crystal",
   "contractAddress" : "0xdd974D5C2e2928deA5F71b9825b8b646686BD200"
 }
 to: {
   "decimalCount" : 18,
   "symbol" : "KNCL",
   "name" : "Kyber Network Crystal Legacy",
   "contractAddress" : "0xdd974D5C2e2928deA5F71b9825b8b646686BD200"
 }
 Token restored: {
   "decimalCount" : 5,
   "symbol" : "GTO",
   "name" : "Gifto",
   "contractAddress" : "0xc5bbae50781be1669306b9e001eff57a2957b09d"
 }
 Token updated from: {
   "decimalCount" : 18,
   "symbol" : "LRC",
   "name" : "LoopringCoin V2",
   "contractAddress" : "0xBBbbCA6A901c926F240b89EacB641d8Aec7AEafD"
 }
 to: {
   "decimalCount" : 18,
   "symbol" : "LRC",
   "name" : "Loopring",
   "contractAddress" : "0xBBbbCA6A901c926F240b89EacB641d8Aec7AEafD"
 }
 Token updated from: {
   "decimalCount" : 18,
   "symbol" : "REN",
   "name" : "Republic Token",
   "contractAddress" : "0x408e41876cCCDC0F92210600ef50372656052a38"
 }
 to: {
   "decimalCount" : 18,
   "symbol" : "REN",
   "name" : "Ren",
   "contractAddress" : "0x408e41876cCCDC0F92210600ef50372656052a38"
 }
 Token updated from: {
   "decimalCount" : 18,
   "symbol" : "LUSD",
   "name" : "LUSD Stablecoin",
   "contractAddress" : "0x5f98805A4E8be255a32880FDeC7F6728C6568bA0"
 }
 to: {
   "decimalCount" : 18,
   "symbol" : "LUSD",
   "name" : "Liquity USD",
   "contractAddress" : "0x5f98805A4E8be255a32880FDeC7F6728C6568bA0"
 }
 Token updated from: {
   "decimalCount" : 8,
   "symbol" : "GIV",
   "name" : "GIVToken",
   "contractAddress" : "0xf6537FE0df7F0Cc0985Cf00792CC98249E73EFa0"
 }
 to: {
   "decimalCount" : 8,
   "symbol" : "GIV",
   "name" : "GIVLY Coin",
   "contractAddress" : "0xf6537FE0df7F0Cc0985Cf00792CC98249E73EFa0"
 }
 Token updated from: {
   "decimalCount" : 18,
   "symbol" : "BEPRO",
   "name" : "BetProtocolToken",
   "contractAddress" : "0xCF3C8Be2e2C42331Da80EF210e9B1b307C03d36A"
 }
 to: {
   "decimalCount" : 18,
   "symbol" : "BEPRO",
   "name" : "BEPRO Network",
   "contractAddress" : "0xCF3C8Be2e2C42331Da80EF210e9B1b307C03d36A"
 }
 Token restored: {
   "decimalCount" : 18,
   "symbol" : "RVT",
   "name" : "Rivetz",
   "contractAddress" : "0x3d1ba9be9f66b8ee101911bc36d3fb562eac2244"
 }
 Token restored: {
   "decimalCount" : 18,
   "symbol" : "EOS",
   "name" : "EOS",
   "contractAddress" : "0x86fa049857e0209aa7d9e616f7eb3b3b78ecfdb0"
 }
 Token restored: {
   "decimalCount" : 8,
   "symbol" : "UCASH",
   "name" : "UCASH",
   "contractAddress" : "0x92e52a1a235d9a103d970901066ce910aacefd37"
 }
 Token updated from: {
   "decimalCount" : 18,
   "symbol" : "UMA",
   "name" : "UMA Voting Token v1",
   "contractAddress" : "0x04Fa0d235C4abf4BcF4787aF4CF447DE572eF828"
 }
 to: {
   "decimalCount" : 18,
   "symbol" : "UMA",
   "name" : "UMA",
   "contractAddress" : "0x04Fa0d235C4abf4BcF4787aF4CF447DE572eF828"
 }
 Token restored: {
   "decimalCount" : 18,
   "symbol" : "PRL",
   "name" : "Oyster Pearl",
   "contractAddress" : "0x1844b21593262668b7248d0f57a220caaba46ab9"
 }
 Token updated from: {
   "decimalCount" : 18,
   "symbol" : "CELL",
   "name" : "Cellframe Token",
   "contractAddress" : "0x26c8AFBBFE1EBaca03C2bB082E69D0476Bffe099"
 }
 to: {
   "decimalCount" : 18,
   "symbol" : "CELL",
   "name" : "Cellframe",
   "contractAddress" : "0x26c8AFBBFE1EBaca03C2bB082E69D0476Bffe099"
 }
 Token restored: {
   "decimalCount" : 18,
   "symbol" : "CMT",
   "name" : "CyberMiles",
   "contractAddress" : "0xf85fEea2FdD81d51177F6b8F35F0e6734Ce45F5F"
 }
 Token updated from: {
   "decimalCount" : 18,
   "symbol" : "DYP",
   "name" : "DeFiYieldProtocol",
   "contractAddress" : "0x961C8c0B1aaD0c0b10a51FeF6a867E3091BCef17"
 }
 to: {
   "decimalCount" : 18,
   "symbol" : "DYP",
   "name" : "DeFi Yield Protocol",
   "contractAddress" : "0x961C8c0B1aaD0c0b10a51FeF6a867E3091BCef17"
 }
 Token restored: {
   "decimalCount" : 18,
   "symbol" : "CND",
   "name" : "Cindicator",
   "contractAddress" : "0xd4c435f5b09f855c3317c8524cb1f586e42795fa"
 }
 Token restored: {
   "decimalCount" : 18,
   "symbol" : "BUSD",
   "name" : "Binance USD",
   "contractAddress" : "0x4fabb145d64652a948d72533023f6e7a623c7c53"
 }
 Token restored: {
   "decimalCount" : 18,
   "symbol" : "XUC",
   "name" : "Exchange Union",
   "contractAddress" : "0xc324a2f6b05880503444451b8b27e6f9e63287cb"
 }
 Token updated from: {
   "decimalCount" : 9,
   "symbol" : "ADT",
   "name" : "adToken",
   "contractAddress" : "0xD0D6D6C5Fe4a677D343cC433536BB717bAe167dD"
 }
 to: {
   "decimalCount" : 9,
   "symbol" : "ADT",
   "name" : "AdToken",
   "contractAddress" : "0xD0D6D6C5Fe4a677D343cC433536BB717bAe167dD"
 }
 Token restored: {
   "decimalCount" : 8,
   "symbol" : "SENT",
   "name" : "SENTinel",
   "contractAddress" : "0xa44e5137293e855b1b7bc7e2c6f8cd796ffcb037"
 }
 Token updated from: {
   "decimalCount" : 18,
   "symbol" : "LUNA",
   "name" : "Wrapped LUNA Token",
   "contractAddress" : "0xd2877702675e6cEb975b4A1dFf9fb7BAF4C91ea9"
 }
 to: {
   "decimalCount" : 18,
   "symbol" : "LUNA",
   "name" : "Terra",
   "contractAddress" : "0xd2877702675e6cEb975b4A1dFf9fb7BAF4C91ea9"
 }
 Token restored: {
   "decimalCount" : 18,
   "symbol" : "DOV",
   "name" : "Dovu",
   "contractAddress" : "0xac3211a5025414af2866ff09c23fc18bc97e79b1"
 }
 Token updated from: {
   "decimalCount" : 18,
   "symbol" : "OGN",
   "name" : "OriginToken",
   "contractAddress" : "0x8207c1FfC5B6804F6024322CcF34F29c3541Ae26"
 }
 to: {
   "decimalCount" : 18,
   "symbol" : "OGN",
   "name" : "Origin Protocol",
   "contractAddress" : "0x8207c1FfC5B6804F6024322CcF34F29c3541Ae26"
 }
 Token updated from: {
   "decimalCount" : 18,
   "symbol" : "VSP",
   "name" : "VesperToken",
   "contractAddress" : "0x1b40183EFB4Dd766f11bDa7A7c3AD8982e998421"
 }
 to: {
   "decimalCount" : 18,
   "symbol" : "VSP",
   "name" : "Vesper",
   "contractAddress" : "0x1b40183EFB4Dd766f11bDa7A7c3AD8982e998421"
 }
 Token updated from: {
   "decimalCount" : 18,
   "symbol" : "LEAD",
   "name" : "Lead Token",
   "contractAddress" : "0x1dD80016e3d4ae146Ee2EBB484e8edD92dacC4ce"
 }
 to: {
   "decimalCount" : 18,
   "symbol" : "LEAD",
   "name" : "Lead Wallet",
   "contractAddress" : "0x1dD80016e3d4ae146Ee2EBB484e8edD92dacC4ce"
 }
 Token restored: {
   "decimalCount" : 18,
   "symbol" : "SAI",
   "name" : "Sai",
   "contractAddress" : "0x89d24a6b4ccb1b6faa2625fe562bdd9a23260359"
 }
 Token updated from: {
   "decimalCount" : 18,
   "symbol" : "ARMOR",
   "name" : "Armor",
   "contractAddress" : "0x1337DEF16F9B486fAEd0293eb623Dc8395dFE46a"
 }
 to: {
   "decimalCount" : 18,
   "symbol" : "ARMOR",
   "name" : "ARMOR",
   "contractAddress" : "0x1337DEF16F9B486fAEd0293eb623Dc8395dFE46a"
 }
 Token restored: {
   "decimalCount" : 18,
   "symbol" : "IOST",
   "name" : "IOStoken",
   "contractAddress" : "0xfa1a856cfa3409cfa145fa4e20eb270df3eb21ab"
 }
 Token restored: {
   "decimalCount" : 18,
   "symbol" : "CNN",
   "name" : "CNN Token",
   "contractAddress" : "0x8713d26637cf49e1b6b4a7ce57106aabc9325343"
 }
 Token updated from: {
   "decimalCount" : 18,
   "symbol" : "DEGO",
   "name" : "dego.finance",
   "contractAddress" : "0x88EF27e69108B2633F8E1C184CC37940A075cC02"
 }
 to: {
   "decimalCount" : 18,
   "symbol" : "DEGO",
   "name" : "Dego Finance",
   "contractAddress" : "0x88EF27e69108B2633F8E1C184CC37940A075cC02"
 }
 Token updated from: {
   "decimalCount" : 18,
   "symbol" : "DPI",
   "name" : "DefiPulse Index",
   "contractAddress" : "0x1494CA1F11D487c2bBe4543E90080AeBa4BA3C2b"
 }
 to: {
   "decimalCount" : 18,
   "symbol" : "DPI",
   "name" : "DeFi Pulse Index",
   "contractAddress" : "0x1494CA1F11D487c2bBe4543E90080AeBa4BA3C2b"
 }
 Token updated from: {
   "decimalCount" : 18,
   "symbol" : "aEth",
   "name" : "aEthereum",
   "contractAddress" : "0xE95A203B1a91a908F9B9CE46459d101078c2c3cb"
 }
 to: {
   "decimalCount" : 18,
   "symbol" : "aETHc",
   "name" : "ankrETH",
   "contractAddress" : "0xE95A203B1a91a908F9B9CE46459d101078c2c3cb"
 }
 Token updated from: {
   "decimalCount" : 18,
   "symbol" : "PMON",
   "name" : "Polkamon",
   "contractAddress" : "0x1796ae0b0fa4862485106a0de9b654eFE301D0b2"
 }
 to: {
   "decimalCount" : 18,
   "symbol" : "PMON",
   "name" : "Polychain Monsters",
   "contractAddress" : "0x1796ae0b0fa4862485106a0de9b654eFE301D0b2"
 }
 Token restored: {
   "decimalCount" : 6,
   "symbol" : "TRX",
   "name" : "TRON",
   "contractAddress" : "0xf230b790e05390fc8295f4d3f60332c93bed42e2"
 }
 Token restored: {
   "decimalCount" : 18,
   "symbol" : "AMLT",
   "name" : "AMLT by Coinfirm",
   "contractAddress" : "0xca0e7269600d353f70b14ad118a49575455c0f2f"
 }
 Token updated from: {
   "decimalCount" : 8,
   "symbol" : "LTO",
   "name" : "LTO Network Token",
   "contractAddress" : "0x3DB6Ba6ab6F95efed1a6E794caD492fAAabF294D"
 }
 to: {
   "decimalCount" : 8,
   "symbol" : "LTO",
   "name" : "LTO Network",
   "contractAddress" : "0x3DB6Ba6ab6F95efed1a6E794caD492fAAabF294D"
 }
 Token updated from: {
   "decimalCount" : 3,
   "symbol" : "GUP",
   "name" : "Matchpool",
   "contractAddress" : "0xf7B098298f7C69Fc14610bf71d5e02c60792894C"
 }
 to: {
   "decimalCount" : 3,
   "symbol" : "GUP",
   "name" : "Guppy",
   "contractAddress" : "0xf7B098298f7C69Fc14610bf71d5e02c60792894C"
 }
 Token restored: {
   "decimalCount" : 18,
   "symbol" : "STQ",
   "name" : "Storiqa",
   "contractAddress" : "0x5c3a228510d246b78a3765c20221cbf3082b44a4"
 }
 Token updated from: {
   "decimalCount" : 18,
   "symbol" : "COIN",
   "name" : "Coin Utility Token",
   "contractAddress" : "0xE61fDAF474Fac07063f2234Fb9e60C1163Cfa850"
 }
 to: {
   "decimalCount" : 18,
   "symbol" : "COIN",
   "name" : "COIN",
   "contractAddress" : "0xE61fDAF474Fac07063f2234Fb9e60C1163Cfa850"
 }
 Token updated from: {
   "decimalCount" : 18,
   "symbol" : "BBR",
   "name" : "BitberryToken",
   "contractAddress" : "0x7671904eed7f10808B664fc30BB8693FD7237abF"
 }
 to: {
   "decimalCount" : 18,
   "symbol" : "BBR",
   "name" : "Boolberry",
   "contractAddress" : "0x7671904eed7f10808B664fc30BB8693FD7237abF"
 }
 Token updated from: {
   "decimalCount" : 18,
   "symbol" : "DOKI",
   "name" : "DokiDokiFinance",
   "contractAddress" : "0x9cEB84f92A0561fa3Cc4132aB9c0b76A59787544"
 }
 to: {
   "decimalCount" : 18,
   "symbol" : "DOKI",
   "name" : "Doki Doki Finance",
   "contractAddress" : "0x9cEB84f92A0561fa3Cc4132aB9c0b76A59787544"
 }
 Token updated from: {
   "decimalCount" : 18,
   "symbol" : "LYXe",
   "name" : "LUKSO Token",
   "contractAddress" : "0xA8b919680258d369114910511cc87595aec0be6D"
 }
 to: {
   "decimalCount" : 18,
   "symbol" : "LYXe",
   "name" : "LUKSO",
   "contractAddress" : "0xA8b919680258d369114910511cc87595aec0be6D"
 }
 Token restored: {
   "decimalCount" : 0,
   "symbol" : "XJP",
   "name" : "Digital JPY",
   "contractAddress" : "0x39689fE671C01fcE173395f6BC45D4C332026666"
 }
 Token restored: {
   "decimalCount" : 8,
   "symbol" : "DENT",
   "name" : "DENT",
   "contractAddress" : "0x3597bfd533a99c9aa083587b074434e61eb0a258"
 }
 Token restored: {
   "decimalCount" : 18,
   "symbol" : "FSN",
   "name" : "Fusion",
   "contractAddress" : "0xd0352a019e9ab9d757776f532377aaebd36fd541"
 }
 Token updated from: {
   "decimalCount" : 18,
   "symbol" : "XOR",
   "name" : "Sora",
   "contractAddress" : "0x40FD72257597aA14C7231A7B1aaa29Fce868F677"
 }
 to: {
   "decimalCount" : 18,
   "symbol" : "XOR",
   "name" : "SORA",
   "contractAddress" : "0x40FD72257597aA14C7231A7B1aaa29Fce868F677"
 }
 Token updated from: {
   "decimalCount" : 18,
   "symbol" : "LEND",
   "name" : "Lend",
   "contractAddress" : "0x80fB784B7eD66730e8b1DBd9820aFD29931aab03"
 }
 to: {
   "decimalCount" : 18,
   "symbol" : "LEND",
   "name" : "Aave",
   "contractAddress" : "0x80fB784B7eD66730e8b1DBd9820aFD29931aab03"
 }
 Token updated from: {
   "decimalCount" : 16,
   "symbol" : "EXNT",
   "name" : "ExNetwork Community Token",
   "contractAddress" : "0xD6c67B93a7b248dF608a653d82a100556144c5DA"
 }
 to: {
   "decimalCount" : 16,
   "symbol" : "EXNT",
   "name" : "ExNetwork Token",
   "contractAddress" : "0xD6c67B93a7b248dF608a653d82a100556144c5DA"
 }
 Token restored: {
   "decimalCount" : 18,
   "symbol" : "LOOM",
   "name" : "Loom",
   "contractAddress" : "0xa4e8c3ec456107ea67d3075bf9e3df3a75823db0"
 }
 Token updated from: {
   "decimalCount" : 18,
   "symbol" : "WINGS",
   "name" : "Wings",
   "contractAddress" : "0x667088b212ce3d06a1b553a7221E1fD19000d9aF"
 }
 to: {
   "decimalCount" : 18,
   "symbol" : "WINGS",
   "name" : "WINGS",
   "contractAddress" : "0x667088b212ce3d06a1b553a7221E1fD19000d9aF"
 }
 Token restored: {
   "decimalCount" : 18,
   "symbol" : "AVM",
   "name" : "AVM Ecosystem",
   "contractAddress" : "0x74004a7227615fb52b82d17ffabfa376907d8a4d"
 }
 Token restored: {
   "decimalCount" : 18,
   "symbol" : "ZLA",
   "name" : "Zilla",
   "contractAddress" : "0xfd8971d5e8e1740ce2d0a84095fca4de729d0c16"
 }
 Token restored: {
   "decimalCount" : 18,
   "symbol" : "STU",
   "name" : "bitJob",
   "contractAddress" : "0x0371a82e4a9d0a4312f3ee2ac9c6958512891372"
 }
 Token restored: {
   "decimalCount" : 18,
   "symbol" : "CSP",
   "name" : "Caspian",
   "contractAddress" : "0xa6446d655a0c34bc4f05042ee88170d056cbaf45"
 }
 Token updated from: {
   "decimalCount" : 18,
   "symbol" : "INJ",
   "name" : "Injective Token",
   "contractAddress" : "0xe28b3B32B6c345A34Ff64674606124Dd5Aceca30"
 }
 to: {
   "decimalCount" : 18,
   "symbol" : "INJ",
   "name" : "Injective",
   "contractAddress" : "0xe28b3B32B6c345A34Ff64674606124Dd5Aceca30"
 }
 Token updated from: {
   "decimalCount" : 18,
   "symbol" : "XIO",
   "name" : "XIO Network",
   "contractAddress" : "0x0f7F961648aE6Db43C75663aC7E5414Eb79b5704"
 }
 to: {
   "decimalCount" : 18,
   "symbol" : "XIO",
   "name" : "Blockzero Labs",
   "contractAddress" : "0x0f7F961648aE6Db43C75663aC7E5414Eb79b5704"
 }
 Token updated from: {
   "decimalCount" : 18,
   "symbol" : "ZEFU",
   "name" : "Zenfuse Trading Platform Token",
   "contractAddress" : "0xB1e9157c2Fdcc5a856C8DA8b2d89b6C32b3c1229"
 }
 to: {
   "decimalCount" : 18,
   "symbol" : "ZEFU",
   "name" : "Zenfuse",
   "contractAddress" : "0xB1e9157c2Fdcc5a856C8DA8b2d89b6C32b3c1229"
 }
 Token restored: {
   "decimalCount" : 4,
   "symbol" : "AST",
   "name" : "Airswap",
   "contractAddress" : "0x27054b13b1b798b345b591a4d22e6562d47ea75a"
 }
 Token restored: {
   "decimalCount" : 18,
   "symbol" : "HPB",
   "name" : "HPBCoin",
   "contractAddress" : "0x38c6a68304cdefb9bec48bbfaaba5c5b47818bb2"
 }
 Token restored: {
   "decimalCount" : 18,
   "symbol" : "BRD",
   "name" : "BRD Token",
   "contractAddress" : "0x558ec3152e2eb2174905cd19aea4e34a23de9ad6"
 }
 Token updated from: {
   "decimalCount" : 18,
   "symbol" : "MKR",
   "name" : "MakerDAO",
   "contractAddress" : "0x9f8F72aA9304c8B593d555F12eF6589cC3A579A2"
 }
 to: {
   "decimalCount" : 18,
   "symbol" : "MKR",
   "name" : "Maker",
   "contractAddress" : "0x9f8F72aA9304c8B593d555F12eF6589cC3A579A2"
 }
 Token updated from: {
   "decimalCount" : 9,
   "symbol" : "HOGE",
   "name" : "hoge.finance",
   "contractAddress" : "0xfAd45E47083e4607302aa43c65fB3106F1cd7607"
 }
 to: {
   "decimalCount" : 9,
   "symbol" : "HOGE",
   "name" : "Hoge Finance",
   "contractAddress" : "0xfAd45E47083e4607302aa43c65fB3106F1cd7607"
 }
 Token restored: {
   "decimalCount" : 18,
   "symbol" : "PAID",
   "name" : "PAID Network",
   "contractAddress" : "0x8c8687fC965593DFb2F0b4EAeFD55E9D8df348df"
 }
 Token restored: {
   "decimalCount" : 0,
   "symbol" : "REV",
   "name" : "Revain",
   "contractAddress" : "0x48f775efbe4f5ece6e0df2f7b5932df56823b990"
 }
 Token restored: {
   "decimalCount" : 18,
   "symbol" : "DRGN",
   "name" : "Dragon",
   "contractAddress" : "0x419c4db4b9e25d6db2ad9691ccb832c8d9fda05e"
 }
 Token updated from: {
   "decimalCount" : 8,
   "symbol" : "AION",
   "name" : "Aion",
   "contractAddress" : "0x4CEdA7906a5Ed2179785Cd3A40A69ee8bc99C466"
 }
 to: {
   "decimalCount" : 8,
   "symbol" : "AION",
   "name" : "AION",
   "contractAddress" : "0x4CEdA7906a5Ed2179785Cd3A40A69ee8bc99C466"
 }
 Token updated from: {
   "decimalCount" : 18,
   "symbol" : "SAN",
   "name" : "SAN",
   "contractAddress" : "0x7C5A0CE9267ED19B22F8cae653F198e3E8daf098"
 }
 to: {
   "decimalCount" : 18,
   "symbol" : "SAN",
   "name" : "SANtiment network token",
   "contractAddress" : "0x7C5A0CE9267ED19B22F8cae653F198e3E8daf098"
 }
 Token updated from: {
   "decimalCount" : 18,
   "symbol" : "SKL",
   "name" : "SKALE",
   "contractAddress" : "0x00c83aeCC790e8a4453e5dD3B0B4b3680501a7A7"
 }
 to: {
   "decimalCount" : 18,
   "symbol" : "SKL",
   "name" : "SKALE Network",
   "contractAddress" : "0x00c83aeCC790e8a4453e5dD3B0B4b3680501a7A7"
 }
 Token updated from: {
   "decimalCount" : 18,
   "symbol" : "GRO",
   "name" : "Growth",
   "contractAddress" : "0x09e64c2B61a5f1690Ee6fbeD9baf5D6990F8dFd0"
 }
 to: {
   "decimalCount" : 18,
   "symbol" : "GRO",
   "name" : "Growth DeFi",
   "contractAddress" : "0x09e64c2B61a5f1690Ee6fbeD9baf5D6990F8dFd0"
 }
 Token updated from: {
   "decimalCount" : 18,
   "symbol" : "buidl",
   "name" : "dfohub",
   "contractAddress" : "0x7b123f53421b1bF8533339BFBdc7C98aA94163db"
 }
 to: {
   "decimalCount" : 18,
   "symbol" : "buidl",
   "name" : "DFOhub",
   "contractAddress" : "0x7b123f53421b1bF8533339BFBdc7C98aA94163db"
 }
 Token updated from: {
   "decimalCount" : 18,
   "symbol" : "RAZOR",
   "name" : "RAZOR",
   "contractAddress" : "0x50DE6856358Cc35f3A9a57eAAA34BD4cB707d2cd"
 }
 to: {
   "decimalCount" : 18,
   "symbol" : "RAZOR",
   "name" : "Razor Network",
   "contractAddress" : "0x50DE6856358Cc35f3A9a57eAAA34BD4cB707d2cd"
 }
 Token updated from: {
   "decimalCount" : 0,
   "symbol" : "SNGLS",
   "name" : "Singular DTV",
   "contractAddress" : "0xaeC2E87E0A235266D9C5ADc9DEb4b2E29b54D009"
 }
 to: {
   "decimalCount" : 0,
   "symbol" : "SNGLS",
   "name" : "SingularDTV",
   "contractAddress" : "0xaeC2E87E0A235266D9C5ADc9DEb4b2E29b54D009"
 }
 Token updated from: {
   "decimalCount" : 18,
   "symbol" : "ALBT",
   "name" : "AllianceBlock Token",
   "contractAddress" : "0x00a8b738E453fFd858a7edf03bcCfe20412f0Eb0"
 }
 to: {
   "decimalCount" : 18,
   "symbol" : "ALBT",
   "name" : "AllianceBlock",
   "contractAddress" : "0x00a8b738E453fFd858a7edf03bcCfe20412f0Eb0"
 }
 Token updated from: {
   "decimalCount" : 8,
   "symbol" : "SALT",
   "name" : "SALT",
   "contractAddress" : "0x4156D3342D5c385a87D264F90653733592000581"
 }
 to: {
   "decimalCount" : 8,
   "symbol" : "SALT",
   "name" : "Salt",
   "contractAddress" : "0x4156D3342D5c385a87D264F90653733592000581"
 }
 Token updated from: {
   "decimalCount" : 18,
   "symbol" : "ADX",
   "name" : "AdEx Network",
   "contractAddress" : "0xADE00C28244d5CE17D72E40330B1c318cD12B7c3"
 }
 to: {
   "decimalCount" : 18,
   "symbol" : "ADX",
   "name" : "Ambire AdEx",
   "contractAddress" : "0xADE00C28244d5CE17D72E40330B1c318cD12B7c3"
 }
 Token updated from: {
   "decimalCount" : 18,
   "symbol" : "QSP",
   "name" : "Quantstamp",
   "contractAddress" : "0x99ea4dB9EE77ACD40B119BD1dC4E33e1C070b80d"
 }
 to: {
   "decimalCount" : 18,
   "symbol" : "QSP",
   "name" : "Quantstamp Token",
   "contractAddress" : "0x99ea4dB9EE77ACD40B119BD1dC4E33e1C070b80d"
 }
 Token restored: {
   "decimalCount" : 9,
   "symbol" : "GNX",
   "name" : "Genaro Network",
   "contractAddress" : "0x6ec8a24cabdc339a06a172f8223ea557055adaa5"
 }
 Token updated from: {
   "decimalCount" : 18,
   "symbol" : "GYSR",
   "name" : "Geyser",
   "contractAddress" : "0xbEa98c05eEAe2f3bC8c3565Db7551Eb738c8CCAb"
 }
 to: {
   "decimalCount" : 18,
   "symbol" : "GYSR",
   "name" : "GYSR",
   "contractAddress" : "0xbEa98c05eEAe2f3bC8c3565Db7551Eb738c8CCAb"
 }
 Token updated from: {
   "decimalCount" : 18,
   "symbol" : "SURF",
   "name" : "SURF.Finance",
   "contractAddress" : "0xEa319e87Cf06203DAe107Dd8E5672175e3Ee976c"
 }
 to: {
   "decimalCount" : 18,
   "symbol" : "SURF",
   "name" : "SURF Finance",
   "contractAddress" : "0xEa319e87Cf06203DAe107Dd8E5672175e3Ee976c"
 }
 Token restored: {
   "decimalCount" : 18,
   "symbol" : "ABT",
   "name" : "ArcBlock",
   "contractAddress" : "0xb98d4c97425d9908e66e53a6fdf673acca0be986"
 }
 Token restored: {
   "decimalCount" : 18,
   "symbol" : "CAS",
   "name" : "Cashaa",
   "contractAddress" : "0xe8780b48bdb05f928697a5e8155f672ed91462f7"
 }
 Token updated from: {
   "decimalCount" : 18,
   "symbol" : "MARSH",
   "name" : "UnmarshalToken",
   "contractAddress" : "0x5a666c7d92E5fA7Edcb6390E4efD6d0CDd69cF37"
 }
 to: {
   "decimalCount" : 18,
   "symbol" : "MARSH",
   "name" : "UnMarshal",
   "contractAddress" : "0x5a666c7d92E5fA7Edcb6390E4efD6d0CDd69cF37"
 }
 Token updated from: {
   "decimalCount" : 18,
   "symbol" : "DAI",
   "name" : "Dai Stablecoin",
   "contractAddress" : "0x6B175474E89094C44Da98b954EedeAC495271d0F"
 }
 to: {
   "decimalCount" : 18,
   "symbol" : "DAI",
   "name" : "Dai",
   "contractAddress" : "0x6B175474E89094C44Da98b954EedeAC495271d0F"
 }
 Token updated from: {
   "decimalCount" : 18,
   "symbol" : "BEL",
   "name" : "Bella",
   "contractAddress" : "0xA91ac63D040dEB1b7A5E4d4134aD23eb0ba07e14"
 }
 to: {
   "decimalCount" : 18,
   "symbol" : "BEL",
   "name" : "Bella Protocol",
   "contractAddress" : "0xA91ac63D040dEB1b7A5E4d4134aD23eb0ba07e14"
 }
 Token restored: {
   "decimalCount" : 6,
   "symbol" : "QASH",
   "name" : "QASH",
   "contractAddress" : "0x618e75ac90b12c6049ba3b27f5d5f8651b0037f6"
 }
 Token updated from: {
   "decimalCount" : 18,
   "symbol" : "STORM",
   "name" : "Storm",
   "contractAddress" : "0xD0a4b8946Cb52f0661273bfbC6fD0E0C75Fc6433"
 }
 to: {
   "decimalCount" : 18,
   "symbol" : "STORM",
   "name" : "Storm Token",
   "contractAddress" : "0xD0a4b8946Cb52f0661273bfbC6fD0E0C75Fc6433"
 }
 Token updated from: {
   "decimalCount" : 6,
   "symbol" : "USDC",
   "name" : "USDC",
   "contractAddress" : "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48"
 }
 to: {
   "decimalCount" : 6,
   "symbol" : "USDC",
   "name" : "USD Coin",
   "contractAddress" : "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48"
 }
 Token restored: {
   "decimalCount" : 18,
   "symbol" : "ATMI",
   "name" : "Atonomi",
   "contractAddress" : "0x97aeb5066e1a590e868b511457beb6fe99d329f5"
 }
 Token restored: {
   "decimalCount" : 18,
   "symbol" : "BLZ",
   "name" : "Bluzelle",
   "contractAddress" : "0x5732046a883704404f284ce41ffadd5b007fd668"
 }
 Token restored: {
   "decimalCount" : 18,
   "symbol" : "AMB",
   "name" : "Amber",
   "contractAddress" : "0x4dc3643dbc642b72c158e7f3d2ff232df61cb6ce"
 }
 Token restored: {
   "decimalCount" : 18,
   "symbol" : "CANDY",
   "name" : "Candy",
   "contractAddress" : "0xf2eab3a2034d3f6b63734d2e08262040e3ff7b48"
 }
 Token updated from: {
   "decimalCount" : 18,
   "symbol" : "MATIC",
   "name" : "Matic Token",
   "contractAddress" : "0x7D1AfA7B718fb893dB30A3aBc0Cfc608AaCfeBB0"
 }
 to: {
   "decimalCount" : 18,
   "symbol" : "MATIC",
   "name" : "Polygon",
   "contractAddress" : "0x7D1AfA7B718fb893dB30A3aBc0Cfc608AaCfeBB0"
 }
 Token updated from: {
   "decimalCount" : 18,
   "symbol" : "YFI",
   "name" : "Yearn.Finance",
   "contractAddress" : "0x0bc529c00C6401aEF6D220BE8C6Ea1667F6Ad93e"
 }
 to: {
   "decimalCount" : 18,
   "symbol" : "YFI",
   "name" : "yearn.finance",
   "contractAddress" : "0x0bc529c00C6401aEF6D220BE8C6Ea1667F6Ad93e"
 }
 Token updated from: {
   "decimalCount" : 8,
   "symbol" : "TRU",
   "name" : "TrustToken",
   "contractAddress" : "0x4C19596f5aAfF459fA38B0f7eD92F11AE6543784"
 }
 to: {
   "decimalCount" : 8,
   "symbol" : "TRU",
   "name" : "TrueFi",
   "contractAddress" : "0x4C19596f5aAfF459fA38B0f7eD92F11AE6543784"
 }
 Token updated from: {
   "decimalCount" : 18,
   "symbol" : "KYL",
   "name" : "Kylin Network",
   "contractAddress" : "0x67B6D479c7bB412C54e03dCA8E1Bc6740ce6b99C"
 }
 to: {
   "decimalCount" : 18,
   "symbol" : "KYL",
   "name" : "Kylin",
   "contractAddress" : "0x67B6D479c7bB412C54e03dCA8E1Bc6740ce6b99C"
 }
 Token updated from: {
   "decimalCount" : 18,
   "symbol" : "WETH",
   "name" : "Wrapped Ethereum",
   "contractAddress" : "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2"
 }
 to: {
   "decimalCount" : 18,
   "symbol" : "WETH",
   "name" : "WETH",
   "contractAddress" : "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2"
 }
 Token restored: {
   "decimalCount" : 18,
   "symbol" : "NAS",
   "name" : "Nebulas",
   "contractAddress" : "0x5d65D971895Edc438f465c17DB6992698a52318D"
 }
 Token updated from: {
   "decimalCount" : 18,
   "symbol" : "UMB",
   "name" : "Umbrella",
   "contractAddress" : "0x6fC13EACE26590B80cCCAB1ba5d51890577D83B2"
 }
 to: {
   "decimalCount" : 18,
   "symbol" : "UMB",
   "name" : "Umbrella Network",
   "contractAddress" : "0x6fC13EACE26590B80cCCAB1ba5d51890577D83B2"
 }
 Token updated from: {
   "decimalCount" : 18,
   "symbol" : "PAY",
   "name" : "TenX",
   "contractAddress" : "0xB97048628DB6B661D4C2aA833e95Dbe1A905B280"
 }
 to: {
   "decimalCount" : 18,
   "symbol" : "PAY",
   "name" : "TenX Pay Token",
   "contractAddress" : "0xB97048628DB6B661D4C2aA833e95Dbe1A905B280"
 }
 Token updated from: {
   "decimalCount" : 18,
   "symbol" : "LPOOL",
   "name" : "Launchpool token",
   "contractAddress" : "0x6149C26Cd2f7b5CCdb32029aF817123F6E37Df5B"
 }
 to: {
   "decimalCount" : 18,
   "symbol" : "LPOOL",
   "name" : "Launchpool",
   "contractAddress" : "0x6149C26Cd2f7b5CCdb32029aF817123F6E37Df5B"
 }
 Token updated from: {
   "decimalCount" : 18,
   "symbol" : "10SET",
   "name" : "10Set Token",
   "contractAddress" : "0x7FF4169a6B5122b664c51c95727d87750eC07c84"
 }
 to: {
   "decimalCount" : 18,
   "symbol" : "10SET",
   "name" : "Tenset",
   "contractAddress" : "0x7FF4169a6B5122b664c51c95727d87750eC07c84"
 }
 Token restored: {
   "decimalCount" : 8,
   "symbol" : "MYST",
   "name" : "Mysterium",
   "contractAddress" : "0xa645264C5603E96c3b0B078cdab68733794B0A71"
 }
 Token restored: {
   "decimalCount" : 18,
   "symbol" : "ELF",
   "name" : "Aelf",
   "contractAddress" : "0xbf2179859fc6d5bee9bf9158632dc51678a4100e"
 }
 Token restored: {
   "decimalCount" : 18,
   "symbol" : "STK",
   "name" : "STK",
   "contractAddress" : "0xae73b38d1c9a8b274127ec30160a4927c4d71824"
 }
 Token restored: {
   "decimalCount" : 6,
   "symbol" : "POWR",
   "name" : "Power Ledger",
   "contractAddress" : "0x595832f8fc6bf59c85c527fec3740a1b7a361269"
 }
 Token updated from: {
   "decimalCount" : 18,
   "symbol" : "eRSDL",
   "name" : "UnFederalReserveToken",
   "contractAddress" : "0x5218E472cFCFE0b64A064F055B43b4cdC9EfD3A6"
 }
 to: {
   "decimalCount" : 18,
   "symbol" : "eRSDL",
   "name" : "unFederalReserve",
   "contractAddress" : "0x5218E472cFCFE0b64A064F055B43b4cdC9EfD3A6"
 }
 Token updated from: {
   "decimalCount" : 18,
   "symbol" : "SALE",
   "name" : "DxSale.Network",
   "contractAddress" : "0xF063fE1aB7a291c5d06a86e14730b00BF24cB589"
 }
 to: {
   "decimalCount" : 18,
   "symbol" : "SALE",
   "name" : "DxSale Network",
   "contractAddress" : "0xF063fE1aB7a291c5d06a86e14730b00BF24cB589"
 }
 Token updated from: {
   "decimalCount" : 18,
   "symbol" : "ID",
   "name" : "Everest ID",
   "contractAddress" : "0xEBd9D99A3982d547C5Bb4DB7E3b1F9F14b67Eb83"
 }
 to: {
   "decimalCount" : 18,
   "symbol" : "ID",
   "name" : "Everest",
   "contractAddress" : "0xEBd9D99A3982d547C5Bb4DB7E3b1F9F14b67Eb83"
 }
 Token updated from: {
   "decimalCount" : 18,
   "symbol" : "WOO",
   "name" : "Wootrade Network",
   "contractAddress" : "0x4691937a7508860F876c9c0a2a617E7d9E945D4B"
 }
 to: {
   "decimalCount" : 18,
   "symbol" : "WOO",
   "name" : "WOO Network",
   "contractAddress" : "0x4691937a7508860F876c9c0a2a617E7d9E945D4B"
 }
 Token updated from: {
   "decimalCount" : 18,
   "symbol" : "NOIA",
   "name" : "NOIA Token",
   "contractAddress" : "0xa8c8CfB141A3bB59FEA1E2ea6B79b5ECBCD7b6ca"
 }
 to: {
   "decimalCount" : 18,
   "symbol" : "NOIA",
   "name" : "Syntropy",
   "contractAddress" : "0xa8c8CfB141A3bB59FEA1E2ea6B79b5ECBCD7b6ca"
 }
 Token updated from: {
   "decimalCount" : 18,
   "symbol" : "SMARTCREDIT",
   "name" : "SMARTCREDIT Token",
   "contractAddress" : "0x72e9D9038cE484EE986FEa183f8d8Df93f9aDA13"
 }
 to: {
   "decimalCount" : 18,
   "symbol" : "SMARTCREDIT",
   "name" : "SmartCredit Token",
   "contractAddress" : "0x72e9D9038cE484EE986FEa183f8d8Df93f9aDA13"
 }
 Token updated from: {
   "decimalCount" : 18,
   "symbol" : "1ST",
   "name" : "FirstBlood",
   "contractAddress" : "0xAf30D2a7E90d7DC361c8C4585e9BB7D2F6f15bc7"
 }
 to: {
   "decimalCount" : 18,
   "symbol" : "1ST",
   "name" : "FirstBlood Token",
   "contractAddress" : "0xAf30D2a7E90d7DC361c8C4585e9BB7D2F6f15bc7"
 }
 Token restored: {
   "decimalCount" : 18,
   "symbol" : "RCC",
   "name" : "Reality Clash",
   "contractAddress" : "0x9b6443b0fb9c241a7fdac375595cea13e6b7807a"
 }
 Token restored: {
   "decimalCount" : 18,
   "symbol" : "ITC",
   "name" : "IOT Chain",
   "contractAddress" : "0x5e6b6d9abad9093fdc861ea1600eba1b355cd940"
 }
 Token updated from: {
   "decimalCount" : 18,
   "symbol" : "MANA",
   "name" : "Decentraland MANA",
   "contractAddress" : "0x0F5D2fB29fb7d3CFeE444a200298f468908cC942"
 }
 to: {
   "decimalCount" : 18,
   "symbol" : "MANA",
   "name" : "Decentraland",
   "contractAddress" : "0x0F5D2fB29fb7d3CFeE444a200298f468908cC942"
 }
 Token restored: {
   "decimalCount" : 8,
   "symbol" : "GBX",
   "name" : "Globitex",
   "contractAddress" : "0x12fcd6463e66974cf7bbc24ffc4d40d6be458283"
 }
 Token restored: {
   "decimalCount" : 18,
   "symbol" : "PAL",
   "name" : "PolicyPal Network",
   "contractAddress" : "0xfeDAE5642668f8636A11987Ff386bfd215F942EE"
 }
 Token updated from: {
   "decimalCount" : 18,
   "symbol" : "PRQ",
   "name" : "Parsiq Token",
   "contractAddress" : "0x362bc847A3a9637d3af6624EeC853618a43ed7D2"
 }
 to: {
   "decimalCount" : 18,
   "symbol" : "PRQ",
   "name" : "PARSIQ",
   "contractAddress" : "0x362bc847A3a9637d3af6624EeC853618a43ed7D2"
 }
 Token restored: {
   "decimalCount" : 18,
   "symbol" : "CCC",
   "name" : "Container Crypto Coin",
   "contractAddress" : "0x9e3359f862b6c7f5c660cfd6d1aa6909b1d9504d"
 }
 Token restored: {
   "decimalCount" : 18,
   "symbol" : "WTC",
   "name" : "Waltonchain",
   "contractAddress" : "0xb7cb1c96db6b22b0d3d9536e0108d062bd488f74"
 }
 Token restored: {
   "decimalCount" : 18,
   "symbol" : "NULS",
   "name" : "Nuls",
   "contractAddress" : "0xb91318f35bdb262e9423bc7c7c2a3a93dd93c92c"
 }
 Token restored: {
   "decimalCount" : 8,
   "symbol" : "POE",
   "name" : "Po.et",
   "contractAddress" : "0x0e0989b1f9b8a38983c2ba8053269ca62ec9b195"
 }
 Token updated from: {
   "decimalCount" : 18,
   "symbol" : "FARM",
   "name" : "FARM Reward Token",
   "contractAddress" : "0xa0246c9032bC3A600820415aE600c6388619A14D"
 }
 to: {
   "decimalCount" : 18,
   "symbol" : "FARM",
   "name" : "Harvest Finance",
   "contractAddress" : "0xa0246c9032bC3A600820415aE600c6388619A14D"
 }
 Token updated from: {
   "decimalCount" : 18,
   "symbol" : "ZRX",
   "name" : "0x Protocol Token",
   "contractAddress" : "0xE41d2489571d322189246DaFA5ebDe1F4699F498"
 }
 to: {
   "decimalCount" : 18,
   "symbol" : "ZRX",
   "name" : "0x",
   "contractAddress" : "0xE41d2489571d322189246DaFA5ebDe1F4699F498"
 }
 Token restored: {
   "decimalCount" : 0,
   "symbol" : "GD",
   "name" : "Zilla GD",
   "contractAddress" : "0xb4cebdb66b3a5183fd4764a25cad1fc109535016"
 }
 Token updated from: {
   "decimalCount" : 6,
   "symbol" : "USDT",
   "name" : "Tether USD",
   "contractAddress" : "0xdAC17F958D2ee523a2206206994597C13D831ec7"
 }
 to: {
   "decimalCount" : 6,
   "symbol" : "USDT",
   "name" : "Tether",
   "contractAddress" : "0xdAC17F958D2ee523a2206206994597C13D831ec7"
 }
 Token restored: {
   "decimalCount" : 18,
   "symbol" : "THETA",
   "name" : "Theta Token",
   "contractAddress" : "0x3883f5e181fccaf8410fa61e12b59bad963fb645"
 }
 Token updated from: {
   "decimalCount" : 18,
   "symbol" : "REEF",
   "name" : "Reef.finance",
   "contractAddress" : "0xFE3E6a25e6b192A42a44ecDDCd13796471735ACf"
 }
 to: {
   "decimalCount" : 18,
   "symbol" : "REEF",
   "name" : "Reef",
   "contractAddress" : "0xFE3E6a25e6b192A42a44ecDDCd13796471735ACf"
 }
 Token updated from: {
   "decimalCount" : 18,
   "symbol" : "BONDLY",
   "name" : "Bondly Token",
   "contractAddress" : "0xD2dDa223b2617cB616c1580db421e4cFAe6a8a85"
 }
 to: {
   "decimalCount" : 18,
   "symbol" : "BONDLY",
   "name" : "Bondly",
   "contractAddress" : "0xD2dDa223b2617cB616c1580db421e4cFAe6a8a85"
 }
 Token restored: {
   "decimalCount" : 2,
   "symbol" : "EUR.AVM",
   "name" : "EUR AVM",
   "contractAddress" : "0xF01Cd2f1c9E42c509d309aC8C5b29B6dA8E64b1a"
 }
 Token updated from: {
   "decimalCount" : 18,
   "symbol" : "POLS",
   "name" : "PolkastarterToken",
   "contractAddress" : "0x83e6f1E41cdd28eAcEB20Cb649155049Fac3D5Aa"
 }
 to: {
   "decimalCount" : 18,
   "symbol" : "POLS",
   "name" : "Polkastarter",
   "contractAddress" : "0x83e6f1E41cdd28eAcEB20Cb649155049Fac3D5Aa"
 }
 Token updated from: {
   "decimalCount" : 18,
   "symbol" : "DAO",
   "name" : "DAO Maker Token",
   "contractAddress" : "0x0f51bb10119727a7e5eA3538074fb341F56B09Ad"
 }
 to: {
   "decimalCount" : 18,
   "symbol" : "DAO",
   "name" : "DAO Maker",
   "contractAddress" : "0x0f51bb10119727a7e5eA3538074fb341F56B09Ad"
 }
 Token updated from: {
   "decimalCount" : 18,
   "symbol" : "SFI",
   "name" : "Spice",
   "contractAddress" : "0xb753428af26E81097e7fD17f40c88aaA3E04902c"
 }
 to: {
   "decimalCount" : 18,
   "symbol" : "SFI",
   "name" : "saffron.finance",
   "contractAddress" : "0xb753428af26E81097e7fD17f40c88aaA3E04902c"
 }
 Token updated from: {
   "decimalCount" : 18,
   "symbol" : "wANATHA",
   "name" : "Wrapped ANATHA",
   "contractAddress" : "0x3383c5a8969Dc413bfdDc9656Eb80A1408E4bA20"
 }
 to: {
   "decimalCount" : 18,
   "symbol" : "wANATHA",
   "name" : "Anatha",
   "contractAddress" : "0x3383c5a8969Dc413bfdDc9656Eb80A1408E4bA20"
 }
 Token updated from: {
   "decimalCount" : 0,
   "symbol" : "ATRI",
   "name" : "AtariToken",
   "contractAddress" : "0xdacD69347dE42baBfAEcD09dC88958378780FB62"
 }
 to: {
   "decimalCount" : 0,
   "symbol" : "ATRI",
   "name" : "Atari Token",
   "contractAddress" : "0xdacD69347dE42baBfAEcD09dC88958378780FB62"
 }
 Token updated from: {
   "decimalCount" : 18,
   "symbol" : "GVT",
   "name" : "Genesis Vision",
   "contractAddress" : "0x103c3A209da59d3E7C4A89307e66521e081CFDF0"
 }
 to: {
   "decimalCount" : 18,
   "symbol" : "GVT",
   "name" : "Genesis Vision Token",
   "contractAddress" : "0x103c3A209da59d3E7C4A89307e66521e081CFDF0"
 }
 Token updated from: {
   "decimalCount" : 18,
   "symbol" : "VRA",
   "name" : "VERA",
   "contractAddress" : "0xF411903cbC70a74d22900a5DE66A2dda66507255"
 }
 to: {
   "decimalCount" : 18,
   "symbol" : "VRA",
   "name" : "Verasity",
   "contractAddress" : "0xF411903cbC70a74d22900a5DE66A2dda66507255"
 }
 Token updated from: {
   "decimalCount" : 18,
   "symbol" : "OST",
   "name" : "OST",
   "contractAddress" : "0x2C4e8f2D746113d0696cE89B35F0d8bF88E0AEcA"
 }
 to: {
   "decimalCount" : 18,
   "symbol" : "ST",
   "name" : "Simple Token",
   "contractAddress" : "0x2C4e8f2D746113d0696cE89B35F0d8bF88E0AEcA"
 }
 Token updated from: {
   "decimalCount" : 18,
   "symbol" : "ROOT",
   "name" : "RootKit",
   "contractAddress" : "0xCb5f72d37685C3D5aD0bB5F982443BC8FcdF570E"
 }
 to: {
   "decimalCount" : 18,
   "symbol" : "ROOT",
   "name" : "Rootkit Finance",
   "contractAddress" : "0xCb5f72d37685C3D5aD0bB5F982443BC8FcdF570E"
 }
 Token updated from: {
   "decimalCount" : 18,
   "symbol" : "PAXG",
   "name" : "Paxos Gold",
   "contractAddress" : "0x45804880De22913dAFE09f4980848ECE6EcbAf78"
 }
 to: {
   "decimalCount" : 18,
   "symbol" : "PAXG",
   "name" : "PAX Gold",
   "contractAddress" : "0x45804880De22913dAFE09f4980848ECE6EcbAf78"
 }
 */
