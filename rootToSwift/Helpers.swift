//
//  Helpers.swift
//  rootToSwift
//
//  Created by Jeremi Niedziela on 15/08/2019.
//  Copyright © 2019 Jeremi Niedziela. All rights reserved.
//

import Foundation

enum RSError: Error {
  /// noArgumentList Provided Method object's arguments field is nil
  case noArgumentList
  /// noReturnOrName Provided method string didn't contain name or return type
  case noReturnOrName
}

/// Dictionary mapping custom root types to standard C types
let rootTypes = [
  "Char_t"       : "char",
  "UChar_t"      : "unsigned char",
  "Short_t"      : "short",
  "UShort_t"     : "unsigned short",
  "Int_t"        : "int",
  "UInt_t"       : "unsigned int",
  "Uint"         : "unsigned int",
  "Seek_t"       : "int",
  "Long_t"       : "long",
  "ULong_t"      : "unsigned long",
  "Float_t"      : "float",
  "Float16_t"    : "float",
  "Double_t"     : "double",
  "Double32_t"   : "double",
  "LongDouble_t" : "long double",
  "Text_t"       : "char",
  "Bool_t"       : "bool",
  "Byte_t"       : "unsigned char",
  "Version_t"    : "short",
  "Option_t"     : "const char",
  "Ssiz_t"       : "int",
  "Real_t"       : "float",
  "Long64_t"     : "long long",
  "ULong64_t"    : "unsigned long long",
  "Axis_t"       : "double",
  "Stat_t"       : "double",
  "Font_t"       : "short",
  "Style_t"      : "short",
  "Marker_t"     : "short",
  "Width_t"      : "short",
  "Color_t"      : "short",
  "SCoord_t"     : "short",
  "Coord_t"      : "double",
  "Angle_t"      : "float",
  "Size_t"       : "float",
]

/**
 Returns current date in dd/m/yyyy format as a string
 */
func getCurrentDate() -> String {
  return "\(Calendar.current.component(.day, from: Date()))/\(Calendar.current.component(.month, from: Date()))/\(Calendar.current.component(.year, from: Date()))"
}

/**
 Removes what looks like default arguments declaration in C from the provided string
 */
func stripDefaultValue(name:inout String) {
  if let nameRange = name.range(of: #"(\w)*"#, options: .regularExpression) {
    name = String(name[nameRange])
  }
}

/**
 Extracts base class name (removing prefix) from a type
 */
func getRootClassName(fullName: String) -> String? {
  if fullName.range(of: #"S[\w]*"#, options: .regularExpression) != nil {
    var className = fullName
    className = className.replacingOccurrences(of: "const ", with: "")
    className = className.replacingOccurrences(of: " ", with: "")
    className = className.replacingOccurrences(of: "&", with: "")
    className = className.replacingOccurrences(of: "*", with: "")
    className.removeFirst()
    return String(className)
  }
  return nil
}


