//
//  fileTools.swift
//  rootToSwift
//
//  Created by Jeremi Niedziela on 08/08/2019.
//  Copyright © 2019 Jeremi Niedziela. All rights reserved.
//

import Foundation

/**
 Class allowing to read public methods from C++ header file and write a string to a file
 */
class FileProcessor: NSObject {

  private let commentPattern = #"(/\*([^*]|[\r\n]|(\*+([^*/]|[\r\n])))*\*+/)|(//.*)"#
  private let templatePattern = #"[<][\s|\w]*[>]"#
  private let implementationPattern = #"[{](\w|\s|[=]|[(]|[)]|[,]|[;]|[->]|[?]|[:])*[}]"#
  private let returnAndNamePattern = #"[\w|\s|[*]]*"#
  private let argumentsPattern = #"[(]([\w|\W|\s|[&]|(*)*|[,]|[=]]*)[)](\s|\w)*[;]"#
  private let classPattern = #"[\s]*class[\w|\s]*[:]?[\w|\s|[,]|[::]]*[{]"#
  
  /**
   Get classes declarations from ROOT header
   - Parameters:
       - rootHeader: Base ROOT header name, e.g. `Browser` for `TBrowser.h`
   - Returns: Array of classes names and corresponding C++ declaration read from ROOT header
   */
  func getClasses(fromRootHeader rootHeader: String) -> [(name: String, text: String)] { 
    let rootHeader = trickyHeaders[rootHeader] ?? rootHeader
    
    let rootClassPath       = "\(rootIncludePath)/T\(rootHeader).h"
    let inputText           = String(fromFile: rootClassPath)
    return getClassesFromText(text: inputText)
  }
  
  /**
   Finds public C++ methods in a string
   - Parameters:
   - text: text in which to find public C++ methods
   - Returns: Array of public C++ methods, one per entry
   */
  func getPublicMethodsFromText(text: String) -> [String] {
    var textTmp = text
    textTmp.removeRegularExpression(expression: commentPattern)
    
    var publicText = fileProcessor.getPublicFrom(text: textTmp)

    publicText.replaceRegularExpression(expression: implementationPattern, with: ";")
    publicText.removeOccurrences(of: "\n")
    publicText.replaceOccurrences(of: ";", with: ";\n")
    
    let methodPattern = returnAndNamePattern + argumentsPattern
    
    var publicMethods: [String] = []
    
    let textByLine = publicText.components(separatedBy: .newlines)
    
    for line in textByLine {
      if line.range(of: methodPattern, options: .regularExpression) != nil &&
          line.range(of: #"operator"#, options: .regularExpression) == nil &&
          line.range(of: #"ClassDef*"#, options: .regularExpression) == nil &&
          line.range(of: #"(\w|\s)*[~](\w|\s|[(]|[)]|[;])*"#, options: .regularExpression) == nil {
        publicMethods.append(line)
      }
    }
    return publicMethods
  }
  
  /**
   Finds public C++ methods in a string
   - Parameters:
   - text: text in which to find public C++ methods
   - Returns: Array of public C++ methods, one per entry
   */
  func getPublicEnumsFromText(text: String) -> [String] {
    var textTmp = text
    textTmp.removeRegularExpression(expression: commentPattern)
    
    var publicText = fileProcessor.getPublicFrom(text: textTmp)

    publicText.removeOccurrences(of: "\n")
    publicText.replaceOccurrences(of: ";", with: ";\n")

    let enumPattern = #"[\s]*enum[.]*"#
    var publicEnums: [String] = []
    
    let textByLine = publicText.components(separatedBy: .newlines)
    
    for line in textByLine {
      if line.range(of: enumPattern, options: .regularExpression) != nil &&
          line.range(of: #"ClassDef*"#, options: .regularExpression) == nil &&
          line.range(of: #"(\w|\s)*[~](\w|\s|[(]|[)]|[;])*"#, options: .regularExpression) == nil {
      
        publicEnums.append(line)
      }
    }
    
    return publicEnums
  }
  
//------------------------------------------------------------------------
// Private methods
//------------------------------------------------------------------------
  
  private func getClassNameAndRange(fromText text: String) -> (name: String, range: Range<String.Index>)? {
    guard let range = text.range(of: classPattern, options: .regularExpression) else { return nil }
    
    var name = String(text[range])
    name = String(name.split(separator: " ")[1])
    name.removeFirst()
    name.removeOccurrences(of: ":")
    return (name, range)
  }
  
  private func findFirstUnopenedBracket(inText text: String, startingFrom index: String.Index) -> String.Index {
    var unclosedBrackets = 1
    var iter = index
   
    while unclosedBrackets > 0 {
      if text[iter] == "{" { unclosedBrackets += 1 }
      if text[iter] == "}" { unclosedBrackets -= 1 }
      iter = text.index(iter, offsetBy: 1)
    }
    
    return iter
  }
  
  /**
   Finds all class declarations inside of a single string and splits them into array of strings
   */
  private func getClassesFromText(text: String) -> [(name:String, text: String)] {
    var textTmp = text
    textTmp.removeRegularExpression(expression: commentPattern)
    textTmp.removeRegularExpression(expression: templatePattern)

    var classes = Array<(name: String, text: String)>()
    
    while true {
      guard let (name, range) = getClassNameAndRange(fromText: textTmp) else { break }

      let classEnd = findFirstUnopenedBracket(inText: textTmp, startingFrom: range.upperBound)
      let classRange = range.lowerBound...classEnd
      let classText = String(textTmp[classRange])
      textTmp.removeSubrange(classRange)
      
      classes.append((name, classText))
    }
    return classes
  }
  
  /**
   Selects only lines that are after "public:" keyword and not after "private:" or "protected:"
   - Parameters:
       - text: text to be filtered
   - Returns: Text filtered from non "public:" lines
   */
  private func getPublicFrom(text: String) -> String {
    let textByLine = text.components(separatedBy: .newlines)
    let publicPattern   = #"(\s)*public:(\s)*"#
    let privatePattern  = #"(\s)*(private:|protected:|class )(\s)*"#
    
    var isPublic = false
    var textPublic = ""
    
    for line in textByLine {
      if !isPublic {
        if line.range(of: publicPattern, options: .regularExpression) != nil { isPublic = true }
        continue
      }
      else {
        if line.range(of: privatePattern, options: .regularExpression) != nil {
          isPublic = false
          continue
        }
      }
      textPublic += line
      textPublic += "\n"
    }
    return textPublic
  }
  
}

