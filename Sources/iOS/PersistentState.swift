//
//  PersistentState.swift
//  Wasmic
//
//  Created by kateinoigakukun on 2021/04/11.
//

import Foundation

class PersistentState {
    private let defaults = UserDefaults.standard
    var isWelcomeDone: Bool {
        get { defaults.bool(forKey: #function) }
        set { defaults.setValue(newValue, forKey: #function) }
    }
}
