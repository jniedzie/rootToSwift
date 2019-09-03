//
//  TextProcessor.swift
//  rootToSwift
//
//  Created by Jeremi Niedziela on 30/08/2019.
//  Copyright © 2019 Jeremi Niedziela. All rights reserved.
//

import Foundation

class TextProcessor {
  /**
   Creates beginnig of the wrapper's header
   - Parameters:
   - className: Output class name ("S" prefix will be added to it)
   - Returns: String containing beginning of the header
   */
  func getHeaderBeginning(className: String) -> String {
    return """
    //  S\(className).h
    //  swiftRoot
    //
    //  Created by Jeremi Niedziela on \(getCurrentDate()).
    //  Copyright © 2019 Jeremi Niedziela. All rights reserved.
    
    #ifndef S\(className)_h
    #define S\(className)_h
    
    #import "SObject.h"
    
    @interface S\(className) : SObject
    
    """
  }
  
  /**
   Creates ending of the wrapper's header
   - Parameters:
   - className: Output class name ("S" prefix will be added to it)
   - Returns: String containing ending of the header
   */
  func getHeaderEnding(className: String) -> String {
    return """
    @end
    
    #endif /* S\(className)_h */
    """
  }
  
  /**
   Creates beginnig of the wrapper's implementation
   - Parameters:
     - className: Output class name ("S" prefix will be added to it)
   - Returns: String containing beginning of the header
   */
  func getImplementationBeginning(className: String) -> String {
    return """
    //  S\(className).m
    //  swiftRoot
    //
    //  Created by Jeremi Niedziela on \(getCurrentDate()).
    //  Copyright © 2019 Jeremi Niedziela. All rights reserved.
    
    #import "S\(className).h"
    #import "CPPMembers.mm"
    
    @implementation S\(className)
    
    - (id) initWithSObject:(SObject*) object
    {
      self = [super init];
      if(self){ self.cppMembers = object.cppMembers; }
      return self;
    }
    
    - (void)dealloc
    {
    
    }
    
    -(T\(className)*) object
    {
      return (T\(className)*)self.cppMembers->object;
    }\n
    """
  }
  
  /**
   Creates ending of the wrapper's implementation
   - Parameters:
     - className: Output class name ("S" prefix will be added to it)
   - Returns: String containing ending of the header
   */
  func getImplementationEnding() -> String {
    return """
    
    @end
    """
  }
}
