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
let className       = "H2"

let fileProcessor = FileProcessor()

// Create Objective-C++ header and imlpementation files for requested ROOT class
let currentDate = getCurrentDate()
var headerText = fileProcessor.getHeaderBeginning(className: className, currentDate: currentDate)
var implementationText = fileProcessor.getImplementationBeginning(className: className, currentDate: currentDate)

// Get public methods from ROOT header
var text = fileProcessor.getContentsOfFile(path: "\(rootIncludePath)/T\(className).h")
let publicMethods = fileProcessor.getPublicMethods(text: text)

// Fill in header and implementation files with public ROOT class methods
for method in publicMethods {
  guard let methodPieces = Method(method: method)
    else{
      print("Could not translate string:\n\(method)\n to a method object")
      continue;
  }
  let methodDeclaration = "-(\(methodPieces.returnType)) \(methodPieces.name)"
  
  headerText += methodDeclaration
  implementationText += methodDeclaration
  
  methodPieces.addArgumentsList(headerText: &headerText, implementationText: &implementationText)
  methodPieces.addMethodImplementation(implementationText: &implementationText)
  headerText += ";\n\n"
}

// Add endings of header and implementation files
headerText += fileProcessor.getHeaderEnding(className: className)
implementationText += fileProcessor.getImplementationEnding()

// Save files
fileProcessor.writeText(text: headerText, filePath: "\(outputPath)/S\(className).h")
fileProcessor.writeText(text: implementationText, filePath: "\(outputPath)/S\(className).mm")
