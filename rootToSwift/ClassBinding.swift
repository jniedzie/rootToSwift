//
//  MethodText.swift
//  rootToSwift
//
//  Created by Jeremi Niedziela on 02/09/2019.
//  Copyright © 2019 Jeremi Niedziela. All rights reserved.
//

import Foundation

class ClassBinding {
  required init(withName _name: String, header _header: String, implementation _impl: String){
    self.name = _name
    self.header = _header
    self.implementation = _impl
  }
  
  var name: String
  var header: String
  var implementation: String
}
