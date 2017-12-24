//
//  UserDefaults+osUserDefaults.swift
//  Facesynth
//
//  Created by Daniel Kuntz on 4/4/17.
//  Copyright © 2017 Daniel Kuntz. All rights reserved.
//

import Foundation

extension UserDefaults {
    
    func hasSeenTutorial() -> Bool {
        return bool(forKey: "hasSeenTutorial")
    }
    
    func sawTutorial() {
        set(true, forKey: "hasSeenTutorial")
    }
    
}
