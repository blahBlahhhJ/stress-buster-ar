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
    
    @IBOutlet weak var modelCollectionView: UICollectionView!
    
    @IBOutlet weak var previewView: SCNView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        modelCollectionView.delegate = self
        modelCollectionView.dataSource = self
        visualizeAlphaSlider.value = setting.visualAlpha
        sliderValueLabel.text = "\(round(visualizeAlphaSlider.value * 100) / 100)"
        prepareView()
        updatePreview()
    }
    
    @IBAction func alphaSliderChanged(_ sender: Any) {
        setting.visualAlpha = visualizeAlphaSlider.value
        sliderValueLabel.text = "\(round(visualizeAlphaSlider.value * 100) / 100)"
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

extension SettingViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return setting.availableModels.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let index = indexPath.item
        
        if let cell = modelCollectionView.dequeueReusableCell(withReuseIdentifier: "modelCell", for: indexPath) as? ModelCollectionViewCell {
            cell.modelImageView.image = UIImage(named: setting.modelPreviewImgs[index])
            // Add some cornerRadius maybe? Need to stuck imageView in a UIView and give UIView cornerRadius. I'm too lazy!
            return cell
        }
        return ModelCollectionViewCell()
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let chosenModel = setting.availableModels[indexPath.item]
        setting.selectedModel = chosenModel
        updatePreview()
    }
}
