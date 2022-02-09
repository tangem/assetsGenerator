//
//  TokenReader.swift
//  AssetsGenerator
//
//  Created by Alexander Osokin on 25.01.2022.
//

import Foundation

struct TokenReader {
    //https://github.com/pangolindex/tokenlists
    func readAvalancheLists(asset: Asset) throws -> [TangemToken] {
        guard asset == .avalanche || asset == .avalancheTestnet else {
            return []
        }
        
        let pathToAvaxTokensList = "/Users/alexander.osokin/repos/github/tokenlists/"
        let tokenFiles = ["defi.tokenlist.json","ab.tokenlist.json","aeb.tokenlist.json","top15.tokenlist.json","stablecoin.tokenlist.json"]
        let testnetTokenFiles = ["fuji.tokenlist.json"]

        let src = asset == .avalanche ? tokenFiles : testnetTokenFiles
        
        var mergedTokens: Set<TangemToken> = []
        
        for file in src {
            let fileURL = URL(fileURLWithPath: pathToAvaxTokensList).appendingPathComponent(file)
            let tokenList = try JSONDecoder().decode(TokenList.self, from: Data(contentsOf: fileURL))
            
            let tokens = tokenList.tokens
                .filter({ $0.chainId == asset.chainId })
                .map { TangemToken(from: $0 )}
            
            tokens.forEach { mergedTokens.insert($0) }
        }
        
        return Array(mergedTokens)
    }
    
    //https://github.com/trustwallet/assets
    func readTwAssets(asset: Asset) throws -> [TangemToken] {
        guard let twAssetsPath = asset.twAssetsPath else { return [] }
        
        //Constants
        let pathToAssets = "/Users/alexander.osokin/repos/github/assets/blockchains/\(twAssetsPath)/assets"
        let jsonFileName = "info.json"
       
        //read tw assets
        let assetsURL = URL(fileURLWithPath: pathToAssets)
        let assetsFolders = try FileManager.default.contentsOfDirectory(at: assetsURL, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])
        
        let twTokens = try assetsFolders.map { path -> TWToken in
            let jsonPath = path.appendingPathComponent(jsonFileName)
            let fileContents = try Data(contentsOf: jsonPath)
            let twToken = try JSONDecoder().decode(TWToken.self, from: fileContents)
            return twToken
        }
        
        let inconsistentTokens = twTokens.filter { $0.type != asset.type }
        if !inconsistentTokens.isEmpty {
            print("Found \(inconsistentTokens.count) inconsistent tokens:\n\(inconsistentTokens.jsonDescription)")
        }
        
        let readTokens = twTokens
            .filter({ $0.type == asset.type })
            .map { token -> TWToken in //fix tokens
                if token.id.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) == "0x28c8d01FF633eA9Cd8fc6a451D7457889E698de6" {
                    return TWToken(id: token.id,
                                   name: "Giga Watt Token",
                                   symbol: "WTT",
                                   decimals: token.decimals,
                                   type: token.type)
                }
                
                if token.id.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) == "0x28c8d01FF633eA9Cd8fc6a451D7457889E698de6" {
                    return TWToken(id: token.id,
                                   name: "Ethereum Gold",
                                   symbol: token.symbol,
                                   decimals: token.decimals,
                                   type: token.type)
                }
                
                return token
            }
            .map { twToken -> TangemToken in
                let contract = twToken.id.trimmingCharacters(in: .whitespacesAndNewlines)
                let imageUrl = "https://raw.githubusercontent.com/trustwallet/assets/master/blockchains/\(twAssetsPath)/assets/\(contract)/logo.png"
                return TangemToken(from: twToken, imageUrl: imageUrl)
            }
       return readTokens
    }
    
    //https://github.com/maticnetwork/polygon-token-list
    func readPolygonList(asset: Asset) throws -> [TangemToken] {
        guard asset == .polygon || asset == .polygonTestnet  else { return [] }
        let fileURL = URL(fileURLWithPath: "/Users/alexander.osokin/repos/github/polygon-token-list/src/tokens/\(asset.isTestnet ? "testnetTokens" : "default").json")
        let polyTokens = try JSONDecoder().decode([GenericToken].self, from: Data(contentsOf: fileURL))
        
        return polyTokens.filter({ $0.chainId == asset.chainId }).map { TangemToken(from: $0 )}
    }
    
    //https://github.com/plasmadlt/plasma-finance-token-list
    func readPlasmaList(asset: Asset) throws -> [TangemToken] {
        let fileURL = URL(fileURLWithPath: "/Users/alexander.osokin/repos/github/plasma-finance-token-list/plasma-finance-token-list.json")
        let list = try JSONDecoder().decode(GenericTokenList.self, from: Data(contentsOf: fileURL))
        
        return list.tokens.filter({ $0.chainId == asset.chainId }).map { TangemToken(from: $0 )}
    }
    
    //https://github.com/solana-labs/token-list
    func readSolanaList(asset: Asset) throws -> [TangemToken] {
        let fileURL = URL(fileURLWithPath: "/Users/alexander.osokin/repos/github/token-list/src/tokens/solana.tokenlist.json")
        let list = try JSONDecoder().decode(GenericTokenList.self, from: Data(contentsOf: fileURL))
        
        return list.tokens.filter({ $0.chainId == asset.chainId }).map { TangemToken(from: $0 )}
    }
    
    //https://github.com/sushiswap/list
    func readSushiList(asset: Asset) throws -> [TangemToken] {
        guard let listName = asset.sushiListName else { return [] }
        
        let fileURL = URL(fileURLWithPath: "/Users/alexander.osokin/repos/github/list/packages/default-token-list/tokens/\(listName).json")
        let tokens = try JSONDecoder().decode([GenericToken].self, from: Data(contentsOf: fileURL))
        
        return tokens.filter({ $0.chainId == asset.chainId }).map { TangemToken(from: $0 )}
    }
}

