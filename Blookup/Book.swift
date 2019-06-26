//
//  Book.swift
//  Blookup
//
//  Created by Louis on 2019/6/15.
//  Copyright © 2019 Louis. All rights reserved.
//

import Foundation
import SwiftSoup
import WKZombie
import Money

class Book {
    
    enum Provider: String {
        case Amazon = "Amazon"
        case Caves = "Caves 敦煌書局"
        case KingStone = "KingStone 金石堂"
        case BooksCom = "博客來"
        case Eslite = "Eslite 誠品"
        case SrBook = "書立得"
        
        enum PageType: String {
            case NORMAL
            case INTERACTIVE
        }
        
        static let allCases = [Amazon, Caves, KingStone, BooksCom, Eslite, SrBook]
    }
    static let providerUrl = [
        Provider.Amazon: "https://www.amazon.com/dp/<ISBN10>",
        Provider.Caves: "https://www.cavesbooks.com.tw/Caves_Search/BooksSearch.aspx?fst=y&KeyWord=<ISBN13>",
        Provider.KingStone: "https://www.kingstone.com.tw/search/result.asp?c_name=<ISBN13>",
        Provider.BooksCom: "https://search.books.com.tw/search/query/key/<ISBN13>",
        Provider.Eslite: "https://mssl.eslite.com/main/searchlist/<ISBN13>",
        Provider.SrBook: "https://www.srbook.com.tw/searchall-products/?Search_Type=2&Search=1&keywords=<ISBN10>",
    ]
    static let providerPageType = [
        Provider.Amazon: Provider.PageType.NORMAL,
        Provider.Caves: Provider.PageType.INTERACTIVE,
        Provider.KingStone: Provider.PageType.NORMAL,
        Provider.BooksCom: Provider.PageType.NORMAL,
        Provider.Eslite: Provider.PageType.NORMAL,
        Provider.SrBook: Provider.PageType.NORMAL,
    ]
    var providerPageCache: [Provider:Document?]
    
    let currencyConversion: CurrencyConversion
    
    let isbn: ISBN
    let isbn10String: String
    let isbn13String: String
    
    var metadata: [String:String?]
    
    init(isbn: ISBN) {
        providerPageCache = [Provider:Document?]()
        currencyConversion = CurrencyConversion()
        
        self.isbn = isbn
        isbn10String = isbn.convert()
        isbn13String = isbn.isbnString
        
        metadata = [
            "title": nil,
            "author": nil,
            "image_url": nil,
            "isbn10": isbn10String,
            "isbn13": isbn13String
        ]
    }
    
    func getBookUrl(forProvider provider: Provider) -> String {
        return Book.providerUrl[provider]!.replacingOccurrences(
            of: "<ISBN10>", with: isbn10String
        ).replacingOccurrences(
            of: "<ISBN13>", with: isbn13String
        )
    }
    
    private func getDocument(forProvider provider: Provider, completion callback: @escaping (Document?) -> Void) {
        if let cachedPage = providerPageCache[provider] {
            callback(cachedPage)
            return
        }
        let urlString = getBookUrl(forProvider: provider)
        
        let secondCallback: (Document?) -> Void = { [weak self, provider, callback] in
            self?.providerPageCache[provider] = $0
            callback($0)
        }
        getDocument(url: urlString, pageType: Book.providerPageType[provider]!, completion: secondCallback)
    }
    
    private func getDocument(url urlString: String, pageType: Provider.PageType, completion callback: @escaping (Document?) -> Void) {
        guard let url = URL(string: urlString) else {
            print("Error: Invalid URL!")
            callback(nil)
            return
        }
        switch pageType {
        case .NORMAL:
            DispatchQueue.main.async {
                do {
                    let html = try String.init(contentsOf: url)
                    let document = try SwiftSoup.parse(html)
                    callback(document)
                } catch let error {
                    print("Error: \(error)")
                    callback(nil)
                }
            }
        case .INTERACTIVE:
            func processPage(result: HTMLPage?) {
                if let html = result?.description {
                    do {
                        let document = try SwiftSoup.parse(html)
                        callback(document)
                    } catch _ {
                        callback(nil)
                    }
                } else {
                    callback(nil)
                }
            }
            let action: Action<HTMLPage> = open(url)
            action >>> inspect() === processPage
        }
    }
    
    func fetchMetadata(usingProvider provider: Provider, completion callback: @escaping () -> Void) {
        let documentCallback: (Document?) -> Void = { [weak self, callback] in
            guard let document = $0 else {
                print("Document not found.")
                callback()
                return
            }
            guard let strongSelf = self else {
                callback()
                return
            }
            do {
                switch provider {
                case .Amazon:
                    let titles: Elements = try document.select("#product-title")
                    if let titleElement = titles.first() {
                        let title = try titleElement.text()
                        strongSelf.metadata["title"] = title
                        
                        if let linebreak = try titleElement.nextElementSibling() {
                            if let authorElement = try linebreak.nextElementSibling() {
                                let author = try authorElement.text()
                                strongSelf.metadata["author"] = author
                            }
                        }
                    }
                    let imageURLs: Elements = try document.select("a img")
                    if let imageURLElement = imageURLs.first() {
                        let imageURL = try imageURLElement.attr("src")
                        strongSelf.metadata["image_url"] = imageURL
                    }
                default:
                    print("Not implemented yet")
                }
            } catch let error {
                // an error occurred
                print("Error: \(error)")
            }
            callback()
        }
        getDocument(forProvider: provider, completion: documentCallback)
    }
    
    func getPrice(forProvider provider: Provider, currency: Currency.BaseCurrency, completion callback: @escaping (Money?) -> Void) {
        let documentCallback: (Document?) -> Void = { [callback] in
            guard let document = $0 else {
                callback(nil)
                return
            }
            do {
                switch provider {
                case .Amazon:
                    if let html = try document.body()?.outerHtml() {
                        let range = NSRange(location: 0, length: html.count)
                        let regex = try! NSRegularExpression(pattern: "(?<=<b>Price:<\\/b>&nbsp;)(.*)(?=&nbsp;)")
                        let results = regex.matches(in: html, options: [], range: range)
                        
                        if let onlyResult = results.first {
                            let priceString = String(html[Range(onlyResult.range, in: html)!])
                            guard let priceDouble = Double(priceString.dropFirst()) else {
                                callback(nil)
                                return
                            }
                            let price = Money(decimal: Decimal(priceDouble), currency: Currency.USD.shared)
                            guard let fetchedCurrency = (price.currency as? Currency.BaseCurrency) else {
                                callback(nil)
                                return
                            }
                            let secondCallback: (Money?) -> Void = {
                                [callback](price) in
                                DispatchQueue.main.async {
                                    callback(price)
                                }
                            }
                            if fetchedCurrency != currency {
                                self.currencyConversion.convert(amount: price, to: currency,
                                                                callback: secondCallback)
                            } else {
                                secondCallback(price)
                            }
                            return
                        }
                        callback(nil)
                    }
                case .Caves:
                    let prices: Elements = try document.select("strong.money i")
                    if let priceElement = prices.first() {
                        let priceString = try priceElement.text()
                        if let price = Double(priceString.dropFirst(3)) {
                            callback(Money(decimal: Decimal(price), currency: Currency.TWD.shared))
                            return
                        }
                    }
                    callback(nil)
                case .KingStone:
                    let prices: Elements = try document.select(".price > .sale_price em")
                    if let priceElement = prices.first() {
                        let priceString = try priceElement.text()
                        if let price = Double(priceString) {
                            callback(Money(decimal: Decimal(price), currency: Currency.TWD.shared))
                            return
                        }
                    }
                    callback(nil)
                case .BooksCom:
                    let prices: Elements = try document.select(".price strong b")
                    if let priceElement = prices.first() {
                        let priceString = try priceElement.text()
                        if let price = Double(priceString) {
                            callback(Money(decimal: Decimal(price), currency: Currency.TWD.shared))
                            return
                        }
                    }
                    callback(nil)
                case .Eslite:
                    let prices: Elements = try document.select(".price_sale font")
                    if let priceElement = prices.first() {
                        let priceString = try priceElement.text()
                        if let price = Double(priceString) {
                            callback(Money(decimal: Decimal(price), currency: Currency.TWD.shared))
                            return
                        }
                    }
                    callback(nil)
                case .SrBook:
                    let prices: Elements = try document.select(".prodlist-price span.font-red.font-big")
                    if let priceElement = prices.first() {
                        let priceString = try priceElement.text()
                        if let price = Double(priceString) {
                            callback(Money(decimal: Decimal(price), currency: Currency.TWD.shared))
                            return
                        }
                    }
                    callback(nil)
                }
            } catch let error {
                print("Error: \(error)")
            }
        }
        getDocument(forProvider: provider, completion: documentCallback)
    }
    
}
