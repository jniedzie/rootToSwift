//
//  ArrayExtension.swift
//  rootToSwift
//
//  Created by Jeremi Niedziela on 14/08/2019.
//  Copyright © 2019 Jeremi Niedziela. All rights reserved.
//

import Foundation

extension Array where Element: Comparable {
  func secondToLast() -> Element? {
    if self.count < 2 {
      return nil
    }
    return self[self.count-2]
  }
  
  func containsSameElements(as other: [Element]) -> Bool {
    return self.count == other.count && self.sorted() == other.sorted()
  }
}
