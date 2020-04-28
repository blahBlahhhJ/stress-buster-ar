//
//  ViewController.swift
//  Stress Buster AR
//
//  Created by Jason Wang on 4/19/20.
//  Copyright © 2020 Jason Wang. All rights reserved.
//

import UIKit
import SceneKit
import ARKit
import CoreML
import Vision

class ViewController: UIViewController {

    @IBOutlet weak var sceneView: ARSCNView!
    @IBOutlet weak var debugImageView: UIImageView!
    
    var footNode = FootNode()
    let footDetector = FootDetector()
    var currentBuffer: CVPixelBuffer?
    
    private var width = Int(UIScreen.main.bounds.width)
    private var height = Int(UIScreen.main.bounds.height)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        sceneView.session.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        sceneView.autoenablesDefaultLighting = true
        sceneView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(viewDidTap(recognizer:))))
        
        /*let spotlightNode = SpotlightNode()
        spotlightNode.position = SCNVector3(10, 10, 0)
        sceneView.scene.rootNode.addChildNode(spotlightNode)*/
        // Richard Note: gonna setup some other lighting system for shadows, 3d rendering etc.
        
        sceneController.setupScene(sceneView, contactDelegate: self, footNode: footNode)
        footDetector.setUpVision()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal

        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    //MARK: Tap events
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let identifier = segue.identifier else {
            return
        }
        if identifier == "toSetting" {
            guard let dest = segue.destination as? SettingViewController else {
                return
            }
            dest.visualizeDetection = false
        }
    }
    
    @IBAction func settingButtonPressed(_ sender: Any) {
        performSegue(withIdentifier: "toSetting", sender: nil)
    }
    /**
     Listener for tap events.
     Creates a ball node in the tap position.
     Just for test.
     */
    @objc func viewDidTap(recognizer: UITapGestureRecognizer) {
        let testRichard = true
        let tapLoc = recognizer.location(in: sceneView)
        let hitTestResults = sceneView.hitTest(tapLoc, types: .existingPlaneUsingExtent)
        guard let hitTestRes = hitTestResults.first else {
            return
        }
        if (testRichard) {
            print("Tappy tappy")
            //sceneController.addFlyingBall()
            sceneController.addStaticBall(at: hitTestRes.worldTransform)
        } else {
            let ball = BallNode(radius: 0.05)
            ball.simdTransform = hitTestRes.worldTransform
            ball.position.y += 0.05
            
            sceneView.scene.rootNode.addChildNode(ball)
        }
    }
    
    //MARK: Helpers
    /**
     Helper function for predicting foot and result visualization.
     */
    private func detectFoot(orientation: CGImagePropertyOrientation) {
        guard let buffer = currentBuffer else {
            return
        }
        footDetector.predict(input: buffer, orientation: orientation) { outputBuffer, _ in
            guard let output = outputBuffer else {
                return
            }
            let debugImage = UIImage(ciImage: CIImage(cvPixelBuffer: output))
            DispatchQueue.main.async {
                self.debugImageView.image = debugImage
                // clear currentBuffer for next prediction.
                self.currentBuffer = nil
                // add footnode blablabla
                guard let footPoint = self.footDetector.findFoot(in: output) else {
                    return
                }
                let point = VNImagePointForNormalizedPoint(footPoint, self.width, self.height)
                let hitTestResults = self.sceneView.hitTest(point, types: .existingPlaneUsingExtent)
                        guard let hitTestRes = hitTestResults.first else {
                            return
                        }
                        self.footNode.simdTransform = hitTestRes.worldTransform
                        self.footNode.position.y += 0.05
                        self.footNode.isHidden = false
            }
            
            
        }
    }
    
    /**
     Helper function for identifying the correct orientation for coreml to work properly.
     */
    private func exifOrientationFromDeviceOrientation() -> CGImagePropertyOrientation {
        let curDeviceOrientation = UIDevice.current.orientation
        let exifOrientation: CGImagePropertyOrientation

        switch curDeviceOrientation {
        case UIDeviceOrientation.portraitUpsideDown:  // Device oriented vertically, home button on the top
            exifOrientation = .left
        case UIDeviceOrientation.landscapeLeft:       // Device oriented horizontally, home button on the right
            exifOrientation = .up
        case UIDeviceOrientation.landscapeRight:      // Device oriented horizontally, home button on the left
            exifOrientation = .down
        case UIDeviceOrientation.portrait:            // Device oriented vertically, home button on the bottom
            exifOrientation = .right
        default:
            exifOrientation = .up
        }
        return exifOrientation
    }
}

// MARK: ARSessionDelegate
extension ViewController: ARSessionDelegate {
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        // only perform prediction when an older prediction request is complete so that currentBuffer is set to nil.
        guard currentBuffer == nil, case .normal = frame.camera.trackingState else {
            return
        }
        currentBuffer = frame.capturedImage
        let orientation = exifOrientationFromDeviceOrientation()
        detectFoot(orientation: orientation)
    }
}

// MARK: ARSCNViewDelegate
extension ViewController: ARSCNViewDelegate {
    /*func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        guard let _ = anchor as? ARPlaneAnchor else {
            return nil
        }
        return PlaneNode()
    }*/
    // not needed
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        /*guard let planeAnchor = anchor as? ARPlaneAnchor, let planeNode = node as? PlaneNode else {
            return
        }*/
        guard let planeAnchor = anchor as? ARPlaneAnchor else {
            return
        }
        sceneController.beginAR(anchorAt: planeAnchor, node: node)
        //planeNode.update(from: planeAnchor)
    }
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        sceneController.frameUpdate()
    }
    /*func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor, let planeNode = node as? PlaneNode else {
            return
        }
        planeNode.update(from: planeAnchor)
    }*/
}


//MARK: SCNPhysicsContactDelegate
extension UIViewController: SCNPhysicsContactDelegate {
    public func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
        sceneController.didContact(contact)
    }
}
