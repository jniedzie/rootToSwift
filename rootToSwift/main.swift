//
//  main.swift
//  rootToSwift
//
//  Created by Jeremi Niedziela on 08/08/2019.
//  Copyright © 2019 Jeremi Niedziela. All rights reserved.
//

import Foundation

let fileProcessor = FileProcessor()
let textProcessor = TextProcessor()

let rootIncludePath = "/Applications/root_v6.16.00/include"
let outputPath      = "/Users/jeremi/Library/Mobile Documents/com~apple~CloudDocs/Applications/swiftRoot/swiftRoot"

/**
 Generates header and implementation text of Objective-C++ binding for given ROOT class
 - Parameters:
     - className: ROOT class name to be analyzed
 - Return: tuple with class bindings and set of other ROOT classes that this class uses
 */
func getWrapperCodeForClass(className: String) -> (bindings: [ClassBinding], neededClasses:Set<String>) {
  
  var neededClasses = Set<String>()
  var classBindings = Array<ClassBinding>()
  let classesNamesAndText = fileProcessor.getClasses(fromRootHeader: className)
  
  for (className, classText) in classesNamesAndText {
    print("Preparing class \(className)")
    let publicMethods = fileProcessor.getPublicMethodsFromText(text: classText)
    
    let classBinding = ClassBinding(withName: className)
    classBinding.fill(withMethods: publicMethods, neededClasses: &neededClasses)
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
      
      for classBinding in addedClasses {
        alreadyImplementedClasses.insert(classBinding.name)
        classBinding.add(includes: missingIncludes)
        classBinding.write(toFile: outputPath)
      }
      
      for c in missingClasses {
        if !alreadyImplementedClasses.contains(c) { newNeededClasses.insert(c) }
      }
    }
    
    neededClasses = newNeededClasses
  }
}

func main() {
  let className       = "H2"
  
  // Generate bindings:
  generateAllNeededClasses(forClass: className)
  //getWrapperCodeForClass(className: "H2")
}

main()

