//
//  ViewController.swift
//  Blookup
//
//  Created by Louis on 2019/6/13.
//  Copyright © 2019 Louis. All rights reserved.
//

import UIKit

class HomeViewController: UIViewController {

    @IBOutlet weak var searchField: UITextField!
    
    var isbn: ISBN!
    var isbnString: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Register keyboard open & close events
        NotificationCenter.default.addObserver(self,
            selector: #selector(HomeViewController.keyboardWillShow),
            name: NSNotification.Name.UIKeyboardWillShow,
            object: nil
        )
        NotificationCenter.default.addObserver(self,
            selector: #selector(HomeViewController.keyboardWillHide),
            name: NSNotification.Name.UIKeyboardWillHide,
            object: nil
        )
    }
    
    @IBAction func searchISBN(_ sender: Any) {
        self.isbnString = searchField.text
        if (self.isbnString ?? "").isEmpty {
            showAlert(title: "Empty ISBN", message: "Scan a barcode or manually enter an ISBN-13 code.")
            return
        }
        isbn = ISBN(isbnString!)
        if !(self.isbnString?.isNumeric)! || !isbn.validate() {
            showAlert(title: "Invalid ISBN", message: "Scan a barcode or manually enter an ISBN-13 code.")
            return
        }
        self.performSegue(withIdentifier: "ShowResultSegue", sender: sender)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowResultSegue" {
            if let resultsViewController = segue.destination as? ResultsViewController {
                resultsViewController.isbn = self.isbn
            }
        }
    }
    
    @IBAction func unwindToHomeScreen(segue: UIStoryboardSegue) {
        dismiss(animated: true, completion: nil)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Close the keyboard if user taps an empty space
        self.view.endEditing(true)
    }
    
    // Move the view up when a keyboard is present
    @objc func keyboardWillShow(notification: NSNotification) {
        guard let userInfo = notification.userInfo else {
            return
        }
        guard let keyboardSize = userInfo[UIKeyboardFrameEndUserInfoKey] as? NSValue else {
            return
        }
        let keyboardFrame = keyboardSize.cgRectValue
        if self.view.frame.origin.y == 0 {
            self.view.frame.origin.y -= keyboardFrame.height
        }
    }
    
    // Move the view back down when closing a keyboard
    @objc func keyboardWillHide(notification: NSNotification) {
        guard let userInfo = notification.userInfo else {
            return
        }
        guard let keyboardSize = userInfo[UIKeyboardFrameEndUserInfoKey] as? NSValue else {
            return
        }
        let keyboardFrame = keyboardSize.cgRectValue
        if self.view.frame.origin.y != 0 {
            self.view.frame.origin.y += keyboardFrame.height
        }
    }
    
    func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title,
                                      message: message,
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
}

extension String {
    var isNumeric: Bool {
        guard self.count > 0 else { return false }
        let nums: Set<Character> = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"]
        return Set(self).isSubset(of: nums)
    }
}
