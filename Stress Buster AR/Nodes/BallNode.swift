//
//  BallNode.swift
//  Stress Buster AR
//
//  Created by Jason Wang on 4/19/20.
//  Copyright © 2020 Jason Wang. All rights reserved.
//

import SceneKit
import ARKit

class BallNode: SCNNode {
    public convenience init(radius: CGFloat) {
        self.init()
        let sphere = SCNSphere(radius: radius)
        
        let reflectiveMaterial = SCNMaterial()
        reflectiveMaterial.lightingModel = .physicallyBased
        
        reflectiveMaterial.metalness.contents = 1.0
        reflectiveMaterial.roughness.contents = 0.1
        
        sphere.firstMaterial = reflectiveMaterial
        
        self.geometry = sphere
        
        physicsBody = SCNPhysicsBody(type: .dynamic, shape: nil)
    }
}
