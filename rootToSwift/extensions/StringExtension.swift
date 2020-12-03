//
//  StringExtension.swift
//  rootToSwift
//
//  Created by Jeremi Niedziela on 02/09/2019.
//  Copyright © 2019 Jeremi Niedziela. All rights reserved.
//

import Foundation

extension String {
  
  /// Initializes string with contents of file
  init(fromFile path: String) {
    do {
      try self.init(contentsOf: URL(fileURLWithPath: path), encoding: .utf8)
    }
    catch {
      self.init()
      print("\nERROR -- Couldn't read file: \(path)\n")
    }
  }
  
  /// Saves string to file
  func save(toPath path: String) {
    do    {
      try self.write(to: URL(fileURLWithPath: path), atomically: true, encoding: .utf8)
    }
    catch {
      print("Could not save file")
    }
  }
  
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
  
  /// Returns string with first character removed
  func removingFirstCharacter() -> String {
    if self.isEmpty { return "" }
    var newString = self
    newString.removeFirst()
    return newString
  }
  
  /// Replaces character at given index with a different character
  mutating func replaceCharacter(atIndex index: Int, with newChar: Character) {
    var chars = Array(self)
    chars[index] = newChar
    self = String(chars)
  }
  
  /// Removes all occurrences of target string from this string
  mutating func removeOccurrences(of target: String) {
    self = self.replacingOccurrences(of: target, with: "")
  }
  
  /// Replaces all occurrences of target string with replacement string
  mutating func replaceOccurrences(of target: String, with replacement: String) {
    self = self.replacingOccurrences(of: target, with: replacement)
  }
  
  /// Removes all occurrences of regular expression from string
  mutating func removeRegularExpression(expression: String) {
    self = self.replacingOccurrences(of: expression, with: "", options: .regularExpression)
  }
  
  /// Replaces all occurrences of regular expression with replacement string
  mutating func replaceRegularExpression(expression: String, with replacement: String) {
    self = self.replacingOccurrences(of: expression, with: replacement, options: .regularExpression)
  }
}
