import UIKit

public class WaveformView: UIView {
    
    // MARK: - Properties
    
    public var numberOfWaves: Int = 5
    public var waveColor: UIColor = .lightGray
    public var currentFrequency: CGFloat = 1.5
    public var density: CGFloat = 1
    public var currentPhaseShift: CGFloat = 0.05
    public var amplitude: CGFloat = 0
    
    public var idleAmplitude: CGFloat = 0.01
    public var idleFrequency: CGFloat = 1.5
    public var idlePhaseShift: CGFloat = 0.05
    
    var updatingFrequency: Bool = false
    var startFrequency: CGFloat = 1.5
    var targetFrequency: CGFloat = 1.5
    
    var updatingPhaseShift: Bool = false
    var startPhaseShift: CGFloat = 0.05
    var targetPhaseShift: CGFloat = 0.05
    
    var maxAmplitude: CGFloat = 0.5
    var startingNote: Bool = false
    var stoppingNote: Bool = false
    
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
        startingNote = true
        stoppingNote = false
    }
    
    public func stopNote() {
        startingNote = false
        stoppingNote = true
        
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
    }
    
    func setNewFrequency(_ newValue: CGFloat) {
        targetFrequency = max(newValue, idleFrequency)
        startFrequency = targetFrequency
        updatingFrequency = true
    }
    
    func setNewPhaseShift(_ newValue: CGFloat) {
        targetPhaseShift = max(newValue, idlePhaseShift)
        startPhaseShift = targetPhaseShift
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
    
    // MARK: - Animation
    
    func updateDisplayLink() {
        updatePhaseShift()
        updateStartStopNote()
        updateFrequency()
    }
    
    func updateStartStopNote() {
        if startingNote {
            if amplitude < maxAmplitude {
                update(withLevel: amplitude + 0.1, frequency: currentFrequency)
            } else {
                startingNote = false
                stoppingNote = false
                updateDefault()
            }
        } else if stoppingNote {
            if amplitude > idleAmplitude {
                update(withLevel: amplitude - 0.1, frequency: currentFrequency)
            } else {
                startingNote = false
                stoppingNote = false
                updateDefault()
            }
        } else {
            updateDefault()
        }
    }
    
    func updateFrequency() {
        if updatingFrequency {
            if currentFrequency < targetFrequency {
                update(withLevel: amplitude, frequency: targetFrequency + (targetFrequency - startFrequency) / 10)
            } else if currentFrequency > targetFrequency {
                update(withLevel: amplitude, frequency: targetFrequency - (targetFrequency - startFrequency) / 10)
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
                currentPhaseShift = targetPhaseShift + (targetPhaseShift - startPhaseShift) / 10
            } else if currentPhaseShift > targetPhaseShift {
                currentPhaseShift = targetPhaseShift - (targetPhaseShift - startPhaseShift) / 10
            } else {
                updatingPhaseShift = false
            }
        }
        
        updateDefault()
    }
    
    func updateDefault() {
        update(withLevel: amplitude, frequency: currentFrequency)
    }
    
    func update(withLevel level: CGFloat, frequency: CGFloat) {
        phase -= currentPhaseShift
        amplitude = max(level, idleAmplitude)
        currentFrequency = frequency

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
            let normedAmplitude: CGFloat = (1.5 * progress - 0.5) * amplitude
            
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
