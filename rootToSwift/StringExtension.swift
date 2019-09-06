//
//  StringExtension.swift
//  rootToSwift
//
//  Created by Jeremi Niedziela on 02/09/2019.
//  Copyright © 2019 Jeremi Niedziela. All rights reserved.
//

import Foundation

extension String {
  
  /**
   Removes what looks like default arguments declaration in C from the provided string. If there
   are no default arguments, the same string is returned
   */
  func strippingDefaultValue() -> String {
    if let nameRange = self.range(of: #"(\w)*"#, options: .regularExpression) {
      return String(self[nameRange])
    }
    return self
  }
  
  func removingFirstCharacter() -> String {
    if self.isEmpty { return "" }
    var newString = self
    newString.removeFirst()
    return newString
  }
  
  mutating func replaceCharacter(atIndex index: Int, with newChar: Character) {
    var chars = Array(self)
    chars[index] = newChar
    self = String(chars)
  }
}
