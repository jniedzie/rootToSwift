//
//  MethodText.swift
//  rootToSwift
//
//  Created by Jeremi Niedziela on 02/09/2019.
//  Copyright © 2019 Jeremi Niedziela. All rights reserved.
//

import Foundation

class ClassBinding {
  required init(withName _name: String, header _header: String = "", implementation _impl: String = ""){
    self.name = _name
    self.header = _header
    self.implementation = _impl
  }
  
  var name: String
  var header: String
  var implementation: String
  
  /**
   Fills in header and implementation files with methods. Inserts names of other classes needed by
   this class to `neededClasses` set. In case of duplicates, method will be added only once.
   */
  func fill(withMethods methods: [String], neededClasses: inout Set<String>){
    
    var alreadyAddedMethods = Set<MethodComponents>()
    
    header = textProcessor.getHeaderBeginning(className: name)
    implementation = textProcessor.getImplementationBeginning(className: name)
    
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
    
    header += textProcessor.getHeaderEnding(className: name)
    implementation += textProcessor.getImplementationEnding()
  }
  
  
  /// Adds provided includes in the include section of the header
  func add(includes: String) {
    header = header.replacingOccurrences(of: "#import \"SObject.h\"", with: includes)
  }
  
  func write(toFile path: String) {
    fileProcessor.writeText(text: header, filePath: "\(path)/S\(name).h")
    fileProcessor.writeText(text: implementation, filePath: "\(path)/S\(name).mm")
  }
}
