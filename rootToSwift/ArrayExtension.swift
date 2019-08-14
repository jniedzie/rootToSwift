//
//  ArrayExtension.swift
//  rootToSwift
//
//  Created by Jeremi Niedziela on 14/08/2019.
//  Copyright © 2019 Jeremi Niedziela. All rights reserved.
//

import Foundation

extension Array {
  func secondToLast() -> Element? {
    if self.count < 2 {
      return nil
    }
    return self[self.count-2]
  }
}
