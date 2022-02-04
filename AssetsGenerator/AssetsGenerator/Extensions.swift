//
//  Extensions.swift
//  AssetsGenerator
//
//  Created by Alexander Osokin on 25.01.2022.
//

import Foundation

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

extension Decimal {
    public func rounded(scale: Int = 2, roundingMode: NSDecimalNumber.RoundingMode = .plain) -> Decimal {
        var result = Decimal()
        var localCopy = self
        NSDecimalRound(&result, &localCopy, scale, roundingMode)
        return result
    }
}

extension Collection where Self: Encodable {
    var jsonDescription: String {
        if self.isEmpty {
            return "[]"
        }
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .withoutEscapingSlashes]
        let jsonData = try! encoder.encode(self)
        let jsonString = String(data: jsonData, encoding: .utf8)!
        return jsonString
    }
}

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}
