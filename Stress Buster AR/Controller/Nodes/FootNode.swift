//
//  FootNode.swift
//  Stress Buster AR
//
//  Created by Jason Wang on 4/19/20.
//  Copyright © 2020 Jason Wang. All rights reserved.
//

import SceneKit
import ARKit

class FootNode: SCNNode {
    public override init() {
        super.init()
        commonInit()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init()
        commonInit()
    }
    
    private func commonInit() {
        let sphere = SCNSphere(radius: 0.10)
        let material = SCNMaterial()
        material.diffuse.contents = UIColor.blue.withAlphaComponent(0.7)
        geometry = sphere
        sphere.firstMaterial = material
        
        let sphereShape = SCNPhysicsShape(geometry: sphere, options: nil)
        physicsBody = SCNPhysicsBody(type: .kinematic, shape: sphereShape)
    }
}
