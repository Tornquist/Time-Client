//
//  CategoryReportStore.swift
//  iOS
//
//  Created by Nathan Tornquist on 10/2/22.
//  Copyright © 2022 nathantornquist. All rights reserved.
//

import Foundation
import Combine
import SwiftUI
import TimeSDK

struct CategoryReportValue: Equatable, Identifiable {
    var stringDate: String
    var date: Date
    var category: String
    var value: TimeInterval
    
    var id: String {
        return "\(stringDate)-\(category)-\(value)"
    }
}

class CategoryReportStore: ObservableObject {
    @Published var warehouse: Warehouse
    @Binding var rootCategory: TimeSDK.Category?
    
    @Published var title: String = "Analytics"
    @Published var durationData: [CategoryReportValue] = []
    @Published var quantityData: [CategoryReportValue] = []
    
    // TODO: Remove need to keep init in sync with view
    var range: RangeOption = .month
    var groupBy: TimePeriod = .day
    
    @Published var loading: Bool = false
    
    @Published var startRange: Date = Date()
    @Published var endRange: Date = Date()
    
    enum RangeOption: String {
        case all = "all"
        case year = "year"
        case sixMonths = "six_months"
        case threeMonths = "three_months"
        case month = "month"
        case week = "week"
    }
    
    init(for warehouse: Warehouse, category: Binding<TimeSDK.Category?>) {
        self.warehouse = warehouse
        self._rootCategory = category
        
        // Bump to end of thread to let binding resolve -- Needs correct implementation.
        self.loading = true
        DispatchQueue.main.async {
            self.compute()
        }
    }

    func recompute(range: RangeOption, gropuBy: TimePeriod) {
        guard self.range != range || self.groupBy != gropuBy else {
            return // No change
        }
        
        self.range = range
        self.groupBy = gropuBy
        
        self.compute()
    }
    
    func reset() {
        Mainify {
            self.title = "Analytics"
        }
    }
    
    func compute() {
        self.loading = true
        DispatchQueue.global(qos: .background).async {
            guard let categoryID = self.rootCategory?.id,
                  let categoryTree = Time.shared.store.categoryTrees.map({ (key: Int, value: CategoryTree) in
                      return value.findItem(withID: categoryID)
                  }).filter({ $0 != nil }).first,
                  let categoryTree = categoryTree
            else {
                self.reset()
                return
            }

            // Identify Scope
            let inScopeCategoryIDs = categoryTree.listCategoryTrees().map { $0.id }
            
            // Calculate General Metrics
            var allResults: [String: [Analyzer.Result]] = [:]
            if self.range == .all {
                allResults = Time.shared.analyzer.evaluateAll(
                    groupBy: self.groupBy,
                    perform: [.calculatePerCategory],
                    includeEmpty: true
                )
            } else if self.range == .sixMonths || self.range == .threeMonths {
                let shift = self.range == .sixMonths ? 6 : 3
                let startRange = Calendar.current.date(byAdding: .month, value: -shift, to: Date())!
                
                allResults = Time.shared.analyzer.evaluate(
                    from: startRange,
                    to: nil,
                    in: Calendar.current,
                    groupBy: self.groupBy,
                    perform: [.calculatePerCategory],
                    includeEmpty: true
                )
            } else {
                var range: TimeRange = TimeRange(rolling: .year)
                switch self.range {
                case .year:
                    range = TimeRange(rolling: .year)
                case .month:
                    range = TimeRange(rolling: .month)
                case .week:
                    range = TimeRange(rolling: .week)
                default:
                    break
                }
                allResults = Time.shared.analyzer.evaluate(
                    range,
                    groupBy: self.groupBy,
                    perform: [.calculatePerCategory],
                    includeEmpty: true
                )
            }
            
            var inScopeResults: [String: [Analyzer.Result]] = [:]
            allResults.keys.forEach { key in
                inScopeResults[key] = allResults[key]!.filter({ result in
                    guard let categoryID = result.categoryID else { return false }
                    return inScopeCategoryIDs.contains(categoryID)
                })
            }
            
            // Format for graph
            var nameCache: [Int: String] = [:]
            inScopeCategoryIDs.forEach { categoryID in
                nameCache[categoryID] = self.warehouse.getName(for: categoryID)
            }
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            dateFormatter.timeZone = TimeZone.current // Sync with analyzer
            dateFormatter.locale = Locale.current // Sync with analyzer
            
            let orderedKeys = inScopeResults.keys.sorted()
            let durationData = orderedKeys.flatMap { key -> [CategoryReportValue] in
                guard let data = inScopeResults[key],
                      let date = dateFormatter.date(from: key) else {
                    return []
                }
                
                let unsortedDurationData = data.compactMap({ result -> CategoryReportValue? in
                    guard result.duration != 0 else {
                        return nil
                    }
                    return CategoryReportValue(
                        stringDate: key,
                        date: date,
                        category: nameCache[result.categoryID ?? -1] ?? "Unknwon",
                        value: result.duration
                    )
                })
                    
                let sortedDurationData = unsortedDurationData.sorted { a, b in
                    return a.category.localizedCompare(b.category) == .orderedAscending
                }
                
                return sortedDurationData
            }
            
            // TODO: Simplify code for a single pass
            let quantityData = orderedKeys.flatMap { key -> [CategoryReportValue] in
                guard let data = inScopeResults[key],
                      let date = dateFormatter.date(from: key) else {
                    return []
                }
                
                let unsortedQuantityData = data.compactMap({ result -> CategoryReportValue? in
                    guard result.events != 0 else {
                        return nil
                    }
                    return CategoryReportValue(
                        stringDate: key,
                        date: date,
                        category: nameCache[result.categoryID ?? -1] ?? "Unknwon",
                        value: TimeInterval(result.events)
                    )
                })
                    
                let sortedQuantityData = unsortedQuantityData.sorted { a, b in
                    return a.category.localizedCompare(b.category) == .orderedAscending
                }
                
                return sortedQuantityData
            }

            // Should always safely resolve
            let first = (orderedKeys.first != nil ? dateFormatter.date(from: orderedKeys.first!) : nil) ?? Date()
            let last = (orderedKeys.last != nil ? dateFormatter.date(from: orderedKeys.last!) : nil) ?? Date()
            let lastInclusive = Calendar.current.date(byAdding: .day, value: 1, to: last)!
            
            DispatchQueue.main.async {
                self.title = (self.rootCategory?.parentID != nil ? self.rootCategory?.name : nil) ?? "Analytics"
                
                self.durationData = durationData
                self.quantityData = quantityData
                
                self.startRange = first
                self.endRange = lastInclusive
                
                self.loading = false
            }
        }
    }
}
