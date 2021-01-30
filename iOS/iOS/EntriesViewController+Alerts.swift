//
//  EntriesViewController+Alerts.swift
//  iOS
//
//  Created by Nathan Tornquist on 5/28/19.
//  Copyright © 2019 nathantornquist. All rights reserved.
//

import UIKit
import TimeSDK

extension EntriesViewController {
    func showAlertFor(deleting entry: Entry, completion: @escaping (Bool) -> Void) {
        let category = Time.shared.store.categories.first(where: { $0.id == entry.categoryID })
        let type = entry.type.rawValue.capitalized
        let title = category != nil
            ? NSLocalizedString("Delete \(type) on \(category!.name)", comment: "")
            : NSLocalizedString("Delete \(type)", comment: "")
        let message = entry.type == .event
            ? NSLocalizedString("Event occurred at \(entry.startedAt.description)", comment: "")
            : NSLocalizedString("Range ran from \(entry.startedAt.description) to \(entry.endedAt != nil ? entry.endedAt!.description : "Present")", comment: "")
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        let deleteTitle = NSLocalizedString("Delete", comment: "")
        let deleteAction = UIAlertAction(title: deleteTitle, style: .destructive) { _ in completion(true) }
        alert.addAction(deleteAction)
        
        let cancelTitle = NSLocalizedString("Cancel", comment: "")
        let cancelAction = UIAlertAction(title: cancelTitle, style: .cancel) { _ in completion(false) }
        alert.addAction(cancelAction)

        if Thread.current.isMainThread {
            self.present(alert, animated: true, completion: nil)
        } else {
            DispatchQueue.main.async {
                self.present(alert, animated: true, completion: nil)
            }
        }
    }
}
