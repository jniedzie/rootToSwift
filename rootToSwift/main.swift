//
//  main.swift
//  rootToSwift
//
//  Created by Jeremi Niedziela on 08/08/2019.
//  Copyright © 2019 Jeremi Niedziela. All rights reserved.
//

import Foundation

let className = "Application"
let fileProcessor = FileProcessor()

var text = fileProcessor.getContentsOfFile(path: "/Applications/root_v6.16.00/include/T\(className).h")

let publicMethods = fileProcessor.getPublicMethods(text: text)

let currentDate:String = "\(Calendar.current.component(.day, from: Date()))/\(Calendar.current.component(.month, from: Date()))/\(Calendar.current.component(.year, from: Date()))"

var headerText = fileProcessor.getHeaderBeginning(className: className)

print("Public methods:")
for method in publicMethods {
  do {
    let methodPieces = try fileProcessor.getMethodPieces(method: method)

    headerText += "-(\(methodPieces.returnType)) \(methodPieces.name)"
    
    if methodPieces.arguments.count > 0 {
      headerText += ":"
      for arg in methodPieces.arguments {
        headerText += "(\(arg.type)) \(arg.name) "
      }
    }
    headerText += ";\n\n"
  }
  catch {
    print("Could not get method pieces for method: \(method)")
    continue
  }
}



headerText += fileProcessor.getHeaderEnding(className: className)

fileProcessor.writeText(text: headerText, filePath: "/Users/Jeremi/Desktop/S\(className).h")
