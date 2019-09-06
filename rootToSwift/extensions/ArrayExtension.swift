//
//  ArrayExtension.swift
//  rootToSwift
//
//  Created by Jeremi Niedziela on 14/08/2019.
//  Copyright © 2019 Jeremi Niedziela. All rights reserved.
//

import Foundation

extension Array where Element: Comparable {
  
  /// Returns second to last element of the array
  func secondToLast() -> Element? {
    return self.count < 2 ? nil : self[self.count-2]
  }
  
  /// Checks if this array contains the same elements as other array.
  /// Returns true even if order of the elements is different
  func containsSameElements(as other: [Element]) -> Bool {
    return self.count == other.count && self.sorted() == other.sorted()
  }
}
