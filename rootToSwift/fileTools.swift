//
//  fileTools.swift
//  rootToSwift
//
//  Created by Jeremi Niedziela on 08/08/2019.
//  Copyright © 2019 Jeremi Niedziela. All rights reserved.
//

import Foundation

class FileProcessor: NSObject {

  /**
   Opens file from path and returns its content as a string
   - Parameters:
      - path: Input file path
   - Returns: String containing file contents
  */
  func getContentsOfFile(path: (String)) -> String {
    do    { return try String(contentsOf: URL(fileURLWithPath: path), encoding: .utf8) }
    catch { print("Couldn't read the file") }
    return ""
  }
  
  /**
   Writes string to a file
   - Parameters:
      - text: Text to be written to a file
      - filePath: path for the output file
   */
  func writeText(text:(String), filePath:(String)) -> Void {
    do    { try text.write(to: URL(fileURLWithPath: filePath), atomically: true, encoding: .utf8) }
    catch { print("Could not save file")}
  }
  
  /**
   Finds public C++ methods in a string
   - Parameters:
      - text: text in which to find public C++ methods
   - Returns: Array of public C++ methods, one per entry
   */
  func getPublicMethods(text:(String)) -> [String] {
    let commentPattern = #"(/\*([^*]|[\r\n]|(\*+([^*/]|[\r\n])))*\*+/)|(//.*)"#
    var text = removePattern(pattern: commentPattern, text: text)
    
    text = fileProcessor.getPublicFrom(text: text)
    
    let implementationPattern = #"[{](\w|\s|[=]|[(]|[)]|[,]|[;]|[->]|[?]|[:])*[}]"#
    text = fileProcessor.removePattern(pattern: implementationPattern, text: text)
    
    text = text.replacingOccurrences(of: "\n", with: "")
    text = text.replacingOccurrences(of: ";", with: ";\n")
    
    let returnAndNamePattern = #"[\w|\s|[*]]*"#
    let argumentsPattern = #"[(]([\w|\W|\s|[&]|[*]*|[,]|[=]]*)[)](\s|\w)*[;]"#
    
    let methodPattern = returnAndNamePattern + argumentsPattern
    
    var publicMethods: [String] = []

    let textByLine = text.components(separatedBy: .newlines)
    
    for line in textByLine {
      if line.range(of: methodPattern, options: .regularExpression) != nil &&
        line.range(of: #"ClassDef*"#, options: .regularExpression) == nil {
        publicMethods.append(line)
      }
    }
    return publicMethods
  }
  
  enum FileProcessorError: Error {
    case noReturnOrName
  }
  
  /**
   Breaks down a string with C++ method declatation into its components
   - Parameters:
      - method: string with a C++ method declaration
   - Throws: can throw an error if string doesn't look like a C++ method declaration
   - Returns: tuple with name, return type, specifiers and arguments of the method
   */
  func getMethodPieces(method:(String)) throws ->
    (name:(String), returnType:(String), specifiers:([String]), arguments:[(type:(String), name:(String))])
  {
    var nameAndArgs = method.components(separatedBy: "(")
    nameAndArgs = nameAndArgs.filter { $0 != "" }
    nameAndArgs = nameAndArgs.filter { !$0.starts(with: ")") }
    
    var returnAndName = nameAndArgs[0].components(separatedBy: .whitespaces)
    returnAndName = returnAndName.filter { $0 != "" }
    
    var args = Array<String>()
    
    if nameAndArgs.count >= 2 {
      args = nameAndArgs[1].components(separatedBy: ",")
    }

    guard var name = returnAndName.last
      else{
      throw FileProcessorError.noReturnOrName
    }
    
    guard var returnType = returnAndName.secondToLast()
      else{
      throw FileProcessorError.noReturnOrName
    }

    let specifiers = Array(returnAndName[0 ..< returnAndName.count-2])
    
    for i in args.indices {
      args[i] = args[i].replacingOccurrences(of: ")", with: "")
      args[i] = args[i].replacingOccurrences(of: ";", with: "")
    }
    args = args.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
    
    if name.range(of: #"[*]+[\w]*"#, options: .regularExpression) != nil {
      let starsRange = name.range(of: #"[*]+"#, options: .regularExpression)!
      returnType += name[starsRange]
      name.removeSubrange(starsRange)
    }
    
    var argComponents = Array<(type:(String), name:(String))>()
    
    for arg in args {
      var argument = (type: arg.components(separatedBy: .whitespaces)[0],
                      name: arg.components(separatedBy: .whitespaces)[1])
      
      if argument.name.range(of: #"[*]+[\w]*"#, options: .regularExpression) != nil {
        let starsRange = argument.name.range(of: #"[*]+"#, options: .regularExpression)!
        argument.type += argument.name[starsRange]
        argument.name.removeSubrange(starsRange)
      }
      argComponents.append(argument)
    }
    
    return (name, returnType, specifiers, argComponents)
  }
  
  /**
   Selects only lines that are after "public:" keyword and not after "private:" or "protected:"
   - Parameters:
   - text: text to be filtered
   - Returns: Text filtered from non "public:" lines
   */
  private func getPublicFrom(text:(String)) -> String {
    let textByLine = text.components(separatedBy: .newlines)
    let publicPattern   = #"(\s)*public:(\s)*"#
    let privatePattern  = #"(\s)*(private:|protected:)(\s)*"#
    
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
  
  /**
   Removes specified pattern from a text
   - Parameters:
      - pattern: regex pattern to be removed
      - text: text to filter
   - Returns: A text from which all occurences for given pattern were removed
   */
  private func removePattern(pattern:(String), text:(String)) -> String {
    var cleanedText = text
    
    var removed = true
    
    while removed {
      removed = false
      if let patternRange = cleanedText.range(of: pattern,
                                              options: .regularExpression,
                                              range: nil, locale: nil){
        
        cleanedText.replaceSubrange(patternRange, with: ";")
        removed = true
      }
    }
    return cleanedText
  }
  
}

