//
//  Method.swift
//  rootToSwift
//
//  Created by Jeremi Niedziela on 15/08/2019.
//  Copyright © 2019 Jeremi Niedziela. All rights reserved.
//

import Foundation

class Method: NSObject {
  
  var name: String
  var returnType: String
  var specifiers: [String]
  var arguments: [(type:String, name: String)]
  
  /**
   Breaks down a string with C++ method declatation into its components
   - Parameters:
      - method: string with a C++ method declaration
   */
  required init?(method:(String)){
    
    self.name = ""
    self.returnType = ""
    self.specifiers = [""]
    self.arguments = [(type:"", name:"")]
    
    super.init()
    
    // Get method name
    guard let name = getName(methodString: method) else { return nil }
    self.name = name
    
    // Get return type
    guard let returnType = getReturnType(methodString: method) else { return nil }
    self.returnType = returnType
    
    // Get specifiers
    guard let specifiers = getSpecifiers(methodString: method) else { return nil }
    self.specifiers = specifiers
    
    // Get arguments
    guard let arguments = getArguments(methodString: method) else { return nil }
    self.arguments = arguments
    
    // Move star from method name to return type
    if name.range(of: #"[*]+[\w]*"#, options: .regularExpression) != nil {
      let starsRange = name.range(of: #"[*]+"#, options: .regularExpression)!
      self.returnType += name[starsRange]
      self.name.removeSubrange(starsRange)
    }
    
    // Replace root types by default C types
    for (rootType, cType) in rootTypes {
      self.returnType = self.returnType.replacingOccurrences(of: rootType, with: cType)
      for i in self.arguments.indices {
        self.arguments[i].type = self.arguments[i].type.replacingOccurrences(of: rootType, with: cType)
      }
    }
  }
  
  private func getNameAndArgs(methodString:String) -> [String]? {
    var nameAndArgs = methodString.components(separatedBy: "(")
    nameAndArgs = nameAndArgs.filter { $0 != "" }
    return nameAndArgs.filter { !$0.starts(with: ")") }
  }
  
  private func getReturnTypeAndName(methodString:String) -> [String]? {
    if let nameAndArgs = getNameAndArgs(methodString: methodString) {
      var returnAndName = nameAndArgs[0].components(separatedBy: .whitespaces)
      returnAndName = returnAndName.filter { $0 != "" }
      return returnAndName
    }
    else {return nil }
  }
  
  private func getName(methodString:String) -> String? {
    if let returnAndName = getReturnTypeAndName(methodString: methodString) {
      return returnAndName.last
    }
    else {return nil }
  }
  
  private func getReturnType(methodString:String) -> String? {
    if let returnAndName = getReturnTypeAndName(methodString: methodString) {
      return returnAndName.secondToLast()
    }
    else {return nil }
  }
  
  private func getSpecifiers(methodString:String) -> [String]? {
    if let returnAndName = getReturnTypeAndName(methodString: methodString){
      return Array(returnAndName[0 ..< returnAndName.count-2])
    }
    else {return nil }
  }
  
  private func getArguments(methodString:String) -> [(String, String)]? {
    guard let nameAndArgs = getNameAndArgs(methodString: methodString) else { return nil }
    
    var args = Array<String>()
    if nameAndArgs.count >= 2 { args = nameAndArgs[1].components(separatedBy: ",") }
    
    for i in args.indices {
      if let goodRange = args[i].range(of: #"(\s|\w|[*]|[&]|[:])*"#, options: .regularExpression) {
        args[i] = String(args[i][goodRange])
      }
      
      while args[i].starts(with: " ") {
        args[i].remove(at: args[i].startIndex)
      }
    }
    args = args.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
    
    var argComponents = Array<(type:(String), name:(String))>()
    
    for arg in args {
      var argComps = arg.components(separatedBy: .whitespaces)
      argComps = argComps.filter { $0.range(of: #"(\s)*"#, options: .regularExpression) != nil && !$0.isEmpty }
      
      var argType = ""
      for type in argComps[0 ..< argComps.count-1] {
        argType += "\(type) "
      }
      if !argType.isEmpty { argType.removeLast() }
      
      var argument = (type: argType, name: argComps.last!)
      
      if argument.name.range(of: #"[*|&]+[\w]*"#, options: .regularExpression) != nil {
        let starsRange = argument.name.range(of: #"[*|&]+"#, options: .regularExpression)!
        argument.type += argument.name[starsRange]
        argument.name.removeSubrange(starsRange)
      }
      argComponents.append(argument)
    }
    return argComponents
  }
  
  /**
   Adds all arguments of this method object to implementation and header strings provided
   - Parameters:
      - headerText: string to which header-style arguments will be added
      - implementationText: string to which implementation-style arguments will be added
   */
  func addArgumentsList(headerText:inout(String), implementationText:inout(String)) {
    var first = true
    
    for arg in arguments {
      var argNameNoDefault = arg.name
      stripDefaultValue(name: &argNameNoDefault)

      if first {
        first = false
        headerText += ":(\(arg.type)) \(argNameNoDefault) "
        implementationText += ":(\(arg.type)) \(arg.name) "
      }
      else {
        headerText += "\(argNameNoDefault):(\(arg.type)) \(argNameNoDefault) "
        implementationText += "\(argNameNoDefault):(\(arg.type)) \(arg.name) "
      }
    }
  }
  
  /**
   Adds methods body to the string provided
   - Parameters:
      - implementationText: string to which implementation-style arguments will be added
   */
  func addMethodImplementation(implementationText:inout(String)) {
    
    if returnType == "SObject*" {
      implementationText += "{\n TObject *obj = [self object]->\(name)("
    }
    else {
      implementationText += "{\nreturn [self object]->\(name)("
    }
    
    if arguments.count > 0 {
      var first = true
      
      for arg in arguments {
        if first { first = false }
        else { implementationText += ", " }
        implementationText += "\(arg.name)"
      }
    }
    
    if returnType == "SObject*" {
      implementationText += """
      );
      CPPMembers *members = new CPPMembers(obj);
      return [[SObject alloc] initWithObject:members];
      }\n\n
      """
    }
    else {
      implementationText += ");\n}\n\n"
    }
  }
  
}
