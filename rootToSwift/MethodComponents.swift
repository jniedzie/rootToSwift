//
//  Method.swift
//  rootToSwift
//
//  Created by Jeremi Niedziela on 15/08/2019.
//  Copyright © 2019 Jeremi Niedziela. All rights reserved.
//

import Foundation

class MethodComponents: NSObject {
  
  var name: String
  var returnType: String
  var specifiers: [String]
  var arguments: [(type:String, name: String)]
  var isConstructor: Bool
  
  /**
   Breaks down a string with C++ method declatation into its components
   - Parameters:
      - method: string with a C++ method declaration
   */
  required init?(methodString: String){
    
    self.name = ""
    self.returnType = ""
    self.specifiers = [""]
    self.arguments = [(type:"", name:"")]
    self.isConstructor = false
    
    super.init()
    
    // Get method name
    guard let name = getName(methodString: methodString) else { return nil }
    self.name = name
    
    // Get return type
    if let returnType = getReturnType(methodString: methodString){
      self.returnType = returnType
      // Get specifiers
      guard let specifiers = getSpecifiers(methodString: methodString) else { return nil }
      self.specifiers = specifiers
    }
    else {
      self.isConstructor = true
    }
    
    // Get arguments
    guard let arguments = getArguments(methodString: methodString) else { return nil }
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
    
    if self.returnType.contains("TT") {
      self.returnType = self.returnType.replacingOccurrences(of: "TT", with: "ST")
    }
    else {
      self.returnType = self.returnType.replacingOccurrences(of: "T", with: "S")
    }
    
    for i in self.arguments.indices {
      if self.arguments[i].type.contains("TT") {
        self.arguments[i].type = self.arguments[i].type.replacingOccurrences(of: "TT", with: "ST")
      }
      else{
        self.arguments[i].type = self.arguments[i].type.replacingOccurrences(of: "T", with: "S")
      }
    }
    
  }
  
  static func ==(lhs: MethodComponents, rhs: MethodComponents) -> Bool{
    
    if lhs.name != rhs.name { return false }
    if lhs.returnType != rhs.returnType { return false }
    if lhs.isConstructor != rhs.isConstructor { return false }

    if !lhs.specifiers.containsSameElements(as: rhs.specifiers) { return false }
    
    func contains(a:[(String, String)], b:(String, String)) -> Bool {
      let (b1, b2) = b
      for (a1, a2) in a { if a1 == b1 && a2 == b2 { return true } }
      return false
    }
    
    if lhs.arguments.count != rhs.arguments.count { return false }
    
    for arg in lhs.arguments {
      if !contains(a: rhs.arguments, b: arg) { return false }
    }
    
    return true
  }
  
  /**
   Adds all arguments of this method object to implementation and header strings provided
   - Parameters:
      - headerText: string to which header-style arguments will be added
      - implementationText: string to which implementation-style arguments will be added
   */
  func addMethod(headerText: inout String, implementationText: inout String) {
    let methodDeclaration = "-(\(returnType)) \(name)"
    headerText += methodDeclaration
    implementationText += methodDeclaration
    
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
    headerText += ";\n\n"
    addMethodImplementation(implementationText: &implementationText)
  }
  
  /**
   Adds methods body to the string provided
   - Parameters:
   - implementationText: string to which implementation-style arguments will be added
   */
  private func addMethodImplementation(implementationText: inout String) {
    
    if returnType == "SObject*" {
      implementationText += "{\n\tTObject *obj = [self object]->\(name)("
    }
    else {
      implementationText += "{\n\treturn [self object]->\(name)("
    }
    
    var first = true
    
    for arg in arguments {
      if first { first = false }
      else { implementationText += ", " }
      implementationText += "\(arg.name)"
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
  
  func addConstructor(headerText: inout String, implementationText: inout String) {
    let methodDeclaration = "-(id)init"
    headerText += methodDeclaration
    implementationText += methodDeclaration
    
    var first = true
    for (type, name) in arguments {
      if first {
        headerText += "With\(name.capitalized):(\(type)) \(name)"
        implementationText += "With\(name.capitalized):(\(type)) \(name)"
        first = false
      }
      else {
        headerText += " \(name):(\(type))\(name)"
        implementationText += " \(name):(\(type))\(name)"
      }
    }
    
    headerText += ";\n\n"
    
    implementationText += """
    {
      self = [super init];
      if(self){
        self.cppMembers = new CPPMembers(new T\(className)(
    """
    
    first = true
    for (_, name) in arguments {
      if first { first = false }
      else { implementationText += ", " }
      implementationText += "\(name)"
    }
    
    implementationText += """
      ));
      }
      return self;
    }\n\n
    """
  }
  
  /**
   Inserts base root class names found in return type and arguments of this method into provided set
   - Parameters:
      - classNames: set to which found ROOT classes will be inserted
   */
  func insertRootClassNames(classNames: inout Set<String>) {
    if let className = getRootClassName(fullName: returnType) {
      classNames.insert(className)
    }
    
    for arg in arguments {
      if let className = getRootClassName(fullName: arg.type) {
        classNames.insert(className)
      }
    }
  }
  
//------------------------------------------------------------------------
// Private methods
//------------------------------------------------------------------------
  
  private func getNameAndArgs(methodString: String) -> [String]? {
    var nameAndArgs = methodString.components(separatedBy: "(")
    nameAndArgs = nameAndArgs.filter { $0 != "" }
    return nameAndArgs.filter { !$0.starts(with: ")") }
  }
  
  private func getReturnTypeAndName(methodString: String) -> [String]? {
    if let nameAndArgs = getNameAndArgs(methodString: methodString) {
      var returnAndName = nameAndArgs[0].components(separatedBy: .whitespaces)
      returnAndName = returnAndName.filter { $0 != "" }
      return returnAndName
    }
    else {return nil }
  }
  
  private func getName(methodString: String) -> String? {
    if let returnAndName = getReturnTypeAndName(methodString: methodString) {
      return returnAndName.last
    }
    else {return nil }
  }
  
  private func getReturnType(methodString: String) -> String? {
    if let returnAndName = getReturnTypeAndName(methodString: methodString) {
      return returnAndName.secondToLast()
    }
    else {return nil }
  }
  
  private func getSpecifiers(methodString: String) -> [String]? {
    if let returnAndName = getReturnTypeAndName(methodString: methodString){
      return Array(returnAndName[0 ..< returnAndName.count-2])
    }
    else {return nil }
  }
  
  private func getArguments(methodString: String) -> [(String, String)]? {
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
    
    var argComponents = Array<(type: String, name: String)>()
    
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
      if argument.type.isEmpty && !argument.name.isEmpty {
        argument.type = argument.name
        argument.name = "unknown_name"
      }
      if argument.name.isEmpty {
        argument.name = "unknown_name"
      }
      argComponents.append(argument)
    }
    return argComponents
  }
  

  
}
