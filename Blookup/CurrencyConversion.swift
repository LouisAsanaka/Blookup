//
//  CurrencyConversion.swift
//  Blookup
//
//  Created by Louis on 2019/6/21.
//  Copyright © 2019 Louis. All rights reserved.
//

import Foundation
import Money

class CurrencyConversion {
    
    let apiKey: String
    let apiEndpoint = "https://free.currconv.com/api/v7/convert?q=<from_to>&compact=ultra&apiKey=<apikey>"
    
    var conversionCache: [String:Double]
    
    init() {
        if let path = Bundle.main.path(forResource: "keys", ofType: "plist") {
            let keys = NSDictionary(contentsOfFile: path)
            if let key = keys?["currencyConversionApiKey"] as? String {
                apiKey = key
            } else {
                apiKey = "NO_KEY"
            }
        } else {
            apiKey = "NO_KEY"
        }
        print(apiKey)
        conversionCache = [String:Double]()
    }
    
    func convert(from: CurrencyProtocol, to: CurrencyProtocol, amount: Double,
                 callback: @escaping (Money?) -> Void) {
        let convertCallback: (Double?) -> Void = { [callback](conversionRate) in
            if let rate = conversionRate {
                callback(Money(decimal: Decimal(amount * rate), currency: to))
            } else {
                callback(nil)
            }
        }
        getConversionRate(from: from, to: to, callback: convertCallback)
    }
    
    func convert(amount: Money, to: CurrencyProtocol,
                 callback: @escaping (Money?) -> Void) {
        convert(from: amount.currency, to: to, amount: amount.floatValue,
                callback: callback)
    }
    
    private func getConversionRate(from: CurrencyProtocol, to: CurrencyProtocol,
                                   callback: @escaping (Double?) -> Void) {
        let fromToString = "\(from.code)_\(to.code)"
        if conversionCache.keys.contains(fromToString) {
            callback(conversionCache[fromToString])
            return
        }
        let urlString = apiEndpoint.replacingOccurrences(
            of: "<from_to>", with: fromToString
            ).replacingOccurrences(
                of: "<apikey>", with: apiKey
        )
        guard let url = URL(string: urlString) else {
            print("Error: Invalid URL!")
            callback(nil)
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) {
            [callback](data, response, error) in
            guard let dataResponse = data, error == nil else {
                print(error?.localizedDescription ?? "Response Error")
                callback(nil)
                return
            }
            do {
                let jsonResponse = try JSONSerialization.jsonObject(with:
                    dataResponse, options: [])
                guard let jsonDict = jsonResponse as? [String: Double] else {
                    callback(nil)
                    return
                }
                if let rate = jsonDict[fromToString] {
                    callback(rate)
                } else {
                    callback(nil)
                }
            } catch let parsingError {
                print("Error", parsingError)
                callback(nil)
            }
        }
        task.resume()
    }
}
