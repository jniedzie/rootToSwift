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

  /**
   Get classes declarations from ROOT header
   - Parameters:
       - rootHeader: Base ROOT header name, e.g. `Browser` for `TBrowser.h`
   - Returns: Array of classes names and corresponding C++ declaration read from ROOT header
   */
  func getClasses(fromRootHeader rootHeader: String) -> [(name: String, text: String)] {
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
    let commentPattern = #"(/\*([^*]|[\r\n]|(\*+([^*/]|[\r\n])))*\*+/)|(//.*)"#
    let textTmp = text.replacingOccurrences(of: commentPattern, with: "", options: .regularExpression)
    
    var publicText = fileProcessor.getPublicFrom(text: textTmp)
    
    let implementationPattern = #"[{](\w|\s|[=]|[(]|[)]|[,]|[;]|[->]|[?]|[:])*[}]"#
    publicText = publicText.replacingOccurrences(of: implementationPattern, with: ";", options: .regularExpression)
    
    publicText = publicText.replacingOccurrences(of: "\n", with: "")
    publicText = publicText.replacingOccurrences(of: ";", with: ";\n")
    
    let returnAndNamePattern = #"[\w|\s|[*]]*"#
    let argumentsPattern = #"[(]([\w|\W|\s|[&]|(*)*|[,]|[=]]*)[)](\s|\w)*[;]"#
    
    let methodPattern = returnAndNamePattern + argumentsPattern
    
    var publicMethods: [String] = []
    
    let textByLine = publicText.components(separatedBy: .newlines)
    
    for line in textByLine {
      if line.range(of: methodPattern, options: .regularExpression) != nil &&
        line.range(of: #"ClassDef*"#, options: .regularExpression) == nil &&
        line.range(of: #"(\w|\s)*[~](\w|\s|[(]|[)]|[;])*"#, options: .regularExpression) == nil {
        publicMethods.append(line)
      }
    }
    return publicMethods
  }
  
  /**
   Writes string to a file
   - Parameters:
      - text: Text to be written to a file
      - filePath: path for the output file
   */
  func writeText(text: String, filePath: String) -> Void {
    do    { try text.write(to: URL(fileURLWithPath: filePath), atomically: true, encoding: .utf8) }
    catch { print("Could not save file")}
  }
  
//------------------------------------------------------------------------
// Private methods
//------------------------------------------------------------------------
  
  /**
   Finds all class declarations inside of a single string and splits them into array of strings
   */
  private func getClassesFromText(text: String) -> [(name:String, text: String)] {
    let commentPattern = #"(/\*([^*]|[\r\n]|(\*+([^*/]|[\r\n])))*\*+/)|(//.*)"#
    var textTmp = text.replacingOccurrences(of: commentPattern, with: "", options: .regularExpression)
    
    let templatePattern = #"[<][\s|\w]*[>]"#
    textTmp = textTmp.replacingOccurrences(of: templatePattern, with: "", options: .regularExpression)
    
    let classPattern = #"[\s]*class[\w|\s]*[:]?[\w|\s|[,]|[::]]*[{]"#
    var classes = Array<(name: String, text: String)>()
    
    var foundClass = true
    while foundClass {
      foundClass = false
      
      if let classNameRange = textTmp.range(of: classPattern, options: .regularExpression) {
        var className = String(textTmp[classNameRange])
        className = String(className.split(separator: " ")[1])
        if className.first == "T" { className.removeFirst() }
        className = className.replacingOccurrences(of: ":", with: "")
        
        var unclosedBrackets = 1
        var iter = classNameRange.upperBound
        
        while unclosedBrackets > 0 {
          if textTmp[iter] == "{" { unclosedBrackets += 1 }
          if textTmp[iter] == "}" { unclosedBrackets -= 1 }
          iter = textTmp.index(iter, offsetBy: 1)
        }
        
        let classRange = classNameRange.lowerBound...iter
        
        let classText = String(textTmp[classRange])
        textTmp.removeSubrange(classRange)
        foundClass = true
        classes.append((className, classText))
      }
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

