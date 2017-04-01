import UIKit

public class WaveformView: UIView {
    
    // MARK: - Properties
    
    public var numberOfWaves: Int = 5
    public var waveColor: UIColor = .lightGray
    
    var density: CGFloat = 1
    
    public var idleAmplitude: CGFloat = 0.01
    public var idleFrequency: CGFloat = 1.5
    public var idlePhaseShift: CGFloat = 0.05
    
    var updatingFrequency: Bool = false
    var currentFrequency: CGFloat = 1.5
    var startFrequency: CGFloat = 1.5
    var targetFrequency: CGFloat = 1.5
    
    var updatingPhaseShift: Bool = false
    var currentPhaseShift: CGFloat = 0.05
    var startPhaseShift: CGFloat = 0.05
    var targetPhaseShift: CGFloat = 0.05
    
    var updatingAmplitude: Bool = false
    var currentAmplitude: CGFloat = 0
    var startAmplitude: CGFloat = 0
    var targetAmplitude: CGFloat = 0.5
    
    var phase: CGFloat = 0
    var displayLink: CADisplayLink!
    
    // MARK: - Initialization
    
    override public init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    func setup() {
        backgroundColor = .black
        displayLink = CADisplayLink(target: self, selector: #selector(updateDisplayLink))
        displayLink.add(to: .current, forMode: .defaultRunLoopMode)
    }
    
    // MARK: - Start / Stop Notes
    
    public func startNote() {
        setNewAmplitude(0.2)
    }
    
    public func stopNote() {
        setNewAmplitude(idleAmplitude)
        setNewFrequency(idleFrequency)
        setNewPhaseShift(idlePhaseShift)
        waveColor = .lightGray
    }
    
    public func update(withRealFrequency frequency: CGFloat, modulation: CGFloat, carrier: CGFloat) {
        let waveformFrequency = frequency / 150
        setNewFrequency(waveformFrequency)
        
        let shift = frequency / 700
        setNewPhaseShift(shift)
        
        setColor(fromModulation: modulation)
        setDensity(fromModulation: modulation)
        setAmplitude(fromCarrier: carrier)
    }
    
    func setNewAmplitude(_ newValue: CGFloat) {
        targetAmplitude = max(newValue, idleAmplitude)
        startAmplitude = currentAmplitude
        updatingAmplitude = true
    }
    
    func setNewFrequency(_ newValue: CGFloat) {
        targetFrequency = max(newValue, idleFrequency)
        startFrequency = currentFrequency
        updatingFrequency = true
    }
    
    func setNewPhaseShift(_ newValue: CGFloat) {
        targetPhaseShift = max(newValue, idlePhaseShift)
        startPhaseShift = currentPhaseShift
        updatingPhaseShift = true
    }
    
    func setColor(fromModulation modulation: CGFloat) {
        DispatchQueue.global(qos: .background).async {
            let blueIntensity = -modulation + 30
            let orangeIntensity = modulation + 30
            
            let blendedColor = UIColor.blend(color1: .pastelBlue, intensity1: blueIntensity, color2: .pastelRed, intensity2: orangeIntensity)
            self.waveColor = blendedColor
        }
    }
    
    func setDensity(fromModulation modulation: CGFloat) {
        density = (modulation + 30) / 6
    }
    
    func setAmplitude(fromCarrier carrier: CGFloat) {
        if updatingAmplitude {
            targetAmplitude = carrier / 6.0
        } else {
            currentAmplitude = carrier / 6.0
        }
    }
    
    // MARK: - Animation
    
    func updateDisplayLink() {
        updatePhaseShift()
        updateStartStopNote()
        updateFrequency()
    }
    
    func updateStartStopNote() {
        if updatingAmplitude {
            if currentAmplitude < targetAmplitude {
                let newAmplitude = 
                update(withLevel: currentAmplitude + abs(targetAmplitude - startAmplitude) / 30, frequency: currentFrequency, phaseShift: currentPhaseShift)
            } else if currentAmplitude > targetAmplitude {
                update(withLevel: currentAmplitude - abs(targetAmplitude - startAmplitude) / 30, frequency: currentFrequency, phaseShift: currentPhaseShift)
            } else {
                updatingAmplitude = false
                updateDefault()
            }
        } else {
            updateDefault()
        }
    }
    
    func updateFrequency() {
        if updatingFrequency {
            if currentFrequency < targetFrequency {
                update(withLevel: currentAmplitude, frequency: currentFrequency + abs(targetFrequency - startFrequency) / 30, phaseShift: currentPhaseShift)
            } else if currentFrequency > targetFrequency {
                update(withLevel: currentAmplitude, frequency: currentFrequency - abs(targetFrequency - startFrequency) / 30, phaseShift: currentPhaseShift)
            } else {
                updatingFrequency = false
                updateDefault()
            }
        } else {
            updateDefault()
        }
    }
    
    func updatePhaseShift() {
        if updatingPhaseShift {
            if currentPhaseShift < targetPhaseShift {
                update(withLevel: currentAmplitude, frequency: currentFrequency, phaseShift: currentPhaseShift + abs(targetPhaseShift - startPhaseShift) / 30)
            } else if currentPhaseShift > targetPhaseShift {
                update(withLevel: currentAmplitude, frequency: currentFrequency, phaseShift: currentPhaseShift - abs(targetPhaseShift - startPhaseShift) / 30)
            } else {
                updatingPhaseShift = false
                updateDefault()
            }
        } else {
            updateDefault()
        }
    }
    
    func updateDefault() {
        update(withLevel: currentAmplitude, frequency: currentFrequency, phaseShift: currentPhaseShift)
    }
    
    func update(withLevel level: CGFloat, frequency: CGFloat, phaseShift: CGFloat) {
        currentAmplitude = max(level, idleAmplitude)
        currentFrequency = max(frequency, idleFrequency)
        currentPhaseShift = max(phaseShift, idlePhaseShift)

        phase -= currentPhaseShift
        setNeedsDisplay()
    }
    
    override public func draw(_ rect: CGRect) {
        var context = UIGraphicsGetCurrentContext()
        context?.clear(bounds)
        
        backgroundColor?.set()
        context?.fill(bounds)
        
        for i in 0..<numberOfWaves {
            context = UIGraphicsGetCurrentContext()
            context?.setLineWidth(2.0)
            
            let halfHeight = bounds.height / 2
            let width = bounds.width
            let mid = width / 2
            
            let maxAmplitude: CGFloat = halfHeight - 4
            let progress: CGFloat = CGFloat(1 - i / numberOfWaves)
            let normedAmplitude: CGFloat = (1.5 * progress - 0.5) * currentAmplitude
            
            let multiplier: CGFloat = min(1.0, (progress / 3 * 2) + (1 / 3))
            
            waveColor.withAlphaComponent(multiplier * waveColor.cgColor.alpha).set()
            
            for x in stride(from: 0, to: width + density, by: density) {
                let scaling: CGFloat = -pow(1 / mid * (x - mid), 2) + 1
                let y: CGFloat = scaling * maxAmplitude * normedAmplitude * sin(2 * .pi * (x / width) * currentFrequency + phase) + halfHeight
                
                let point: CGPoint = CGPoint(x: x, y: y)
                if x == 0 {
                    context?.move(to: point)
                } else {
                    context?.addLine(to: point)
                }
            }
            
            context?.strokePath()
        }
    }
}
