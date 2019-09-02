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
let textProcessor = TextProcessor()

/**
 Fills in header and implementation files with methods. Inserts names of other classes needed by
 this class to `neededClasses` set. In case of duplicates, method will be added only once.
 */
func fill(header: inout String, implementation: inout String,
          withMethods methods: [String],
          neededClasses: inout Set<String>){
  
  var alreadyAddedMethods = Set<MethodComponents>()
  
  header = textProcessor.getHeaderBeginning(className: className)
  implementation = textProcessor.getImplementationBeginning(className: className)
  
  for methodText in methods {
    guard let methodPieces = MethodComponents(methodString: methodText)
      else{
        print("Could not translate string:\n\(methodText)\n to a method object")
        continue;
    }
    if alreadyAddedMethods.contains(where: {$0 == methodPieces}) { continue }
    alreadyAddedMethods.insert(methodPieces)
    
    methodPieces.insertRootClasses(withNames: &neededClasses)
    methodPieces.addMethod(toHeader: &header, andImplementation: &implementation)
  }
  
  header += textProcessor.getHeaderEnding(className: className)
  implementation += textProcessor.getImplementationEnding()
}

/**
 Generates header and implementation text of Objective-C++ binding for given ROOT class
 - Parameters:
     - className: ROOT class name to be analyzed
 - Return: tuple with header and implementation strings and other ROOT classes that this class uses
 */
func getWrapperCodeForClass(className: String) -> (bindings: [ClassBinding], neededClasses:Set<String>) {
  
  var neededClasses = Set<String>()
  var classBindings = Array<ClassBinding>()
  let classesNamesAndText = fileProcessor.getClasses(fromRootHeader: className)
  
  // Get header and implementation for each class
  for (className, classText) in classesNamesAndText {
    print("Preparing class \(className)")
    let publicMethods = fileProcessor.getPublicMethodsFromText(text: classText)
    
    var header = ""
    var implementation = ""
    
    fill(header: &header,
         implementation: &implementation,
         withMethods: publicMethods,
         neededClasses: &neededClasses)
    
    let classBinding = ClassBinding(withName: className,
                                    header: header,
                                    implementation: implementation)
    classBindings.append(classBinding)
  }
  return (classBindings, neededClasses)
}

/**
 Recursively creates bindings for specified ROOT class and all classes used by this one
 */
func generateAllNeededClasses(forClass className: String) {
  var alreadyImplementedClasses: Set = ["Object"]
  var neededClasses: Set = ["H2"]
  
  while neededClasses.count != 0 {
    var newNeededClasses = Set<String>()
    
    for className in neededClasses {
      if alreadyImplementedClasses.contains(className) { continue }
      let (addedClasses, missingClasses) = getWrapperCodeForClass(className: className)
      
      var missingIncludes = "#import \"SObject.h\"\n"
      for missingClass in missingClasses { missingIncludes += "#import \"S\(missingClass).h\"\n" }
      
      for bindingText in addedClasses {
        let name = bindingText.name
        alreadyImplementedClasses.insert(name)
        let headerTextWithIncludes = bindingText.header.replacingOccurrences(of: "#import \"SObject.h\"",
                                                                             with: missingIncludes)
        
        fileProcessor.writeText(text: headerTextWithIncludes, filePath: "\(outputPath)/S\(name).h")
        fileProcessor.writeText(text: bindingText.implementation, filePath: "\(outputPath)/S\(name).mm")
      }
      
      for c in missingClasses {
        if !alreadyImplementedClasses.contains(c) { newNeededClasses.insert(c) }
      }
    }
    
    neededClasses = newNeededClasses
  }
}

// Generate bindings:
generateAllNeededClasses(forClass: className)
//getWrapperCodeForClass(className: "H2")
