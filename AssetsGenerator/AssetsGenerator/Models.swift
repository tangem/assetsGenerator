//
//  Models.swift
//  AssetsGenerator
//
//  Created by Alexander Osokin on 14.01.2022.
//

import Foundation

struct TangemToken: Codable, Hashable, Equatable {
    public let name: String
    public let symbol: String
    public let contractAddress: String
    public let decimalCount: Int
    public var customIconUrl: String?
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(contractAddress.lowercased())
    }
    
    public static func == (lhs: TangemToken, rhs: TangemToken) -> Bool {
        lhs.hashValue == rhs.hashValue
    }
    
    var jsonDescription: String {        
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .withoutEscapingSlashes]
        let jsonData = try! encoder.encode(self)
        let jsonString = String(data: jsonData, encoding: .utf8)!
        return jsonString
    }
}

extension TangemToken {
    init(from twToken: TWToken, imageUrl: String) {
        name = twToken.name.trimmingCharacters(in: .whitespacesAndNewlines)
        symbol = twToken.symbol.trimmingCharacters(in: .whitespacesAndNewlines)
        contractAddress = twToken.id.trimmingCharacters(in: .whitespacesAndNewlines)
        decimalCount = twToken.decimals
        customIconUrl = imageUrl
    }
    
    init(from token: AVToken) {
        name = token.name.trimmingCharacters(in: .whitespacesAndNewlines)
        symbol = token.symbol.trimmingCharacters(in: .whitespacesAndNewlines)
        contractAddress = token.address.trimmingCharacters(in: .whitespacesAndNewlines)
        decimalCount = token.decimals
        customIconUrl = token.logoURI
    }
    
    init(from token: GenericToken) {
        name = token.name.trimmingCharacters(in: .whitespacesAndNewlines)
        symbol = token.symbol.trimmingCharacters(in: .whitespacesAndNewlines)
        contractAddress = token.address.trimmingCharacters(in: .whitespacesAndNewlines)
        decimalCount = token.decimals
        customIconUrl = token.logoURI
    }
}

enum Errors: Error {
    case unsupported
}

struct TWToken: Codable {
    public let id: String
    public let name: String
    public let symbol: String
    public let decimals: Int
    public let type: String
}

struct AVToken: Codable {
    public let address: String
    public let chainId: Int
    public let name: String
    public let symbol: String
    public let decimals: Int
    public let logoURI: String?
}

struct TokenList: Codable {
    let tokens: [AVToken]
}

enum Asset: String, CaseIterable {
    case polygon
    case solana
    case solanaTestnet
    case binance
    case binanceTestnet
    case bsc
    case bscTestnet
    case ethereum
    case ethereumTestnet
    case avalanche
    case avalancheTestnet
    
    var isTestnet: Bool {
        switch self {
        case .solanaTestnet, .binanceTestnet, .bscTestnet, .ethereumTestnet, .avalancheTestnet:
            return true
        default:
            return false
        }
    }
    
    var fileName: String { "\(rawValue).json" }
    
    var legacyFilename: String? {
        switch self {
        case .binance: return "binanceTokens.json"
        case .binanceTestnet: return "binanceTokens_testnet.json"
        case .bsc: return "binanceSmartChainTokens.json"
        case .bscTestnet: return "binanceSmartChainTokens_testnet.json"
        case .ethereum: return "ethereumTokens.json"
        case .ethereumTestnet: return "ethereumTokens_testnet.json"
        default:
            return nil
        }
    }
    
    var fixedDecimals: Int? {
        switch self {
        case .binance:
            return 8
        default:
            return nil
        }
    }
    
    var assetsPath: String {
        switch self {
        case .bsc:
            return "smartchain"
        case .avalanche:
            return "avalanchec"
        default:
            return rawValue
        }
    }
    
    var type: String {
        switch self {
        case .avalanche: return "AVALANCHE"
        case .binance: return "BEP2"
        case .bsc: return "BEP20"
        case .ethereum: return "ERC20"
        case .polygon: return "POLYGON"
        case .solana: return "SPL"
        default:
            fatalError()
        }
    }

    var chainId: Int? {
        switch self {
        case .avalanche: return 43114
        case .avalancheTestnet: return 43113
        case .bsc: return 56
        case .ethereum: return 1
        case .polygon: return 137
        case .solana: return 101
        default:
          return nil
        }
    }
    
    var cgPlatform: String {
        switch self {
        case .avalanche: return "avalanche"
        case .binance: return "binancecoin"
        case .bsc: return "binance-smart-chain"
        case .ethereum: return "ethereum"
        case .polygon: return "polygon-pos"
        case .solana: return "solana"
        default:
            fatalError()
        }
    }
    
    static var productionCases: [Asset] { Asset.allCases.filter { !$0.isTestnet } }
    
    func readTokens() throws-> [TangemToken] {
        let reader = TokenReader()
        
        switch self {
        case .ethereum, .bsc:
            let twTokens = Set(reader.readTwAssets(asset: self))
            let plasmaTokens = Set(try reader.readPlasmaList(asset: self))
            
            let intersection = twTokens.intersection(plasmaTokens)
            for token in intersection {
                let twToken = twTokens.first(where: {$0.contractAddress == token.contractAddress})!
                let ptoken = plasmaTokens.first(where: {$0.contractAddress == token.contractAddress})!
                if twToken.name != ptoken.name || twToken.symbol != ptoken.symbol {
                    print("names: \(twToken.name), \(ptoken.name); symbols: \(twToken.symbol), \(ptoken.symbol)")
                }
            }
            
            return Array(twTokens.union(plasmaTokens))
        case .avalanche, .avalancheTestnet:
            let twTokens = reader.readTwAssets(asset: self)
            let avaxTokens = try reader.readAvalancheLists(asset: self)
            return Array(Set(twTokens + avaxTokens))
        case .solana:
            let twTokens = reader.readTwAssets(asset: self)
            let solTokens = try reader.readSolanaList(asset: self)
            return Array(Set(twTokens + solTokens))
        case .polygon:
            let polygonTokens = try reader.readPolygonList(asset: self)
            let twTokens = reader.readTwAssets(asset: self)
            let plasmaTokens = try reader.readPlasmaList(asset: self)
            
            return Array(Set(polygonTokens + twTokens + plasmaTokens))
        default:
            return reader.readTwAssets(asset: self)
        }
    }
}

//coingecko
struct CGToken: Codable, Hashable {
    let id: String
    let symbol: String
    let name: String
    var platforms: [String:String?]
    var usdPrice: Decimal?
    
    var jsonDescription: String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .withoutEscapingSlashes]
        let jsonData = try! encoder.encode(self)
        let jsonString = String(data: jsonData, encoding: .utf8)!
        return jsonString
    }
}

struct CGPrice: Codable {
    let usd: Decimal?
}

struct GenericToken: Codable {
    public let address: String
    public let chainId: Int
    public let name: String
    public let symbol: String
    public let decimals: Int
    public let logoURI: String?
}

struct GenericTokenList: Codable {
    public let tokens: [GenericToken]
}
