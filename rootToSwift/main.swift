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

let rootIncludePath = "/usr/local/Cellar/root/6.22.00_1/include/root"
let outputPath      = "/Users/jeremi/Library/Mobile Documents/com~apple~CloudDocs/Applications/swiftRoot/swiftRoot"

func getIndentForLevel(_ level: Int) -> String {
  var indent = ""
  for _ in 0...level { indent += "\t" }
  return indent
}

/**
 Generates header and implementation text of Objective-C++ binding for given ROOT class
 - Parameters:
     - className: ROOT class name to be analyzed
 - Return: tuple with class bindings and set of other ROOT classes that this class uses
 */
func getWrapperCode(forClass name:String, withLevel level:Int) -> (bindings: [ClassBinding], neededClasses:Set<String>) {
  
  var neededClasses = Set<String>()
  var classBindings = Array<ClassBinding>()
  let classesNamesAndText = fileProcessor.getClasses(fromRootHeader: name)
  
  let indent = getIndentForLevel(level)
  print("\(indent)Preparing classes for header \(name): ", terminator:"")
  
  for (name, classText) in classesNamesAndText {
    
    print("\(name)", terminator:", ")
    
    let publicMethods = fileProcessor.getPublicMethodsFromText(text: classText)
    let publicEnums = fileProcessor.getPublicEnumsFromText(text: classText)
    
    
    
    let classBinding = ClassBinding(withName: name)
    classBinding.fill(withMethods: publicMethods, enums: publicEnums, neededClasses: &neededClasses)
    classBindings.append(classBinding)
  }
  print("")
  return (classBindings, neededClasses)
}


func getIncludesTextForClasses(_ missingClasses: Set<String>, className: String) -> String {
  var missingIncludes = "#import \"SObject.h\"\n"
  for missingClass in missingClasses {
    if missingClass != className && missingClass != "Object" {
      missingIncludes += "#import \"S\(missingClass).h\"\n"
    }
  }
  return missingIncludes
}

/**
 Recursively creates bindings for specified ROOT class and all classes used by this one
 */

func generateAllNeededClasses(forClass className: String, alreadyImplementedClasses: inout Set<String>, level: Int = 0) {
  
  if className == "VirtualIsAProxy" || className == "ArrayI" {
    
  }
  
  if className == "DataType"{
    
  }
  
  if className == "String"{
    
  }
  
  
  
  if alreadyImplementedClasses.contains(trickyHeaders[className] ?? className) { return }
  
  let (addedClasses, missingClasses) = getWrapperCode(forClass: className, withLevel: level)
  
  if missingClasses.contains("Dictionary::void"){
    
  }
  
  let missingIncludes = getIncludesTextForClasses(missingClasses, className: className)
  
  for classBinding in addedClasses {
    alreadyImplementedClasses.insert(classBinding.name)
    classBinding.addIncludes(missingIncludes)
    classBinding.writeToFile(outputPath)
  }
  
  for missingClass in missingClasses {
    if !alreadyImplementedClasses.contains(missingClass) {
      generateAllNeededClasses(forClass: missingClass, alreadyImplementedClasses: &alreadyImplementedClasses, level: level+1)
    }
  }
}

func main() {
  let className = "File"
  
  // Generate bindings:
  var implementedClasses: Set = ["Object"]
  generateAllNeededClasses(forClass: className, alreadyImplementedClasses: &implementedClasses)
  //getWrapperCodeForClass(className: "H2")
}

main()

