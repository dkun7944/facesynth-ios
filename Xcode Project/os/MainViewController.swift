//
//  MainViewController.swift
//  os
//
//  Created by Daniel Kuntz on 4/1/17.
//  Copyright © 2017 Daniel Kuntz. All rights reserved.
//

import UIKit
import ARKit
import SceneKit
import AudioKit

public class MainViewController: UIViewController, UIGestureRecognizerDelegate, VirtualContentUpdaterDelegate {
    
    // MARK: - Outlets
    
    @IBOutlet weak var label1: UILabel!
    @IBOutlet weak var label2: UILabel!
    @IBOutlet weak var sceneView: ARSCNView!
    
    // MARK: - Properties
    
    var waveform: WaveformView!
    var waveformIdle: Bool = true
    var oscillator: AKFMOscillator = AKFMOscillator()
    var startingFrequency: Double = 220
    
    let freqRange: ClosedRange<Double> = 110.0...1760.0
    let modRange: ClosedRange<Double> = -30.0...30.0
    
    let contentUpdater = VirtualContentUpdater()
    /// Convenience accessor for the session owned by ARSCNView.
    var session: ARSession {
        return sceneView.session
    }
    
    // MARK: - Setup
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        setupSceneView()
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
        
        /*
         AR experiences typically involve moving the device without
         touch input for some time, so prevent auto screen dimming.
         */
        UIApplication.shared.isIdleTimerDisabled = true
        
        resetTracking()
    }
    
    func setupSceneView() {
        sceneView.delegate = contentUpdater
        sceneView.automaticallyUpdatesLighting = true
        contentUpdater.delegate = self
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
        
        if is3DTouchAvailable() {
            let forceGR = ForceTouchGestureRecognizer(target: self, action: #selector(viewForceTouched(_:)))
            forceGR.delegate = self
            view.addGestureRecognizer(forceGR)
        }
    }
    
    func is3DTouchAvailable() -> Bool {
        return self.traitCollection.forceTouchCapability == .available
    }
    
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    func addWaveform() {
        waveform = WaveformView(frame: view.frame)
        view.addSubview(waveform)
        view.backgroundColor = .clear
        view.sendSubview(toBack: waveform)
    }
    
    // MARK: -  ARFaceTrackingSetup
    func resetTracking() {
        print("Starting ARFaceTracking session")
        
        guard ARFaceTrackingConfiguration.isSupported else { return }
        let configuration = ARFaceTrackingConfiguration()
        configuration.isLightEstimationEnabled = true
        session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }
    
    // MARK: - VirtualContentUpdaterDelegate
    
    func blendShapesUpdated(_ jawOpen: Float, _ brows: Float) {
        label1.text = "\(jawOpen)"
        label2.text = "\(brows)"
        
        updateOscillatorFrequency(withBrows: brows)
        updateOscillatorModulation(withJaw: jawOpen)
        updateWaveform()
        
        if jawOpen >= 0.05 && !oscillator.isPlaying {
            oscillator.play()
            waveform.startNote()
            waveformIdle = false
        } else if jawOpen <= 0.05 && oscillator.isPlaying {
            oscillator.stop()
            waveform.stopNote()
            waveformIdle = true
        }
    }
    
    // MARK: - Pan Gesture Handler
    
    @objc func viewTouched(_ gestureRecognizer: UILongPressGestureRecognizer) {
        switch gestureRecognizer.state {
        case .began:
            self.beganPanning(gestureRecognizer)
        case .ended, .cancelled, .failed:
            self.stoppedPanning()
        default:
            break
        }
    }
    
    @objc func viewPanned(_ gestureRecognizer: UIPanGestureRecognizer) {
        DispatchQueue.global(qos: .background).async {
            if gestureRecognizer.state == .changed {
                self.continuedPanning(gestureRecognizer)
            }
        }
    }
    
    @objc func viewForceTouched(_ gestureRecognizer: ForceTouchGestureRecognizer) {
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
        updateOscillatorModulation(withLocation: gestureRecognizer.location(in: view))
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
        
        updateOscillatorModulation(withLocation: location)
        updateOscillatorFrequency(withTranslation: translation)
    }
    
    func updateOscillatorModulation(withLocation location: CGPoint) {
        let modulation = Double(location.x * 0.16) - 30
        let newModulation = modulation.clamped(to: modRange)
        self.oscillator.modulationIndex = newModulation
    }
    
    func updateOscillatorFrequency(withTranslation translation: CGPoint) {
        let changeInFrequency = Double(-translation.y * 1.5)
        let newFrequency = (self.startingFrequency + changeInFrequency).clamped(to: freqRange)
        oscillator.baseFrequency = newFrequency
    }
    
    func updateOscillatorFrequency(withBrows brows: Float) {
        let frequency = (Double(brows) * (freqRange.upperBound - freqRange.lowerBound)) + freqRange.lowerBound
        oscillator.baseFrequency = frequency
    }
    
    func updateOscillatorModulation(withJaw jaw: Float) {
        let mod = (Double(jaw) * (modRange.upperBound - modRange.lowerBound)) + modRange.lowerBound
        oscillator.modulationIndex = mod
    }
    
    // MARK: - Status Bar
    
    public override var prefersStatusBarHidden: Bool {
        return true
    }
}


