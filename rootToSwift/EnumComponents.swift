//
//  EnumComponents.swift
//  rootToSwift
//
//  Created by Jeremi Niedziela on 03/12/2020.
//  Copyright © 2020 Jeremi Niedziela. All rights reserved.
//

import Foundation

class EnumComponents: Hashable {
  // MARK: - Properties
  var name: String
  var cases: [String]
  
  func hash(into hasher: inout Hasher) {
    hasher.combine(name)
    for name in cases { hasher.combine(name) }
  }
  
  // MARK: - Constructor
  
  
  /**
   Breaks down a string with C++ method declatation into its components
   - Parameters:
      - method: string with a C++ method declaration
   */
  required init?(enumString: String){
    
    self.name = ""
    self.cases = []
    
    // Get method name
    guard let name = getName(enumString: enumString) else { return nil }
    self.name = name
    
    if name.range(of: "operator", options: .regularExpression) != nil { return nil }
    
    // Get cases
    guard let cases = getCases(enumString: enumString) else { return nil }
    self.cases = cases
  }
  
  // MARK: - Comparison operator
  
  /// Comparison operator
  static func ==(lhs: EnumComponents, rhs: EnumComponents) -> Bool{
    var hasherA = Hasher(); lhs.hash(into: &hasherA)
    var hasherB = Hasher(); rhs.hash(into: &hasherB)
    return hasherA.finalize() == hasherB.finalize()
  }
  
  // MARK: - Public methods
  
  
  /**
   Adds objective-C declaration and implementation of this method to `headerText` and `implementationText` resoectively
  - Parameters:
      - header: string to which header-style arguments will be added
      - implementation: string to which implementation-style arguments will be added
  */
  func addEnum(toHeader header: inout String) {
    
//    typedef enum {
//           Monday=1,
//           Tuesday,
//           Wednesday
//
//       } WORKDAYS;
    
    
    var enumDeclaration = "typedef enum { ";
    
    var first = true
    for enumCase in cases {
      
      if first {
        enumDeclaration += enumCase
        first = false
      }
      else {
        enumDeclaration += ", \(enumCase)"
        
      }
    }
    enumDeclaration += "} \(name);\n"
    
    header += enumDeclaration
  }

  
  // MARK: - Private methods
  
  /**
   Separates provided string into enum name and its cases
   */
  private func getNameAndCases(enumString: String) -> [String]? {
    var startIndex: String.Index?
    var endIndex: String.Index?
    
    for index in enumString.indices {
      if startIndex != nil, endIndex != nil { break }
      
      if startIndex==nil, enumString[index]=="{" { startIndex = index }
      if endIndex==nil, enumString[index]=="}" { endIndex = index }
    }
    
    if startIndex==nil || endIndex==nil {
      print("Could not find method name and cases in enum:\(enumString)")
      return nil
    }
    
    var nameAndCases = [enumString[enumString.startIndex..<startIndex!]]
    
    if enumString.index(startIndex!, offsetBy: 1) < endIndex! {
       nameAndCases.append(enumString[enumString.index(startIndex!, offsetBy: 1)..<endIndex!])
    }
    
    nameAndCases = nameAndCases.filter { !$0.isEmpty }
    
    var nameAndCasesString = [String]()
    for nc in nameAndCases { nameAndCasesString.append(String(nc)) }
    
    return nameAndCasesString
  }
  
  /// Returns name of the enum
  private func getName(enumString: String) -> String? {
    if let nameAndCases = getNameAndCases(enumString: enumString) {
      var name = nameAndCases[0]
      if let enumRange = name.range(of: #"enum"#, options: .regularExpression) {
        name.replaceSubrange(enumRange, with: "")
        name.replaceOccurrences(of: " ", with: "")
      }
      return name
    }
    else {return nil }
  }
  
  /// Returns cases of the enum
  private func getCases(enumString: String) -> [String]? {
    guard let nameAndCases = getNameAndCases(enumString: enumString) else { return nil }
    
    var cases = Array<String>()
    if nameAndCases.count >= 2 { cases = nameAndCases[1].components(separatedBy: ",") }
    
    for i in cases.indices {
      while cases[i].starts(with: " ") {
        cases[i].remove(at: cases[i].startIndex)
      }
    }
    cases = cases.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
    return cases
  }
  
  
}

