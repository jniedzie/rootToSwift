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
let className = "H2"

let fileProcessor = FileProcessor()
let textProcessor = TextProcessor()

/**
 Generates header and implementation text of Objective-C++ binding for given ROOT class
 - Parameters:
 - className: ROOT class name to be analyzed
 - Return: tuple with header and implementation strings and other ROOT classes that this class uses
 */
func getWrapperCodeForClass(className: String)
  -> (classes: [(name: String, header: String, implementation: String)], neededClasses:Set<String>) {
    // Get classes declarations from ROOT header
    let rootClassPath       = "\(rootIncludePath)/T\(className).h"
    let inputText           = fileProcessor.getContentsOfFile(path: rootClassPath)
    let classesNamesAndText = fileProcessor.getClassesFromText(text: inputText)
    
    var neededClasses = Set<String>()
    var classes = Array<(name: String, header: String, implementation: String)>()
    
    // Get header and implementation for each class
    for (className, classText) in classesNamesAndText {
      print("Preparing class \(className)")
      let publicMethods = fileProcessor.getPublicMethodsFromText(text: classText)
      
      // Create Objective-C++ header and imlpementation files for requested ROOT class
      var headerText = textProcessor.getHeaderBeginning(className: className)
      var implementationText = textProcessor.getImplementationBeginning(className: className)
      
      var alreadyAddedMethods = Set<MethodComponents>()
      
      // Fill in header and implementation files with public ROOT class methods
      for methodText in publicMethods {
        guard let methodPieces = MethodComponents(methodString: methodText)
          else{
            print("Could not translate string:\n\(methodText)\n to a method object")
            continue;
        }
        var isAlreadyIn = false
        for alreadyIn in alreadyAddedMethods {
          if alreadyIn==methodPieces {
            isAlreadyIn = true
            break
          }
        }
        if isAlreadyIn { continue }
        alreadyAddedMethods.insert(methodPieces)
        
        methodPieces.insertRootClassNames(classNames: &neededClasses)
        
        if methodPieces.isConstructor {
          methodPieces.addConstructor(headerText: &headerText, implementationText: &implementationText)
        }
        else{
          methodPieces.addMethod(headerText: &headerText, implementationText: &implementationText)
        }
      }
      
      // Add endings of header and implementation files
      headerText += textProcessor.getHeaderEnding(className: className)
      implementationText += textProcessor.getImplementationEnding()
      
      classes.append((name: className, header: headerText, implementation: implementationText))
    }
    
    return (classes: classes, neededClasses: neededClasses)
}

/**
 Recursively creates bindings for specified ROOT class and all classes used by this one
 */
func generateAllNeededClassesForClass(className: String) {
  var alreadyImplementedClasses: Set = ["Object"]
  var neededClasses: Set = ["H2"]
  
  while neededClasses.count != 0 {
    var newNeededClasses = Set<String>()
    
    for className in neededClasses {
      if alreadyImplementedClasses.contains(className) { continue }
      let (addedClasses, missingClasses) = getWrapperCodeForClass(className: className)
      
      for (name, headerText, implementationText) in addedClasses {
        alreadyImplementedClasses.insert(name)
        fileProcessor.writeText(text: headerText, filePath: "\(outputPath)/S\(className).h")
        fileProcessor.writeText(text: implementationText, filePath: "\(outputPath)/S\(className).mm")
      }
      
      for c in missingClasses {
        if !alreadyImplementedClasses.contains(c) { newNeededClasses.insert(c) }
      }
      // Save files
      
    }
    
    neededClasses = newNeededClasses
  }
}

// Generate bindings:
generateAllNeededClassesForClass(className: className)
//getWrapperCodeForClass(className: "H2")
