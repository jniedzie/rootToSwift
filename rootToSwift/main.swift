//
//  main.swift
//  rootToSwift
//
//  Created by Jeremi Niedziela on 08/08/2019.
//  Copyright © 2019 Jeremi Niedziela. All rights reserved.
//

import Foundation

let rootIncludePath = "/Applications/root_v6.16.00/include"
let outputPath      = "/Users/jeremi/Library/Mobile Documents/com~apple~CloudDocs/Applications/swiftRoot/swiftRoot"
let className       = "Canvas"

let fileProcessor = FileProcessor()

var text = fileProcessor.getContentsOfFile(path: "\(rootIncludePath)/T\(className).h")

let publicMethods = fileProcessor.getPublicMethods(text: text)

let currentDate:String = "\(Calendar.current.component(.day, from: Date()))/\(Calendar.current.component(.month, from: Date()))/\(Calendar.current.component(.year, from: Date()))"

var headerText = fileProcessor.getHeaderBeginning(className: className, currentDate: currentDate)
var implementationText = fileProcessor.getImplementationBeginning(className: className, currentDate: currentDate)

print("Public methods:")
for method in publicMethods {
  do {
    let methodPieces = try fileProcessor.getMethodPieces(method: method)

    headerText += "-(\(methodPieces.returnType)) \(methodPieces.name)"
    implementationText += "-(\(methodPieces.returnType)) \(methodPieces.name)"
    
    if methodPieces.arguments.count > 0 {
      headerText += ":"
      implementationText += ":"
      
      var first = true
      for arg in methodPieces.arguments {
        var argName = arg.name
        if let nameRange = arg.name.range(of: #"(\w)*"#, options: .regularExpression) {
          argName = String(arg.name[nameRange])
        }
        
        if first {
          first = false
          headerText += "(\(arg.type)) \(argName) "
          implementationText += "(\(arg.type)) \(arg.name) "
        }
        else {
          headerText += "\(argName):(\(arg.type)) \(argName) "
          implementationText += "\(argName):(\(arg.type)) \(arg.name) "
        }
      }
    }
    headerText += ";\n\n"
    
    if methodPieces.returnType == "SObject*" {
      implementationText += """
      {
        TObject *obj = [self object]->\(methodPieces.name)(
      """
    }
    else {
      implementationText += """
      {
        return [self object]->\(methodPieces.name)(
      """
    }
      
    if methodPieces.arguments.count > 0 {
      var first = true
      
      for arg in methodPieces.arguments {
        if first { first = false }
        else { implementationText += ", " }
        implementationText += "\(arg.name)"
      }
    }
    
    if methodPieces.returnType == "SObject*" {
      implementationText += """
        );
        CPPMembers *members = new CPPMembers(obj);
        return [[SObject alloc] initWithObject:members];
        }\n\n
      """
    }
    else {
      implementationText += """
      );
      }\n\n
      """
    }
  }
  catch {
    print("Could not get method pieces for method: \(method)")
    continue
  }
}

headerText += fileProcessor.getHeaderEnding(className: className)
implementationText += fileProcessor.getImplementationEnding()

fileProcessor.writeText(text: headerText, filePath: "\(outputPath)/S\(className).h")
fileProcessor.writeText(text: implementationText, filePath: "\(outputPath)/S\(className).mm")
