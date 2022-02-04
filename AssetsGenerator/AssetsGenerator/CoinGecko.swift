//
//  CoinGecko.swift
//  AssetsGenerator
//
//  Created by Alexander Osokin on 25.01.2022.
//

import Foundation

struct CoinGecko {
    func readCGList() -> [String: Set<String>] {
        //CG
        let fileURL = URL(fileURLWithPath: "/Users/alexander.osokin/repos/tangem/assetsGenerator/AssetsGenerator/AssetsGenerator/cg.json")
        let cgTokens = try! JSONDecoder().decode([CGToken].self, from: Data(contentsOf: fileURL))
        print("Read \(cgTokens.count) coinGecko tokens")
        
        var platforms: [String: Set<String>] = [:]
        
        for cgToken in cgTokens {
            for platform in cgToken.platforms {
                if let address = platform.value, !address.isEmpty {
                    platforms[platform.key, default: []].insert(address.lowercased())
                }
            }
        }

        return platforms
    }

    func loadPrices(for tokens: [TangemToken], platform: String) async throws -> [String:Decimal] {
        let pricesFileURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("prices_\(platform).txt")
        
        if let data = try? Data(contentsOf:pricesFileURL) {
            let dict =  try! PropertyListSerialization.propertyList(from: data, format: nil) as! [String:Double]
            
            let convertedDict = dict.mapValues { Decimal($0) }
            return convertedDict
        }
        
        var prices: [String:Decimal] = [:]
        var counter = 0
        for token in tokens {
            let price = try await getPrice(for: token.contractAddress.lowercased(), platform: platform)
            prices[token.contractAddress.lowercased()] = price
            print("\(token.contractAddress) : \(price)")
            counter += 1
            if counter == 50 {
                counter = 0
                try NSDictionary(dictionary: prices).write(to: pricesFileURL)
                try await Task.sleep(nanoseconds: 65_000_000_000)
            }
        }
        
        return prices
    }
    
    func load(forced: Bool = false) async throws -> [String: [CGToken]] {
        let pricesFileURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("tokens_with_prices.txt")
        
        if !forced, let data = try? Data(contentsOf:pricesFileURL) {
            let cached = try JSONDecoder().decode([CGToken].self, from: data)
            return mapList(cached)
        }
        
        var tokens = try await loadList()
        var counter = 0
        let chunked = tokens.chunked(into: 200)
        
        for (index, chunk) in chunked.enumerated() {
            print("Start loading \(index) of \(chunked.count)")
            let prices = try await getPrice(for: chunk.map { $0.id })
            
            prices.forEach { price in
                if let idx = tokens.firstIndex(where: {$0.id == price.key}) {
                    tokens[idx].usdPrice = price.value
                    print("\(price.key) : \(price.value)")
                } else {
                    print("Error! \(price)")
                }
            }
            
            counter += 1
            if counter == 49 {
                counter = 0
                print("Waiting")
                try await Task.sleep(nanoseconds: 65_000_000_000)
            }
            
            try JSONEncoder().encode(tokens).write(to: pricesFileURL)
        }
        
        return mapList(tokens)
    }
    
    private func mapList(_ cgTokens: [CGToken]) -> [String: [CGToken]] {
        var platforms: [String: [CGToken]] = [:]
        
        let supportedPlatforms = Asset.productionCases.map { $0.cgPlatform }
        for cgToken in cgTokens {
            for platform in cgToken.platforms {
                if supportedPlatforms.contains(platform.key) {
                    if let address = platform.value, !address.isEmpty {
                        platforms[platform.key, default: []].append(cgToken)
                    }
                }
            }
        }

        return platforms
    }
    
    //https://api.coingecko.com/api/v3/simple/token_price/binance-smart-chain?contract_addresses=0xe550a593d09FBC8DCD557b5C88Cea6946A8b404A&vs_currencies=usd
    private func getPrice(for address: String, platform: String) async throws -> Decimal {
        let url = URL(string: "https://api.coingecko.com/api/v3/simple/token_price/\(platform)?contract_addresses=\(address)&vs_currencies=usd")!
        let (data, _) = try await URLSession.shared.data(from: url)
        let respData = try JSONDecoder().decode([String:CGPrice?].self, from: data)
        return respData[address]??.usd ?? -1
    }
    
    //https://api.coingecko.com/api/v3/simple/price?ids=tether,wrapped-tether&vs_currencies=usd
    private func getPrice(for ids: [String]) async throws -> [String: Decimal] {
        let url = URL(string: "https://api.coingecko.com/api/v3/simple/price?ids=\(ids.joined(separator: ","))&vs_currencies=usd")!
        let (data, _) = try await URLSession.shared.data(from: url)
        let respData = try JSONDecoder().decode([String:CGPrice?].self, from: data)
        return respData.mapValues { $0?.usd ?? -1 }
    }
    
    //https://api.coingecko.com/api/v3/coins/list?include_platform=true
    private func loadList() async throws -> [CGToken] {
        let url = URL(string: "https://api.coingecko.com/api/v3/coins/list?include_platform=true")!
        let (data, _) = try await URLSession.shared.data(from: url)
        let respData = try JSONDecoder().decode([CGToken].self, from: data)
        return respData
    }
}
