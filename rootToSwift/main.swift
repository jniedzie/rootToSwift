//
//  main.swift
//  rootToSwift
//
//  Created by Jeremi Niedziela on 08/08/2019.
//  Copyright © 2019 Jeremi Niedziela. All rights reserved.
//

import Foundation

let fileProcessor = FileProcessor()

var text = fileProcessor.getContentsOfFile(path: "/Applications/root_v6.16.00/include/TApplication.h")

let publicMethods = fileProcessor.getPublicMethods(text: text)


print("Public methods:")
for method in publicMethods {
  do {
    let methodPieces = try fileProcessor.getMethodPieces(method: method)
    print("\(methodPieces)")
  }
  catch {
    print("Could not get method pieces for method: \(method)")
    continue
  }
}



