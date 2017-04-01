//
//  MainViewController.swift
//  os
//
//  Created by Daniel Kuntz on 4/1/17.
//  Copyright © 2017 Daniel Kuntz. All rights reserved.
//

import UIKit
import AudioKit

public class MainViewController: UIViewController, UIGestureRecognizerDelegate {
    
    // MARK: - Properties
    
    var waveform: WaveformView!
    var oscillator: AKFMOscillator = AKFMOscillator()
    
    var startingFrequency: Double = 220
    
    // MARK: - Setup
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        setupOscillator()
        setupPanGestureRecognizer()
    }
    
    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        addWaveform()
    }
    
    func setupOscillator() {
        oscillator.amplitude = 1
        oscillator.rampTime = 0.2
        oscillator.modulationIndex = 0
        oscillator.baseFrequency = startingFrequency
        
        let reverb = AKReverb(oscillator, dryWetMix: 0.5)
        
        AudioKit.output = reverb
        AudioKit.start()
    }
    
    func setupPanGestureRecognizer() {
        let panGR = ImmediatePanGestureRecognizer(target: self, action: #selector(viewPanned(_:)))
        panGR.delegate = self
        view.addGestureRecognizer(panGR)
        
        let tapGR = UILongPressGestureRecognizer(target: self, action: #selector(viewTouched(_:)))
        tapGR.minimumPressDuration = 0
        tapGR.delegate = self
        view.addGestureRecognizer(tapGR)
        
        let forceGR = ForceTouchGestureRecognizer(target: self, action: #selector(viewForceTouched(_:)))
        forceGR.delegate = self
        view.addGestureRecognizer(forceGR)
    }
    
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    func addWaveform() {
        let waveformHeight: CGFloat = 400
        let centerY = view.bounds.height / 2 - waveformHeight / 2
        let frame = CGRect(x: 0, y: centerY, width: view.bounds.width, height: waveformHeight)
        
        waveform = WaveformView(frame: frame)
        view.addSubview(waveform)
        view.backgroundColor = .black
    }
    
    // MARK: - Pan Gesture Handler
    
    func viewTouched(_ gestureRecognizer: UILongPressGestureRecognizer) {
        switch gestureRecognizer.state {
        case .began:
            self.beganPanning(gestureRecognizer)
        case .ended, .cancelled:
            self.stoppedPanning()
        default:
            break
        }
    }
    
    func viewPanned(_ gestureRecognizer: UIPanGestureRecognizer) {
        DispatchQueue.global(qos: .background).async {
            if gestureRecognizer.state == .changed {
                self.continuedPanning(gestureRecognizer)
            }
        }
    }
    
    func viewForceTouched(_ gestureRecognizer: ForceTouchGestureRecognizer) {
        DispatchQueue.global(qos: .background).async {
            self.oscillator.carrierMultiplier = Double(gestureRecognizer.force) + 1
        }
    }
    
    func beganPanning(_ gestureRecognizer: UIGestureRecognizer) {
        startingFrequency = oscillator.baseFrequency
        oscillator.play()
        
        oscillator.rampTime = 0
        let location = gestureRecognizer.location(in: view)
        let modulation = Double(location.x * 0.16) - 30
        let newModulation = modulation.clamped(to: -30...30)
        self.oscillator.modulationIndex = newModulation
        oscillator.rampTime = 0.2
        
        DispatchQueue.main.async {
            let frequency = CGFloat(self.oscillator.baseFrequency)
            let modulation = CGFloat(self.oscillator.modulationIndex)
            
            self.waveform.startNote()
            self.waveform.update(withRealFrequency: frequency, modulation: modulation)
        }
    }
    
    func continuedPanning(_ gestureRecognizer: UIPanGestureRecognizer) {
        updateOscillator(gestureRecognizer)
        
        DispatchQueue.main.async {
            let frequency = CGFloat(self.oscillator.baseFrequency)
            let modulation = CGFloat(self.oscillator.modulationIndex)
            self.waveform.update(withRealFrequency: frequency, modulation: modulation)
        }
    }
    
    func stoppedPanning() {
        oscillator.stop()
        
        DispatchQueue.main.async {
            self.waveform.stopNote()
        }
    }
    
    // MARK: - Oscillator Updates
    
    func updateOscillator(_ gestureRecognizer: UIPanGestureRecognizer) {
        let location = gestureRecognizer.location(in: view)
        let translation = gestureRecognizer.translation(in: view)
        
        let changeInFrequency = Double(-translation.y * 1.5)
        let modulation = Double(location.x * 0.16) - 30
        
        let newFrequency = (self.startingFrequency + changeInFrequency).clamped(to: 110...1760)
        let newModulation = modulation.clamped(to: -30...30)
        
        self.oscillator.baseFrequency = newFrequency
        self.oscillator.modulationIndex = newModulation
    }
    
    // MARK: - Status Bar
    
    public override var prefersStatusBarHidden: Bool {
        return true
    }
}


