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
    case polygonTestnet
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
    case fantom
    case fantomTestnet
    
    var isTestnet: Bool {
        switch self {
        case .solanaTestnet, .binanceTestnet, .bscTestnet, .ethereumTestnet, .avalancheTestnet, .fantomTestnet, .polygonTestnet:
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
    
    //trustwallet
    var twAssetsPath: String? {
        switch self {
        case .bsc:
            return "smartchain"
        case .avalanche:
            return "avalanchec"
        case .polygon, .solana, .binance, .ethereum, .fantom:
            return rawValue
        default:
            return nil
        }
    }
    
    //sushi
    var sushiListName: String? {
        switch self {
        case .polygon:
            return "matic"
        case .polygonTestnet:
            return "matic-testnet"
        case .bsc:
            return "bsc"
        case .bscTestnet:
            return "bsc-testnet"
        case .ethereum:
            return "mainnet"
        case .ethereumTestnet:
            return "rinkeby"
        case .avalanche:
            return "avalanche"
        case .fantom:
            return "fantom"
        case .fantomTestnet:
            return "fantom-testnet"
        default:
            return nil
        }
    }
    //trustwallet
    var type: String {
        switch self {
        case .avalanche: return "AVALANCHE"
        case .binance: return "BEP2"
        case .bsc: return "BEP20"
        case .ethereum: return "ERC20"
        case .polygon: return "POLYGON"
        case .solana: return "SPL"
        case .fantom: return "FANTOM"
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
        case .polygonTestnet: return 80001
        case .solana: return 101
        case .fantom: return 250
        case .fantomTestnet: return 4002
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
        case .fantom: return "fantom"
        default:
            fatalError()
        }
    }
    
    static var productionCases: [Asset] { Asset.allCases.filter { !$0.isTestnet } }
    
    static var testnetCases: [Asset] { Asset.allCases.filter { $0.isTestnet } }
    
    func readTokens() throws-> [TangemToken] {
        let reader = TokenReader()
        
        var tokens: [TangemToken] = []
        
        tokens.append(contentsOf: try reader.readTwAssets(asset: self))
        tokens.append(contentsOf: try reader.readSushiList(asset: self))
        tokens.append(contentsOf: try reader.readPlasmaList(asset: self))
        
        switch self {
        case .avalanche, .avalancheTestnet:
            tokens.append(contentsOf: try reader.readAvalancheLists(asset: self))
        case .solana:
            tokens.append(contentsOf: try reader.readSolanaList(asset: self))
        case .polygon, .polygonTestnet:
            tokens.append(contentsOf: try reader.readPolygonList(asset: self))
        default:
            break
        }
        
        return Array(Set(tokens))
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
