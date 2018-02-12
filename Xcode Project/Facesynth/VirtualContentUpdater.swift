/*
See LICENSE folder for this sample’s licensing information.

Abstract:
An `ARSCNViewDelegate` which addes and updates the virtual face content in response to the ARFaceTracking session.
*/

import SceneKit
import ARKit

protocol VirtualContentUpdaterDelegate {
    func blendShapesUpdated(_ jawOpen: Float, _ brows: Float, _ pucker: Float)
}

class VirtualContentUpdater: NSObject, ARSCNViewDelegate {
    
    // MARK: - Blend Shapes
    
    var jawOpen: Float = 0.01
    var brows: Float = 0.5
    var pucker: Float = 0.5
    
    /// - Tag: BlendShapeAnimation
    var blendShapes: [ARFaceAnchor.BlendShapeLocation : Any] = [:] {
        didSet {
            jawOpen = blendShapes[.jawOpen] as? Float ?? jawOpen
            brows = blendShapes[.browInnerUp] as? Float ?? brows
            if let p = blendShapes[.mouthPucker] as? Float {
                pucker = (0.8-(2*p)).clamped(to: 0...1)
            }
            delegate?.blendShapesUpdated(jawOpen, brows, pucker)
        }
    }
    
    var position: SCNVector3 = SCNVector3(0, 0, 0)
    var orientation: SCNVector3 = SCNVector3(0, 0, 0)
    var delegate: VirtualContentUpdaterDelegate?
    
    /**
     A reference to the node that was added by ARKit in `renderer(_:didAdd:for:)`.
     - Tag: FaceNode
     */
    private var faceNode: SCNNode?
    
    // MARK: - ARSCNViewDelegate
    
    /// - Tag: ARNodeTracking
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        // Hold onto the `faceNode` so that the session does not need to be restarted when switching masks.
        
        DispatchQueue.main.async {
            self.faceNode = node
        }
    }
    
    /// - Tag: ARFaceGeometryUpdate
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let faceAnchor = anchor as? ARFaceAnchor else { return }
        
        DispatchQueue.main.async {
            if faceAnchor.isTracked {
                self.blendShapes = faceAnchor.blendShapes
                self.position = faceAnchor.transform.position()
                
                let r = faceAnchor.transform.upperLeft3x3
                let yaw = atan(r[1][0] / r[0][0])
                let pitch = atan(-r[2][0] / sqrt(pow(r[2][1], 2) + pow(r[2][2], 2)))
                let roll = atan(r[2][1] / r[2][2])
                
                self.orientation = SCNVector3(yaw, pitch, roll)
            } else {
                self.blendShapes = [.jawOpen : Float(0.01),
                                    .browInnerUp : self.brows,
                                    .mouthPucker : self.pucker]
            }
        }
    }
}
