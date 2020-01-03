//
//  NewImportViewController.swift
//  iOS
//
//  Created by Nathan Tornquist on 12/17/19.
//  Copyright © 2019 nathantornquist. All rights reserved.
//

import UIKit
import TimeSDK

protocol NewImportViewControllerDelegate: class {
    func didCreateNewImportRequest()
}

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
    @IBOutlet weak var step3AddButton: UIButton!
    @IBOutlet weak var step3ContinueButton: UIButton!
    
    @IBOutlet weak var step4Container: UIView!
    @IBOutlet weak var step4Label: UILabel!
    @IBOutlet weak var step4SegmentedControl: UISegmentedControl!
    @IBOutlet weak var step4ColumnALabel: UILabel!
    @IBOutlet weak var step4ColumnAButton: UIButton!
    @IBOutlet weak var step4ColumnBLabel: UILabel!
    @IBOutlet weak var step4ColumnBButton: UIButton!
    @IBOutlet weak var step4ColumnCContainer: UIStackView!
    @IBOutlet weak var step4ColumnCLabel: UILabel!
    @IBOutlet weak var step4ColumnCButton: UIButton!
    @IBOutlet weak var step4DateContainer: UIStackView!
    @IBOutlet weak var step4DateFormatLabel: UILabel!
    @IBOutlet weak var step4DateFormatTextField: UITextField!
    @IBOutlet weak var step4TimeContainer: UIStackView!
    @IBOutlet weak var step4TimeFormatLabel: UILabel!
    @IBOutlet weak var step4TimeFormatTextField: UITextField!
    @IBOutlet weak var step4TimezoneLabel: UILabel!
    @IBOutlet weak var step4TimezoneTextField: UITextField!
    @IBOutlet weak var step4TestButton: UIButton!
    @IBOutlet weak var step4TestLabel: UILabel!
    @IBOutlet weak var step4ApproveButton: UIButton!
    
    var step4ColumnAName: String? = nil
    var step4ColumnBName: String? = nil
    var step4ColumnCName: String? = nil
    
    @IBOutlet weak var step5Container: UIView!
    @IBOutlet weak var step5TitleLabel: UILabel!
    @IBOutlet weak var step5DetailsLabel: UILabel!
    @IBOutlet weak var step5Button: UIButton!
    
    // Shared
    
    var availableColumns: [String] = []
    
    enum PickerViewMode {
        case categoryColumns
        case columnA
        case columnB
        case columnC
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
    
    func generateAvailableColumns() {
        guard let loadedColumns = self.importer?.columns else {
            self.availableColumns = []
            return
        }
        self.availableColumns = loadedColumns.filter { (column) -> Bool in
            let notInTree = !self.step3CategoryColumns.contains(column)
            let notInTime = column != self.step4ColumnAName &&
                column != self.step4ColumnBName &&
                column != self.step4ColumnCName
            return notInTree && notInTime
        }
    }
    
    @IBAction func showColumnPicker(_ sender: UIButton) {
        self.generateAvailableColumns()
        
        guard self.availableColumns.count > 0 else {
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
        
        self.pickerViewSelectedValue = self.availableColumns[0]
        if sender == self.step3AddButton {
            self.pickerViewMode = .categoryColumns
        } else if (sender == self.step4ColumnAButton) {
            self.pickerViewMode = .columnA
        } else if (sender == self.step4ColumnBButton) {
            self.pickerViewMode = .columnB
        } else if (sender == self.step4ColumnCButton) {
            self.pickerViewMode = .columnC
        } else {
            return // Should never occur unless sender names are mismatched
        }

        vc.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: nil))
        vc.addAction(UIAlertAction(title: NSLocalizedString("Confirm", comment: ""), style: .default, handler: { action in
            if self.pickerViewSelectedValue != nil {
                if self.pickerViewMode == .categoryColumns {
                    self.step3ColumnSelected()
                } else {
                    self.step4ColumnSelected()
                }
            }
            
            self.pickerViewSelectedValue = nil
        }))

        self.present(vc, animated: true, completion: nil)
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
        self.step3ContinueButton.isEnabled = false
        
        self.step4Label.text = NSLocalizedString("4. Specify date formatting rules", comment: "")
        self.configureStep4()
        
        self.step5TitleLabel.text = NSLocalizedString("5. Review details", comment: "")
        self.step5Button.setTitle(NSLocalizedString("Import", comment: ""), for: .normal)
        
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
        
        self.step4Container.isHidden = true
        
        self.step5Container.isHidden = true
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
    
    func step3ColumnSelected() {
        self.step3CategoryColumns.append(self.pickerViewSelectedValue!)
        
        self.step3StatusLabel.text = self.step3CategoryColumns.joined(separator: "\n")
        self.step3ContinueButton.isEnabled = true
    }

    @IBAction func step3ContinueButtonPressed(_ sender: Any) {
        self.importer?.categoryColumns = self.step3CategoryColumns
        do {
            // TODO: Show progress
            try self.importer?.buildCategoryTree()
            // TODO: End progress
            self.step3Container.isHidden = true
            self.step4Container.isHidden = false
        } catch {
            // TODO: Show error
        }
    }
    
    // MARK: Step 4
    
    func configureStep4() {
        self.step4SegmentedControl.removeAllSegments()
        self.step4SegmentedControl.insertSegment(withTitle: NSLocalizedString("Date/Time", comment: ""), at: 0, animated: false)
        self.step4SegmentedControl.insertSegment(withTitle: NSLocalizedString("Unix", comment: ""), at: 1, animated: false)
        self.step4SegmentedControl.selectedSegmentIndex = 0
        
        self.step4TestButton.setTitle(NSLocalizedString("Test Formatting", comment: ""), for: .normal)
            
        self.step4ApproveButton.setTitle(NSLocalizedString("Continue", comment: ""), for: .normal)
        
        self.updateStep4Fields()
    }
    
    func updateStep4Fields() {
        // Reset. Only called 1st time, and on segment change
        self.step4ColumnAName = nil
        self.step4ColumnBName = nil
        self.step4ColumnCName = nil
        self.generateAvailableColumns()
        
        self.step4TestLabel.text = NSLocalizedString("<Format Test Output>", comment: "")
        self.step4TestButton.isEnabled = false
        self.step4ApproveButton.isEnabled = false
        
        if self.step4SegmentedControl.selectedSegmentIndex == 0 {
            self.step4ColumnALabel.text = NSLocalizedString("Date Column", comment: "")
            self.step4ColumnAButton.setTitle(NSLocalizedString("Select Column", comment: ""), for: .normal)
            self.step4ColumnAButton.isEnabled = true
            
            self.step4ColumnBLabel.text = NSLocalizedString("Start Time Column", comment: "")
            self.step4ColumnBButton.setTitle(NSLocalizedString("Select Column", comment: ""), for: .normal)
            self.step4ColumnBButton.isEnabled = true
            
            self.step4ColumnCContainer.isHidden = false
            self.step4ColumnCLabel.text = NSLocalizedString("End Time Column", comment: "")
            self.step4ColumnCButton.setTitle(NSLocalizedString("Select Column", comment: ""), for: .normal)
            self.step4ColumnCButton.isEnabled = true
            
            self.step4DateContainer.isHidden = false
            self.step4DateFormatLabel.text = NSLocalizedString("Date Format", comment: "")
            self.step4DateFormatTextField.text = "M/d/yy"
            
            self.step4TimeContainer.isHidden = false
            self.step4TimeFormatLabel.text = NSLocalizedString("Time Format", comment: "")
            self.step4TimeFormatTextField.text = "h:mm a"
        } else {
            self.step4ColumnALabel.text = NSLocalizedString("Start Timestamp", comment: "")
            self.step4ColumnAButton.setTitle(NSLocalizedString("Select Column", comment: ""), for: .normal)
            self.step4ColumnAButton.isEnabled = true
            
            self.step4ColumnBLabel.text = NSLocalizedString("End Timestamp", comment: "")
            self.step4ColumnBButton.setTitle(NSLocalizedString("Select Column", comment: ""), for: .normal)
            self.step4ColumnBButton.isEnabled = true
            
            self.step4ColumnCContainer.isHidden = true
            self.step4DateContainer.isHidden = true
            self.step4TimeContainer.isHidden = true
        }
        
        self.step4TimezoneLabel.text = NSLocalizedString("Timezone", comment: "")
        self.step4TimezoneTextField.text = TimeZone.current.abbreviation() ?? "CST"
    }
    
    @IBAction func step4DidToggleSegmentedControl(_ sender: Any) {
        self.updateStep4Fields()
    }
    
    func step4ColumnSelected() {
        guard self.pickerViewSelectedValue != nil else { return }
        
        if self.pickerViewMode == .columnA {
            self.step4ColumnAName = self.pickerViewSelectedValue
            self.step4ColumnAButton.setTitle(self.pickerViewSelectedValue!, for: .normal)
            self.step4ColumnAButton.isEnabled = false
        } else if self.pickerViewMode == .columnB {
            self.step4ColumnBName = self.pickerViewSelectedValue
            self.step4ColumnBButton.setTitle(self.pickerViewSelectedValue!, for: .normal)
            self.step4ColumnBButton.isEnabled = false
        } else if self.pickerViewMode == .columnC {
            self.step4ColumnCName = self.pickerViewSelectedValue
            self.step4ColumnCButton.setTitle(self.pickerViewSelectedValue!, for: .normal)
            self.step4ColumnCButton.isEnabled = false
        }
        
        let aBSet = self.step4ColumnAName != nil && self.step4ColumnBName != nil
        let cSet = self.step4ColumnCName != nil
        let allSet = self.step4SegmentedControl.selectedSegmentIndex == 0 ? (aBSet && cSet) : aBSet
        
        self.step4TestButton.isEnabled = allSet
    }
    
    @IBAction func step4TestFormatPressed(_ sender: Any) {
        if self.step4SegmentedControl.selectedSegmentIndex == 0 {
            guard
                let dateColumn = self.step4ColumnAName,
                let startTimeColumn = self.step4ColumnBName,
                let endTimeColumn = self.step4ColumnCName,
                let dateFormat = self.step4DateFormatTextField.text,
                let timeFormat = self.step4TimeFormatTextField.text,
                let timezone = self.step4TimezoneTextField.text else {
                    // Show error
                    return
            }
            
            do {
                let result = try self.importer?.setDateTimeParseRules(
                    dateColumn: dateColumn,
                    startTimeColumn: startTimeColumn,
                    endTimeColumn: endTimeColumn,
                    dateFormat: dateFormat,
                    timeFormat: timeFormat,
                    timezoneAbbreviation: timezone,
                    testFormat: "MMM d, y @ h:mm a zzz"
                )
                let resultString = "First row raw input: \(result?.startRaw ?? "??")\nFirst row start parsed: \(result?.startParsed ?? "??")"
                self.step4TestLabel.text = resultString
                self.step4ApproveButton.isEnabled = true
            } catch {
                // Show error
                self.step4TestLabel.text = NSLocalizedString("Unable to parse", comment: "")
                self.step4ApproveButton.isEnabled = false
            }
        } else {
            guard
                let startUnix = self.step4ColumnAName,
                let endUnix = self.step4ColumnBName,
                let timezone = self.step4TimezoneTextField.text else {
                    // Show error
                    return
            }
            
            do {
                let result = try self.importer?.setDateTimeParseRules(
                    startUnixColumn: startUnix,
                    endUnixColumn: endUnix,
                    timezoneAbbreviation: timezone,
                    testFormat: "MMM d, y @ h:mm a zzz"
                )
                let resultString = "First row raw input: \(result?.startRaw ?? "??")\nFirst row start parsed: \(result?.startParsed ?? "??")"
                self.step4TestLabel.text = resultString
                self.step4ApproveButton.isEnabled = true
            } catch {
                // Show error
                self.step4TestLabel.text = NSLocalizedString("Unable to parse", comment: "")
                self.step4ApproveButton.isEnabled = false
            }
        }
    }
    
    @IBAction func step4ApprovePressed(_ sender: Any) {
        do {
            // TODO: Show progress
            try self.importer?.parseAll()
            // TODO: End progress
            self.configureStep5Details()
            
            self.step4Container.isHidden = true
            self.step5Container.isHidden = false
        } catch {
            // show error
        }
    }
    
    // MARK: Step 5
    
    func configureStep5Details() {
        let rangesValue = self.importer?.ranges ?? 0
        let eventsValue = self.importer?.events ?? 0
        let rangesString = NSLocalizedString("Ranges: \(rangesValue)", comment: "")
        let eventsString = NSLocalizedString("Events: \(eventsValue)", comment: "")
        
        // TODO: Add review of columns prior to final submit
        
        self.step5DetailsLabel.text = NSLocalizedString("\(rangesString)\n\(eventsString)", comment: "")
    }
    
    @IBAction func step5SubmitPressed(_ sender: Any) {
        guard self.importer != nil else { return }
        
        Time.shared.store.importData(from: self.importer!) { (importedRequest, error) in
            guard error == nil else {
                return
            }
            DispatchQueue.main.async {
                self.dismiss(animated: true, completion: nil)
            }
        }
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
        return self.availableColumns.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return self.availableColumns[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if self.availableColumns.count > 0 {
            self.pickerViewSelectedValue = self.availableColumns[row]
        }
    }
}
