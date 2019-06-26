//
//  ResultsViewController.swift
//  Blookup
//
//  Created by Louis on 2019/6/13.
//  Copyright © 2019 Louis. All rights reserved.
//

import UIKit
import SafariServices
import NVActivityIndicatorView
import Money

class ResultsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, NVActivityIndicatorViewable {
    
    @IBOutlet weak var listingTableView: UITableView!
    
    @IBOutlet weak var bookImageView: UIImageView!
    
    @IBOutlet weak var bookNameLabel: UILabel!
    @IBOutlet weak var bookAuthorLabel: UILabel!
    @IBOutlet weak var bookISBNLabel: UILabel!
    
    var isbn: ISBN!
    
    var book: Book?
    var priceListings: [PriceListing] = [] {
        didSet {
            if priceListings.count == Book.Provider.allCases.count {
                self.stopAnimating()
            }
        }
    }
    var dataLoaded = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        listingTableView.dataSource = self
        listingTableView.delegate = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if dataLoaded {
            return
        }
        startAnimating(
            message: "Loading...",
            type: NVActivityIndicatorType.lineSpinFadeLoader,
            fadeInAnimation: nil
        )
        DispatchQueue.main.async {
            [weak self] in
            if let strongSelf = self {
                strongSelf.lookup(strongSelf.isbn)
            }
        }
        dataLoaded = true
    }
    
    @IBAction func returnToHome(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    func lookup(_ isbn: ISBN) {
        print("Looking up \(isbn)...")
        if !isbn.validate() {
            showAlert(title: "Error: Invalid \(isbn.format)!", message: "NONE")
            return
        }
        bookISBNLabel.text = "ISBN: \(isbn)"
        
        book = Book(isbn: isbn)
        
        let configureLabelCallback: () -> Void = { [weak self] in
            // Configure book information labels
            self?.bookNameLabel.text = self?.book?.metadata["title"] ?? "ERROR"
            if let author = self?.book?.metadata["author"] as? String {
                self?.bookAuthorLabel.text = "Author: \(author)"
            } else {
                self?.bookAuthorLabel.text = "ERROR"
            }
            if let imageURLString = self?.book?.metadata["image_url"] as? String {
                let imageURL = URL(string: imageURLString)
                do {
                    let data = try Data(contentsOf: imageURL!)
                    self?.bookImageView.image = UIImage(data: data)
                } catch let error {
                    print("Error: \(error)")
                }
            }
        }
        book?.fetchMetadata(usingProvider: .Amazon, completion: configureLabelCallback)
        
        for provider in Book.Provider.allCases {
            let listPriceCallback: (Money?) -> Void = { [weak self] in
                guard let strongSelf = self else {
                    return
                }
                if let book = strongSelf.book {
                    let price = $0 as Money?
                    strongSelf.priceListings.append(
                        PriceListing(provider: provider, price: price,
                                     link: book.getBookUrl(forProvider: provider))
                    )
                }
                strongSelf.listingTableView.reloadData()
            }
            book?.getPrice(forProvider: provider, currency: Currency.TWD.shared,
                           completion: listPriceCallback)
        }
    }
    
    func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title,
                                      message: message,
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return priceListings.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PriceListing", for: indexPath)
        guard let priceListingCell = cell as? PriceListingTableViewCell else {
            return cell
        }
        if indexPath.row < priceListings.count {
            let priceListing = priceListings[indexPath.row]
            priceListingCell.providerLabel.text = priceListing.provider.rawValue
            if let price = priceListing.price {
                priceListingCell.priceLabel.text = "\(price)"
            } else {
                priceListingCell.priceLabel.text = "Error"
            }
            
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row < priceListings.count {
            tableView.deselectRow(at: indexPath, animated: true)
            let priceListing = priceListings[indexPath.row]
            guard let url = URL(string: priceListing.link) else {
                print("Error: Invalid URL!")
                return
            }
            let safariViewController = SFSafariViewController(url: url)
            present(safariViewController, animated: true)
        }
    }
    
}
