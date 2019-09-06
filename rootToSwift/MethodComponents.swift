//
//  Method.swift
//  rootToSwift
//
//  Created by Jeremi Niedziela on 15/08/2019.
//  Copyright © 2019 Jeremi Niedziela. All rights reserved.
//

import Foundation

class MethodComponents: NSObject {
  // MARK: - Properties
  var name: String
  var returnType: String
  var specifiers: [String]
  var arguments: [(type:String, name: String?)]
  var isConstructor: Bool
  
  // MARK: - Constructor
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
      if specifiers.contains("const"){
        self.returnType = "const "+self.returnType
        self.specifiers.removeAll(where: {$0 == "const"})
      }
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
    
    if self.returnType.first == "T" { self.returnType.replaceCharacter(atIndex: 0, with: "S") }
    
    for i in self.arguments.indices {
      if self.arguments[i].type.first == "T" { self.arguments[i].type.replaceCharacter(atIndex: 0, with: "S") }
    }
    
  }
  
  // MARK: - Comparison operator
  
  /// Comparison operator
  static func ==(lhs: MethodComponents, rhs: MethodComponents) -> Bool{
    
    if lhs.name != rhs.name { return false }
    if lhs.returnType != rhs.returnType { return false }
    if lhs.isConstructor != rhs.isConstructor { return false }

    if !lhs.specifiers.containsSameElements(as: rhs.specifiers) { return false }
    
    func contains(a:[(String, String?)], b:(String, String?)) -> Bool {
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
  
  // MARK: - Public methods
  
  
  /**
   Adds objective-C declaration and implementation of this method to `headerText` and `implementationText` resoectively
  - Parameters:
      - header: string to which header-style arguments will be added
      - implementation: string to which implementation-style arguments will be added
  */
  func addMethod(toHeader header: inout String,
                 andImplementation implementation: inout String,
                 labelFirstArgument: Bool,
                 commentOut: Bool = false) {
    
    if commentOut {
      header += "/*\n"
      implementation += "/*\n"
    }
    let methodDeclaration = isConstructor ? "-(id)init" : "-(\(returnType)) \(name)"
    header += methodDeclaration
    implementation += methodDeclaration
    
    var first = true
    for arg in arguments {
      guard let name: String = arg.name else { continue }
      
      let type = arg.type
      let nameNoDefault = name.strippingDefaultValue()
      
      if first {
        if isConstructor || labelFirstArgument {
          header += "With\(name.capitalized):(\(type)) \(name) "
          implementation += "With\(name.capitalized):(\(type)) \(name) "
        }
        else {
          header += ":(\(type)) \(nameNoDefault) "
          implementation += ":(\(type)) \(name) "
        }
        first = false
      }
      else {
        header += "\(nameNoDefault):(\(type)) \(nameNoDefault) "
        implementation += "\(nameNoDefault):(\(type)) \(name) "
      }
    }
    if arguments.isEmpty && labelFirstArgument {
      header          += specifiers.contains("const") ? "Const " : "NonConst "
      implementation  += specifiers.contains("const") ? "Const " : "NonConst "
    }
    
    header += ";\n"
    addMethod(toImplementation: &implementation)
    
    if commentOut {
      header += "*/\n"
      implementation += "*/\n"
    }
  }
  
  /**
   Adds method/constructor body to the provided `implementation` string.
   */
  private func addMethod(toImplementation implementation: inout String) {
    
    if isConstructor {
      implementation += """
      {
        self = [super init];
        if(self){
          self.cppMembers = new CPPMembers(new \(name)(
      """
    }
    else if returnType == "SObject*" {
      implementation += "{\n\tTObject *tobj = [self object]->\(name)("
    }
    else {
      implementation += "{\n\treturn [self object]->\(name)("
    }
    
    var first = true
    
    if isCopyConstuctor() {
      implementation += "*[&\(arguments.first!.name ?? "") object]"
    }
    else{
      for (argType, argName) in arguments {
        guard let arg = argName else { continue }
        
        if first { first = false }
        else { implementation += ", " }
        
        if argType.contains("SObject")  { implementation += "(TObject*)[\(arg) get]" }
        else                            { implementation += "\(arg)" }
      }
    }
      
    if isConstructor {
      implementation += """
      ));
        }
        return self;
      }\n
      """
    }
    else if returnType == "SObject*" {
      implementation += """
      );
        CPPMembers *members = new CPPMembers(tobj);
        return [[SObject alloc] initWithObject:members];
      }\n
      """
    }
    else {
      implementation += ");\n}\n"
    }
  }
  
  /**
   Inserts base root class names found in return type and arguments of this method into provided set
   - Parameters:
      - withNames: set to which found ROOT classes will be inserted
   */
  func insertRootClasses(withNames names: inout Set<String>) {
    if let name = getRootClassName(fullName: returnType) {
      if !name.isEmpty { names.insert(name) }
    }
    
    for arg in arguments {
      if let name = getRootClassName(fullName: arg.type) {
        if !name.isEmpty { names.insert(name) }
      }
    }
  }
  
  /// Checks if this method is an overloaded operator
  func isOperator() -> Bool {
    let operatorPattern = #"operator"#
    if name.range(of: operatorPattern, options: .regularExpression) != nil { return true }
    return false
  }
  
  // MARK: - Private methods
  /**
   Separates provided string into method name and method's arguments
   */
  private func getNameAndArgs(methodString: String) -> [String]? {
    var startIndex: String.Index?
    var endIndex: String.Index?
    
    for index in methodString.indices {
      if startIndex != nil, endIndex != nil { break }
      
      if startIndex==nil, methodString[index]=="(" { startIndex = index }
      if endIndex==nil, methodString[index]==")" { endIndex = index }
    }
    
    if startIndex==nil || endIndex==nil {
      print("Could not find method name and arguments in method:\(methodString)")
      return nil
    }
    
    var nameAndArgs = [methodString[methodString.startIndex..<startIndex!]]
    
    if methodString.index(startIndex!, offsetBy: 1) < endIndex! {
       nameAndArgs.append(methodString[methodString.index(startIndex!, offsetBy: 1)..<endIndex!])
    }
    
    nameAndArgs = nameAndArgs.filter { !$0.isEmpty }
    
    var nameAndArgsString = [String]()
    for na in nameAndArgs { nameAndArgsString.append(String(na)) }
    
    return nameAndArgsString
  }
  
  private func getReturnTypeAndName(methodString: String) -> [String]? {
    if let nameAndArgs = getNameAndArgs(methodString: methodString) {
      var returnAndName = nameAndArgs[0].components(separatedBy: .whitespaces)
      if returnAndName.contains("struct") { return nil }
      returnAndName = returnAndName.filter { !$0.isEmpty }
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
    if var returnAndName = getReturnTypeAndName(methodString: methodString) {
      var returnType = returnAndName[0..<returnAndName.count-1]
      returnType.removeAll(where: {$0 == "virtual"})
      
      if returnType.isEmpty { return nil }
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
  
  private func getArguments(methodString: String) -> [(String, String?)]? {
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
    
    var argComponents = Array<(type: String, name: String?)>()
    
    for arg in args {
      argComponents.append(breakArgumentIntoComponents(arg: arg))
    }
    return argComponents
  }
  
  /**
   Breaks string containing argument of a method into it's type and name
   - Return: In case of anonymous parameter, name is nil
   */
  private func breakArgumentIntoComponents(arg: String) -> (type: String, name: String?) {
    var argComps = arg.components(separatedBy: .whitespaces)
    argComps = argComps.filter { $0.range(of: #"(\s)*"#, options: .regularExpression) != nil && !$0.isEmpty }
    
    var argType = ""
    for type in argComps[0 ..< argComps.count-1] {
      argType += "\(type) "
    }
    if !argType.isEmpty { argType.removeLast() }
    
    var argument:(type: String, name: String?) = (argType, nil)
    
    var name = argComps.last!
    
    if name.range(of: #"[*|&]+[\w]*"#, options: .regularExpression) != nil {
      let starsRange = name.range(of: #"[*|&]+"#, options: .regularExpression)!
      argument.type += name[starsRange]
      name.removeSubrange(starsRange)
    }
    if !name.isEmpty {
      if argument.type.isEmpty  { argument.type = name }
      else                      { argument.name = name }
    }
    return argument
  }
  
  private func isCopyConstuctor() -> Bool {
    if arguments.count == 1 {
      if let arg = arguments.first {
        let type = arg.type
        let baseName = name.removingFirstCharacter()
        
        if type.contains("const") && type.contains("&") && type.contains(baseName) {
          return true
        }
      }
    }
    return false
  }
}
