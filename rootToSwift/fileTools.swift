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
    let argumentsPattern = #"[(]([\w|\W|\s|[&]|(*)*|[,]|[=]]*)[)](\s|\w)*[;]"#
    
    let methodPattern = returnAndNamePattern + argumentsPattern
    
    var publicMethods: [String] = []

    let textByLine = text.components(separatedBy: .newlines)
    
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
   Creates beginnig of the wrapper's header
   - Parameters:
      - className: Output class name ("S" prefix will be added to it)
   - Returns: String containing beginning of the header
   */
  func getHeaderBeginning(className:(String), currentDate:(String)) -> String {
    return """
    //  S\(className).h
    //  swiftRoot
    //
    //  Created by Jeremi Niedziela on \(currentDate).
    //  Copyright © 2019 Jeremi Niedziela. All rights reserved.
    
    #ifndef S\(className)_h
    #define S\(className)_h
    
    #import "SObject.h"
    
    @interface S\(className) : SObject
    
    """
  }
  
  /**
   Creates ending of the wrapper's header
   - Parameters:
      - className: Output class name ("S" prefix will be added to it)
   - Returns: String containing ending of the header
   */
  func getHeaderEnding(className:(String)) -> String {
    return """
    @end
    
    #endif /* S\(className)_h */
    """
  }
  
  func getImplementationBeginning(className:(String), currentDate:(String)) -> String {
    return """
    //  S\(className).m
    //  swiftRoot
    //
    //  Created by Jeremi Niedziela on \(currentDate).
    //  Copyright © 2019 Jeremi Niedziela. All rights reserved.
    
    #import "S\(className).h"
    #import "CPPMembers.mm"
    
    @implementation S\(className)
    
    - (id) initWithSObject:(SObject*) object
    {
      self = [super init];
      if(self){ self.cppMembers = object.cppMembers; }
      return self;
    }
      
    - (void)dealloc
    {
          
    }
    
    -(T\(className)*) object
    {
        return (T\(className)*)self.cppMembers->object;
    }\n
    """
  }

  func getImplementationEnding() -> String {
    return """
    
    @end
    """
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

