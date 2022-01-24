//
//  Models.swift
//  AssetsGenerator
//
//  Created by Alexander Osokin on 14.01.2022.
//

import Foundation

struct NewToken: Codable, Hashable, Equatable {
    public let name: String
    public let symbol: String
    public let contractAddress: String
    public let decimalCount: Int
    public let customIconUrl: String?
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(contractAddress.lowercased())
    }
    
    public static func == (lhs: NewToken, rhs: NewToken) -> Bool {
        lhs.hashValue == rhs.hashValue
    }
    
    var jsonDescription: String {        
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let jsonData = try! encoder.encode(self)
        let jsonString = String(data: jsonData, encoding: .utf8)!
        return jsonString
    }
    
    init(from twToken: TWToken) {
        name = twToken.name.trimmingCharacters(in: .whitespacesAndNewlines)
        symbol = twToken.symbol.trimmingCharacters(in: .whitespacesAndNewlines)
        contractAddress = twToken.id.trimmingCharacters(in: .whitespacesAndNewlines)
        decimalCount = twToken.decimals
        customIconUrl = nil
    }
    
    init(from avToken: AVToken) {
        name = avToken.name.trimmingCharacters(in: .whitespacesAndNewlines)
        symbol = avToken.symbol.trimmingCharacters(in: .whitespacesAndNewlines)
        contractAddress = avToken.address.trimmingCharacters(in: .whitespacesAndNewlines)
        decimalCount = avToken.decimals
        customIconUrl = avToken.logoURI
    }
}

extension Collection where Self: Encodable {
    var jsonDescription: String {
        if self.isEmpty {
            return "[]"
        }
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let jsonData = try! encoder.encode(self)
        let jsonString = String(data: jsonData, encoding: .utf8)!
        return jsonString
    }
}

struct Token: Codable {
    public let name: String
    public let symbol: String
    public let contractAddress: String
    public let decimalCount: Int
    
//    init(from twToken: TWToken) {
//        name = twToken.name
//        symbol = twToken.symbol
//        contractAddress = twToken.id
//        decimalCount = twToken.decimals
//        blockchain = Blockchain.fromType(twToken.type)
//    }
}

public enum Blockchain {
    case stellar(testnet: Bool)
    case ethereum(testnet: Bool)
    case rsk
    case binance(testnet: Bool)
    case cardano(shelley: Bool)
    case bsc(testnet: Bool)
    case polygon(testnet: Bool)
    case solana
    case avalanche(testnet: Bool)
    
    static func fromType(_ typeValue: String) -> Blockchain {
        switch typeValue {
        case "POLYGON": return .polygon(testnet: false)
        case "SPL": return .solana
        case "ERC20": return .ethereum(testnet: false)
        case "BEP20": return .bsc(testnet: false)
        case "BEP2": return .binance(testnet: false)
        case "AVALANCHE": return .avalanche(testnet: false)
        default:
            fatalError("unsupported")
        }
    }
    
    static func fromAvalancheChainID(_ chainId: String) -> Blockchain {
        switch chainId {
        case "43114": return .avalanche(testnet: false)
        case "43113": return .avalanche(testnet: true)
        default:
            fatalError("unsupported")
        }
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

enum Assets: String, CaseIterable {
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
    
    var avalancheChainId: Int {
        switch self {
        case .avalanche: return 43114
        case .avalancheTestnet: return 43113
        default:
            fatalError()
        }
    }
}

extension String {
    func contains(_ symbols: [String]) -> Bool {
        for symbol in symbols {
            if self.contains(symbol) {
                return true
            }
        }
        
        return false
    }
}
