//
//  FaceTutorialViewController.swift
//  os
//
//  Created by Daniel Kuntz on 12/24/17.
//  Copyright © 2017 Daniel Kuntz. All rights reserved.
//

import UIKit

class FaceTutorialViewController: UIViewController {
    
    // MARK: - Outlets

    @IBOutlet weak var faceImage: UIImageView!
    
    // MARK: - Variables
    
    var faceNumber: Int = 3
    var increasing: Bool = true
    var range: ClosedRange<Int> = 1...6
    
    // MARK: - Setup Views
    
    override func viewDidLoad() {
        super.viewDidLoad()
        changeFace()
    }
    
    func changeFace() {
        let image = UIImage(named: "face_\(faceNumber)")
        faceImage.image = image
        
        faceNumber += increasing ? 1 : -1
        if faceNumber == range.upperBound {
            increasing = false
        } else if faceNumber == range.lowerBound {
            increasing = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4, execute: {
            self.changeFace()
        })
    }

    // MARK: - Actions
    
    @IBAction func gotItPressed(_ sender: Any) {
        UserDefaults.standard.sawTutorial()
        dismiss(animated: true, completion: nil)
    }
}
