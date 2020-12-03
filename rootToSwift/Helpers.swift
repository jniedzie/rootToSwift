//
//  Helpers.swift
//  rootToSwift
//
//  Created by Jeremi Niedziela on 15/08/2019.
//  Copyright © 2019 Jeremi Niedziela. All rights reserved.
//

import Foundation

/// Dictionary mapping custom root types to standard C types
let rootTypes = [
  "Char_t"       : "char",
  "UChar_t"      : "unsigned char",
  "Short_t"      : "short",
  "Short_t*"     : "short*",
  "Short_t&"     : "short&",
  "UShort_t"     : "unsigned short",
  "Int_t"        : "int",
  "UInt_t"       : "unsigned int",
  "Uint"         : "unsigned int",
  "Seek_t"       : "int",
  "Long_t"       : "long",
  "ULong_t"      : "unsigned long",
  "Float_t"      : "double",
  "Float16_t"    : "double",
  "Double_t"     : "double",
  "Double32_t"   : "double",
  "LongDouble_t" : "long double",
  "Text_t"       : "char",
  "Bool_t"       : "bool",
  "Byte_t"       : "unsigned char",
  "Version_t"    : "short",
  "Option_t"     : "const char",
  "Tsiz_t"       : "int",
  "Ssiz_t"       : "int",
  "Ssiz_t*"      : "int*",
  "Ssiz_t&"      : "int&",
  "siz_t"        : "int",
  "Real_t"       : "double",
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
  "Angle_t"      : "double",
  "Size_t"       : "double",
  
  "TObjLinkPtr_t" : "TObjLink*",
  "DeclId_t"      : "const void*",
  "TDictionary::DeclId_t" : "const void*",
  
//  Cheating with these ones:
  "TypedefInfo_t"     : "void*",
  "TypedefInfo_t*"    : "void*",
  "ypedefInfo_t"      : "void*",
  "ShowMembersFunc_t" : "void*",
]


let trickyHeaders = [
  "GMainFrame" : "Frame",
  "ErrorLock" : "Collection",
  "DeclNameRegistry" : "Class",
  
]

/// Returns current date in dd/m/yyyy format as a string
func getCurrentDate() -> String {
  return """
  \(Calendar.current.component(.day,    from: Date()))/\
  \(Calendar.current.component(.month,  from: Date()))/\
  \(Calendar.current.component(.year,   from: Date()))
  """
}

/// Extracts base class name (removing prefix) from a type
func getRootClassName(fullName: String) -> String? {
  if fullName.range(of: #"S[\w]*"#, options: .regularExpression) == nil { return nil }
  if !fullName.starts(with: "S") { return nil }
  
  var className = fullName
  className.removeOccurrences(of: "const ")
  className.removeOccurrences(of: " ")
  className.removeOccurrences(of: "&")
  className.removeOccurrences(of: "*")
  className.removeFirst()
  return String(className)
}
