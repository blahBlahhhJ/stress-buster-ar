//
//  SettingViewController.swift
//  Stress Buster AR
//
//  Created by Jason Wang on 4/25/20.
//  Copyright © 2020 Jason Wang. All rights reserved.
//

import UIKit
import SceneKit

class SettingViewController: UIViewController {

    @IBOutlet weak var sliderValueLabel: UILabel!
    
    @IBOutlet weak var visualizeAlphaSlider: UISlider!
    
    @IBOutlet weak var selectModelSegment: UISegmentedControl!
    
    @IBOutlet weak var previewView: SCNView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        visualizeAlphaSlider.value = setting.visualAlpha
        sliderValueLabel.text = "\(round(visualizeAlphaSlider.value * 100) / 100)"
        if setting.selectedModel == "art.scnassets/shrek.scn" {
            selectModelSegment.selectedSegmentIndex = 0
        } else if setting.selectedModel == "art.scnassets/Hoover.scn" {
            selectModelSegment.selectedSegmentIndex = 1
        }
        prepareView()
        updatePreview()
    }
    
    @IBAction func alphaSliderChanged(_ sender: Any) {
        setting.visualAlpha = visualizeAlphaSlider.value
        sliderValueLabel.text = "\(round(visualizeAlphaSlider.value * 100) / 100)"
    }
    
    @IBAction func modelSelectionChanged(_ sender: Any) {
        if selectModelSegment.selectedSegmentIndex == 0 {
            setting.selectedModel = "art.scnassets/shrek.scn"
        } else if selectModelSegment.selectedSegmentIndex == 1 {
            setting.selectedModel = "art.scnassets/Hoover.scn"
        }
        updatePreview()
    }
    
    func prepareView() {
        previewView.scene = SCNScene()
        let worldGroundMaterial = SCNMaterial()
        worldGroundMaterial.lightingModel = .constant
        worldGroundMaterial.writesToDepthBuffer = true
        worldGroundMaterial.isDoubleSided = true
        let floor = SCNNode(geometry: SCNFloor())
        floor.geometry?.materials = [worldGroundMaterial]
        previewView.scene?.rootNode.addChildNode(floor)
        
        /* Stupid f*cking shadow rendering bug needs a patch */
        let material = SCNMaterial()
        material.diffuse.contents = UIColor.clear.cgColor
        let node1 = SCNNode(geometry: SCNSphere(radius: 0.0001))
        node1.geometry?.materials = [material]
        node1.position = SCNVector3(x: 0, y: 0, z: -0.08)
        previewView.scene?.rootNode.addChildNode(node1)
        let node2 = SCNNode(geometry: SCNSphere(radius: 0.0001))
        material.diffuse.contents = UIColor.clear.cgColor
        node2.geometry?.materials = [material]
        node2.position = SCNVector3(x: 0, y: 0, z: 0.08)
        previewView.scene?.rootNode.addChildNode(node2)

        let directionalLight = SCNNode()
        directionalLight.light = SCNLight()
        directionalLight.light?.type = .directional
        directionalLight.light?.intensity = 1000
        directionalLight.position = SCNVector3(x: 0, y: 1, z: 1)
        directionalLight.eulerAngles = SCNVector3(-Float.pi / 5 * 2, 0, 0)
        directionalLight.light?.castsShadow = true
        directionalLight.light?.shadowMode = .deferred
        directionalLight.light?.shadowColor = UIColor.black.withAlphaComponent(0.80)
        directionalLight.light?.shadowSampleCount = 8
        directionalLight.light?.shadowRadius = 16
        directionalLight.light?.shadowMapSize = CGSize(width: 1024, height: 1024)
        directionalLight.light?.zFar = 1000
        let ambientLight = SCNNode()
        ambientLight.light = SCNLight()
        ambientLight.light?.type = .ambient
        ambientLight.light?.intensity = 1000
        ambientLight.position = SCNVector3(x: 1, y: 1, z: 0)
        previewView.scene?.physicsWorld.speed = 0
        previewView.scene?.rootNode.addChildNode(directionalLight)
        previewView.scene?.rootNode.addChildNode(ambientLight)
    }

    var structNode: SCNNode?
    func updatePreview() {
        structNode?.removeFromParentNode()
        structNode = SCNNode()
        for node in SCNScene(named: setting.selectedModel)!.rootNode.childNodes {
            structNode!.addChildNode(node)
        }
        structNode?.position = SCNVector3(0, 0, 0)
//        structNode?.scale = SCNVector3(1, 1, 1)
        previewView.scene!.rootNode.addChildNode(structNode!)
    }
}
