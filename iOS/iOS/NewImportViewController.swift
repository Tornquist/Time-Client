//
//  NewImportViewController.swift
//  iOS
//
//  Created by Nathan Tornquist on 12/17/19.
//  Copyright © 2019 nathantornquist. All rights reserved.
//

import UIKit
import TimeSDK

class NewImportViewController: UIViewController, UIDocumentPickerDelegate {
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var stackView: UIStackView!
    
    @IBOutlet weak var step1Container: UIView!
    @IBOutlet weak var step1Label: UILabel!
    @IBOutlet weak var step1Button: UIButton!
    @IBOutlet weak var step1ResultLabel: UILabel!
    
    @IBOutlet weak var step2Container: UIView!
    @IBOutlet weak var step2Label: UILabel!
    @IBOutlet weak var step2DelimiterTextField: UITextField!
    @IBOutlet weak var step2Button: UIButton!
    @IBOutlet weak var step2StatusIndicator: UIActivityIndicatorView!
    
    var fileURL: URL? = nil
    var importer: FileImporter? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.configureTheme()
    }
    
    func configureTheme() {
        self.navigationItem.title = NSLocalizedString("New Import", comment: "")
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelPressed(_:)))
        
        let topConstraint = NSLayoutConstraint(item: self.view!, attribute: .top, relatedBy: .equal, toItem: self.scrollView, attribute: .top, multiplier: 1, constant: 0)
        let bottomConstraint = NSLayoutConstraint(item: self.view!, attribute: .bottom, relatedBy: .equal, toItem: self.scrollView, attribute: .bottom, multiplier: 1, constant: 0)
        self.view.addConstraints([topConstraint, bottomConstraint])
        
        self.configureSteps()
    }
    
    // MARK: - Events
    
    @IBAction func cancelPressed(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func step1ButtonPressed(_ sender: Any) {
        let filePickerVC = UIDocumentPickerViewController(documentTypes: ["public.plain-text"], in: .import)
        filePickerVC.allowsMultipleSelection = false
        filePickerVC.delegate = self
        self.present(filePickerVC, animated: true, completion: nil)
    }
    
    @IBAction func step2ButtonPressed(_ sender: Any) {
        guard self.step2DelimiterTextField.text?.count == 1 else {
            let vc = UIAlertController(title: NSLocalizedString("Error", comment: ""), message: NSLocalizedString("Delimiter must be a single character", comment: ""), preferredStyle: .alert)
            vc.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil))
            self.present(vc, animated: true, completion: nil)
            return
        }
        
        let string = self.step2DelimiterTextField.text!
        let index = string.index(string.startIndex, offsetBy: 0)
        let character = string[index]
        self.completeStep2(with: character)
    }
    
    // MARK: - UIDocumentPickerDelegate
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard urls.count == 1 else {
            let vc = UIAlertController(title: NSLocalizedString("Error", comment: ""), message: NSLocalizedString("An unknown error has occurred.", comment: ""), preferredStyle: .alert)
            vc.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil))
            self.present(vc, animated: true, completion: nil)
            return
        }
            
        let url = urls[0]
        self.completeStep1(with: url)
    }
    
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        // No action
    }
    
    // MARK: - Steps
    
    func configureSteps() {
        self.step1Label.text = NSLocalizedString("1. Select a file", comment: "")
        self.step1Button.setTitle(NSLocalizedString("Browse", comment: ""), for: .normal)
        
        self.step2Label.text = NSLocalizedString("2. Set delimiter", comment: "")
        self.step2Button.setTitle("Load Data", for: .normal)
        
        self.restartSteps()
    }
    
    func restartSteps() {
        self.importer = nil
        self.step1Container.isHidden = false
        self.step1ResultLabel.text = ""
        
        self.step2Container.isHidden = true
        self.step2DelimiterTextField.text = ","
        self.step2StatusIndicator.stopAnimating()
        self.step2StatusIndicator.isHidden = true
    }
    
    func completeStep1(with url: URL) {
        self.step1ResultLabel.text = url.lastPathComponent
        self.fileURL = url
        self.step2Container.isHidden = false
    }
    
    func completeStep2(with delimiter: Character) {
        guard let url = self.fileURL else { return }
        
        self.step2StatusIndicator.startAnimating()
        self.step2StatusIndicator.isHidden = false

        let importer = FileImporter.init(fileURL: url)
        do {
            try importer.loadData()
            self.importer = importer
            print(importer.columns)
        } catch {
            let vc = UIAlertController(title: NSLocalizedString("Error", comment: ""), message: NSLocalizedString("Unable to process file.", comment: ""), preferredStyle: .alert)
            vc.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil))
            self.present(vc, animated: true, completion: nil)
            
            print(url, error)
        }
        
        self.step2StatusIndicator.isHidden = true
        self.step2StatusIndicator.stopAnimating()
    }
}
