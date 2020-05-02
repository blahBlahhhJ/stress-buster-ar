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
        let cylinder = SCNCylinder(radius: 0.1, height: 0.1)
        let material = SCNMaterial()
        material.diffuse.contents = UIColor.blue.withAlphaComponent(0.5)
        geometry = cylinder
        cylinder.firstMaterial = material
        
        let cylinderShape = SCNPhysicsShape(geometry: cylinder, options: nil)
        physicsBody = SCNPhysicsBody(type: .kinematic, shape: cylinderShape)
    }
}
