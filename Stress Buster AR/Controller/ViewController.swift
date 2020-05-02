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
    @IBOutlet var popUpView: UIView!
    @IBOutlet weak var blurView: UIVisualEffectView!
    
    var footNode = FootNode()
    let footDetector = FootDetector()
    
    var currentBuffer: CVPixelBuffer?
    var currentOrientation = CGImagePropertyOrientation.up
    
    var blurEffectOn = true
    
    private var width = Int(UIScreen.main.bounds.width)
    private var height = Int(UIScreen.main.bounds.height)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // SceneView setup
        sceneView.delegate = self
        sceneView.session.delegate = self
        sceneView.showsStatistics = true
        sceneView.autoenablesDefaultLighting = true
        sceneView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(viewDidTap(recognizer:))))
        
        // BlurEffect and popup setup
        popUpFadeIn()
        
        // Richard Note: gonna setup some other lighting system for shadows, 3d rendering etc.
        
        // AR setup
        sceneController.setupScene(sceneView, contactDelegate: self, footNode: footNode)
        
        // Vision setup
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
     Helper function for popUpView to fade in.
     */
    private func popUpFadeIn() {
        self.view.addSubview(popUpView)
        popUpView.layer.cornerRadius = 5
        popUpView.translatesAutoresizingMaskIntoConstraints = false
        popUpView.center = self.view.center
        popUpView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 100).isActive = true
        popUpView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -100).isActive = true
        popUpView.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 100).isActive = true
        popUpView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: -100).isActive = true
        popUpView.alpha = 0
        popUpView.transform = CGAffineTransform.init(scaleX: 1.3, y: 1.3)
        
        UIView.animate(withDuration: 0.5) {
            self.popUpView.transform = CGAffineTransform.identity
            self.popUpView.alpha = 1
        }
    }
    
    private func popUpFadeOut() {
        DispatchQueue.main.async {
            UIView.animate(withDuration: 0.5, animations: {
                self.popUpView.transform = CGAffineTransform.init(scaleX: 1.3, y: 1.3)
                self.popUpView.alpha = 0
            }) { (success: Bool) in
                self.blurView.removeFromSuperview()
                self.popUpView.removeFromSuperview()
                self.blurEffectOn = false
            }
        }
    }
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
                self.debugImageView.alpha = CGFloat(setting.visualAlpha)
                self.debugImageView.image = debugImage
                // clear currentBuffer for next prediction.
                self.currentBuffer = nil
                // this is where you switch the method for finding foot
                guard let footPoint = self.footDetector.findFoot(in: output) else {
                    return
                }
                self.width = Int(self.view.bounds.width)
                self.height = Int(self.view.bounds.height)
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
            exifOrientation = currentOrientation
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
        currentOrientation = exifOrientationFromDeviceOrientation()
        detectFoot(orientation: currentOrientation)
    }
}

// MARK: ARSCNViewDelegate
extension ViewController: ARSCNViewDelegate {
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else {
            return
        }
        if self.blurEffectOn {
            popUpFadeOut()
        }
        sceneController.beginAR(anchorAt: planeAnchor, node: node)
    }
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        sceneController.frameUpdate()
    }
}


//MARK: SCNPhysicsContactDelegate
extension UIViewController: SCNPhysicsContactDelegate {
    public func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
        sceneController.didContact(contact)
    }
}
