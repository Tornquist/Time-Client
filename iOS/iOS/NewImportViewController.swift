//
//  NewImportViewController.swift
//  iOS
//
//  Created by Nathan Tornquist on 12/17/19.
//  Copyright © 2019 nathantornquist. All rights reserved.
//

import UIKit
import TimeSDK

class NewImportViewController: UIViewController, UIDocumentPickerDelegate, UIPickerViewDelegate, UIPickerViewDataSource {
    
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
    
    @IBOutlet weak var step3Container: UIView!
    @IBOutlet weak var step3Label: UILabel!
    @IBOutlet weak var step3StatusLabel: UILabel!
    var step3CategoryColumns: [String] = []
    var step3AvailableCategoryColumns: [String] = []
    @IBOutlet weak var step3AddButton: UIButton!
    @IBOutlet weak var step3ContinueButton: UIButton!
    
    enum PickerViewMode {
        case categoryColumns
        case dateColumns
    }
    var pickerViewMode: PickerViewMode = .categoryColumns
    var pickerViewSelectedValue: String? = nil
    
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
    
    // MARK: - Shared Events
    
    @IBAction func cancelPressed(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
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
        
        self.step3Label.text = NSLocalizedString("3. Set columns for tree creation.\n*First is parent, second is child, third is grandchild, etc.", comment: "")
        self.step3AddButton.setTitle(NSLocalizedString("Add column", comment: ""), for: .normal)
        self.step3ContinueButton.setTitle(NSLocalizedString("Continue", comment: ""), for: .normal)
        self.step3ContinueButton.isHidden = true
        
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
        
        self.step3Container.isHidden = true
        self.step3StatusLabel.text = ""
        self.step3CategoryColumns = []
    }
    
    // MARK: Step 1
    
    @IBAction func step1ButtonPressed(_ sender: Any) {
        let filePickerVC = UIDocumentPickerViewController(documentTypes: ["public.plain-text"], in: .import)
        filePickerVC.allowsMultipleSelection = false
        filePickerVC.delegate = self
        self.present(filePickerVC, animated: true, completion: nil)
    }
    
    func completeStep1(with url: URL) {
        self.step1ResultLabel.text = url.lastPathComponent
        self.fileURL = url
        
        self.step1Container.isHidden = true
        self.step2Container.isHidden = false
    }
    
    // MARK: Step 2
    
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
    
    func completeStep2(with delimiter: Character) {
        guard let url = self.fileURL else { return }
        
        self.step2StatusIndicator.startAnimating()
        self.step2StatusIndicator.isHidden = false

        let importer = FileImporter.init(fileURL: url)
        do {
            try importer.loadData()
            self.importer = importer
        } catch {
            let vc = UIAlertController(title: NSLocalizedString("Error", comment: ""), message: NSLocalizedString("Unable to process file.", comment: ""), preferredStyle: .alert)
            vc.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil))
            self.present(vc, animated: true, completion: nil)
            
            print(url, error)
        }
        
        self.step2StatusIndicator.isHidden = true
        self.step2StatusIndicator.stopAnimating()
        
        self.step2Container.isHidden = true
        self.step3Container.isHidden = false
    }
    
    // MARK: Step 3
    
    func generateAvailableCategoryColumns() {
        guard let loadedColumns = self.importer?.columns else {
            self.step3AvailableCategoryColumns = []
            return
        }
        self.step3AvailableCategoryColumns = loadedColumns.filter { (column) -> Bool in
            return !self.step3CategoryColumns.contains(column)
        }
    }
    
    @IBAction func step3AddButtonPressed(_ sender: Any) {
        self.generateAvailableCategoryColumns()
        guard self.step3AvailableCategoryColumns.count > 0 else {
            let title = NSLocalizedString("No columns remain", comment: "")
            let vc = UIAlertController(title: title, message: nil, preferredStyle: .alert)
            vc.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil))
            self.present(vc, animated: true, completion: nil)
            return
        }
        
        let title = NSLocalizedString("Select column", comment: "")
        let vc = UIAlertController(title: title, message: "\n\n\n\n\n\n", preferredStyle: .alert)
        
        let pickerView = UIPickerView(frame: CGRect(x: 5, y: 20, width: 250, height: 140))
        pickerView.delegate = self
        pickerView.dataSource = self
        vc.view.addSubview(pickerView)
        
        self.pickerViewSelectedValue = self.step3AvailableCategoryColumns[0]
        self.pickerViewMode = .categoryColumns

        vc.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: nil))
        vc.addAction(UIAlertAction(title: NSLocalizedString("Confirm", comment: ""), style: .default, handler: { action in
            if self.pickerViewSelectedValue != nil {
                self.step3CategoryColumns.append(self.pickerViewSelectedValue!)
                
                self.step3StatusLabel.text = self.step3CategoryColumns.joined(separator: "\n")
                self.step3ContinueButton.isHidden = false
            }
            
            self.pickerViewSelectedValue = nil
        }))

        self.present(vc, animated: true, completion: nil)
    }
    
    @IBAction func step3ContinueButtonPressed(_ sender: Any) {
        self.importer?.categoryColumns = self.step3AvailableCategoryColumns
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
    
    // MARK: - UIPickerViewDelegate and UIPickerViewDataSource
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        switch self.pickerViewMode {
        case .categoryColumns:
            return self.step3AvailableCategoryColumns.count
        case .dateColumns:
            return 0
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        switch self.pickerViewMode {
        case .categoryColumns:
            return self.step3AvailableCategoryColumns[row]
        case .dateColumns:
            return nil
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        switch self.pickerViewMode {
        case .categoryColumns:
            if self.step3AvailableCategoryColumns.count > 0 {
                self.pickerViewSelectedValue = self.step3AvailableCategoryColumns[row]
            }
        case .dateColumns:
            break
        }
    }
}
