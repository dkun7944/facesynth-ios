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
    var waveformIdle: Bool = true
    var oscillator: AKFMOscillator = AKFMOscillator()
    
    var startingFrequency: Double = 220
    
    // MARK: - Setup
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        setupOscillator()
        setupGestureRecognizers()
    }
    
    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        addWaveform()
    }
    
    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if !UserDefaults.standard.hasSeenTutorial() {
            performSegue(withIdentifier: "mainToSwipeTutorial", sender: nil)
        }
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
    
    func setupGestureRecognizers() {
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
        waveform = WaveformView(frame: view.frame)
        view.addSubview(waveform)
        view.backgroundColor = .black
    }
    
    // MARK: - Pan Gesture Handler
    
    func viewTouched(_ gestureRecognizer: UILongPressGestureRecognizer) {
        switch gestureRecognizer.state {
        case .began:
            self.beganPanning(gestureRecognizer)
        case .ended, .cancelled, .failed:
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
            self.oscillator.carrierMultiplier = Double(gestureRecognizer.force * 3) + 1
            self.updateWaveform()
        }
    }
    
    func beganPanning(_ gestureRecognizer: UIGestureRecognizer) {
        waveformIdle = false
        startingFrequency = oscillator.baseFrequency
        oscillator.play()
        
        oscillator.rampTime = 0
        updateOscillatorModulation(gestureRecognizer.location(in: view))
        oscillator.rampTime = 0.2
        
        DispatchQueue.main.async {
            self.waveform.startNote()
            self.updateWaveform()
        }
    }
    
    func continuedPanning(_ gestureRecognizer: UIPanGestureRecognizer) {
        updateOscillator(gestureRecognizer)
        
        DispatchQueue.main.async {
            self.updateWaveform()
        }
    }
    
    func stoppedPanning() {
        waveformIdle = true
        oscillator.stop()
        
        DispatchQueue.main.async {
            self.waveform.stopNote()
        }
    }
    
    // MARK: - Waveform Updates
    
    func updateWaveform() {
        if waveformIdle { return }
        
        let frequency = CGFloat(self.oscillator.baseFrequency)
        let modulation = CGFloat(self.oscillator.modulationIndex)
        let carrier = CGFloat(self.oscillator.carrierMultiplier)
        self.waveform.update(withRealFrequency: frequency, modulation: modulation, carrier: carrier)
    }
    
    // MARK: - Oscillator Updates
    
    func updateOscillator(_ gestureRecognizer: UIPanGestureRecognizer) {
        let location = gestureRecognizer.location(in: view)
        let translation = gestureRecognizer.translation(in: view)
        
        updateOscillatorModulation(location)
        updateOscillatorFrequency(translation)
    }
    
    func updateOscillatorModulation(_ location: CGPoint) {
        let modulation = Double(location.x * 0.16) - 30
        let newModulation = modulation.clamped(to: -30...30)
        self.oscillator.modulationIndex = newModulation
    }
    
    func updateOscillatorFrequency(_ translation: CGPoint) {
        let changeInFrequency = Double(-translation.y * 1.5)
        let newFrequency = (self.startingFrequency + changeInFrequency).clamped(to: 110...1760)
        oscillator.baseFrequency = newFrequency
    }
    
    // MARK: - Status Bar
    
    public override var prefersStatusBarHidden: Bool {
        return true
    }
}


