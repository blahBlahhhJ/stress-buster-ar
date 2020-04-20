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
    @IBOutlet weak var debugTextView: UITextView!
    @IBOutlet weak var debugImageView: UIImageView!
    
    var footNode = FootNode()
    
    var currentBuffer: CVPixelBuffer?
    private let visionQueue = DispatchQueue(label: "vision")
    private var requests = [VNRequest]()
    
    private var debugText = "none"
    private var debugImage = UIImage()
    
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
        
        let spotlightNode = SpotlightNode()
        spotlightNode.position = SCNVector3(10, 10, 0)
        sceneView.scene.rootNode.addChildNode(spotlightNode)
        sceneView.scene.rootNode.addChildNode(footNode)
        
        setUpVision()
        
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
    
    func setUpVision() {
        guard let model = try? VNCoreMLModel(for: FootModel().model) else {
            fatalError("can't load model")
        }
        let request = VNCoreMLRequest(model: model) { request, error in
            //main thread
            DispatchQueue.main.async {
                self.handleDetection(request: request, error: error)
                self.currentBuffer = nil
            }
        }
        request.imageCropAndScaleOption = .scaleFill
        requests = [request]
    }
    
    func handleDetection(request: VNRequest, error: Error?) {
        guard let results = request.results, !results.isEmpty else {
            debugText = "none"
            return
        }
        guard let obs = results.first as? VNRecognizedObjectObservation else {
            return
        }
        let bbox = VNImageRectForNormalizedRect(obs.boundingBox, width, height)
        let label = obs.labels[0]
        
        debugImage = drawRectangle(box: bbox)
        debugText = label.identifier
        
        let hitTestResults = self.sceneView.hitTest(CGPoint(x: bbox.midX, y: CGFloat(height) - bbox.midY), types: .existingPlaneUsingExtent)
        guard let hitTestRes = hitTestResults.first else {
            return
        }
        self.footNode.simdTransform = hitTestRes.worldTransform
        self.footNode.position.y += 0.05
        self.footNode.isHidden = false
    }
    
    @objc func viewDidTap(recognizer: UITapGestureRecognizer) {
        let tapLoc = recognizer.location(in: sceneView)
        let hitTestResults = sceneView.hitTest(tapLoc, types: .existingPlaneUsingExtent)
        guard let hitTestRes = hitTestResults.first else {
            return
        }
        
        let ball = BallNode(radius: 0.05)
        ball.simdTransform = hitTestRes.worldTransform
        ball.position.y += 0.05
        
        sceneView.scene.rootNode.addChildNode(ball)
    }
    
    func drawRectangle(box: CGRect) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: width, height: height))

        let img = renderer.image { ctx in
            ctx.cgContext.setStrokeColor(UIColor.red.cgColor)
            ctx.cgContext.setFillColor(gray: 0, alpha: 0)
            ctx.cgContext.setLineWidth(5)
            
            let new_box = CGRect(x: box.midX, y: CGFloat(height) - box.midY, width: box.width, height: box.height)

            ctx.cgContext.addRect(new_box)
            ctx.cgContext.drawPath(using: .fillStroke)
        }
        return img
    }
}

// MARK: ARSessionDelegate
extension ViewController: ARSessionDelegate {
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        guard currentBuffer == nil, case .normal = frame.camera.trackingState else {
            return
        }
        currentBuffer = frame.capturedImage
        // fix
        let handler = VNImageRequestHandler(cvPixelBuffer: currentBuffer!, orientation: .right)
        do {
            try handler.perform(self.requests)
            debugTextView.text = debugText
            debugImageView.image = debugImage
        } catch {
            print(error)
        }
    }
}

// MARK: ARSCNViewDelegate
extension ViewController: ARSCNViewDelegate {
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        guard let _ = anchor as? ARPlaneAnchor else {
            return nil
        }
        return PlaneNode()
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor, let planeNode = node as? PlaneNode else {
            return
        }
        planeNode.update(from: planeAnchor)
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor, let planeNode = node as? PlaneNode else {
            return
        }
        planeNode.update(from: planeAnchor)
    }
}
