/*
See LICENSE folder for this sample’s licensing information.

Abstract:
An `ARSCNViewDelegate` which addes and updates the virtual face content in response to the ARFaceTracking session.
*/

import SceneKit
import ARKit

class VirtualContentUpdater: NSObject, ARSCNViewDelegate {
    
    // MARK: - Blend Shapes
    
    var mouthClose: Float = 0.5
    var brows: Float = 0.5
    
    /// - Tag: BlendShapeAnimation
    var blendShapes: [ARFaceAnchor.BlendShapeLocation: Any] = [:] {
        didSet {
            mouthClose = blendShapes[.mouthClose] as? Float ?? mouthClose
            brows = blendShapes[.browInnerUp] as? Float ?? brows
        }
    }
    
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
            self.blendShapes = faceAnchor.blendShapes
        }
    }
}
