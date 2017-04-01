import UIKit

public class WaveformView: UIView {
    
    // MARK: - Properties
    
    public var rampTime: TimeInterval = 0.2 {
        didSet {
            rampFrames = 60 * CGFloat(rampTime)
        }
    }
    
    public var waveColor: UIColor = .lightGray
    public var idleAmplitude: CGFloat = 0.01
    public var idleFrequency: CGFloat = 1.5
    public var idlePhaseShift: CGFloat = 0.05
    
    var density: CGFloat = 1
    var phase: CGFloat = 0
    var rampFrames: CGFloat!
    
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
        rampFrames = 60 * CGFloat(rampTime)
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
    
    public func update(withRealFrequency frequency: CGFloat, modulation: CGFloat) {
        let waveformFrequency = frequency / 150
        setNewFrequency(waveformFrequency)
        
        let shift = frequency / 700
        setNewPhaseShift(shift)
        
        setColor(fromModulation: modulation)
        setDensity(fromModulation: modulation)
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
    
    // MARK: - Animation
    
    func updateDisplayLink() {
        updatePhaseShift()
        updateStartStopNote()
        updateFrequency()
    }
    
    func updateStartStopNote() {
        if updatingAmplitude {
            if currentAmplitude < targetAmplitude {
                let newAmplitude = currentAmplitude + abs(targetAmplitude - startAmplitude) / rampFrames
                update(withLevel: newAmplitude, frequency: currentFrequency, phaseShift: currentPhaseShift)
            } else if currentAmplitude > targetAmplitude {
                let newAmplitude = currentAmplitude - abs(targetAmplitude - startAmplitude) / rampFrames
                update(withLevel: newAmplitude, frequency: currentFrequency, phaseShift: currentPhaseShift)
            } else {
                updatingAmplitude = false
                updateWithDefaultValues()
            }
        } else {
            updateWithDefaultValues()
        }
    }
    
    func updateFrequency() {
        if updatingFrequency {
            if currentFrequency < targetFrequency {
                let newFrequency = currentFrequency + abs(targetFrequency - startFrequency) / rampFrames
                update(withLevel: currentAmplitude, frequency: newFrequency, phaseShift: currentPhaseShift)
            } else if currentFrequency > targetFrequency {
                let newFrequency = currentFrequency - abs(targetFrequency - startFrequency) / rampFrames
                update(withLevel: currentAmplitude, frequency: newFrequency, phaseShift: currentPhaseShift)
            } else {
                updatingFrequency = false
                updateWithDefaultValues()
            }
        } else {
            updateWithDefaultValues()
        }
    }
    
    func updatePhaseShift() {
        if updatingPhaseShift {
            if currentPhaseShift < targetPhaseShift {
                let newPhaseShift = currentPhaseShift + abs(targetPhaseShift - startPhaseShift) / rampFrames
                update(withLevel: currentAmplitude, frequency: currentFrequency, phaseShift: newPhaseShift)
            } else if currentPhaseShift > targetPhaseShift {
                let newPhaseShift = currentPhaseShift - abs(targetPhaseShift - startPhaseShift) / rampFrames
                update(withLevel: currentAmplitude, frequency: currentFrequency, phaseShift: newPhaseShift)
            } else {
                updatingPhaseShift = false
                updateWithDefaultValues()
            }
        } else {
            updateWithDefaultValues()
        }
    }
    
    func updateWithDefaultValues() {
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
        
        context = UIGraphicsGetCurrentContext()
        context?.setLineWidth(2.0)
        
        let halfHeight = bounds.height / 2
        let width = bounds.width
        let mid = width / 2
        let maxAmplitude: CGFloat = halfHeight - 4
        
        waveColor.set()
        
        for x in stride(from: 0, to: width + density, by: density) {
            let scaling: CGFloat = -pow(1 / mid * (x - mid), 2) + 1
            let y: CGFloat = scaling * maxAmplitude * currentAmplitude * sin(2 * .pi * (x / width) * currentFrequency + phase) + halfHeight
            
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
