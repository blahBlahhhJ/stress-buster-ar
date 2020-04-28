//
//  PlaneNode.swift
//  Stress Buster AR
//
//  Created by Jason Wang on 4/19/20.
//  Copyright © 2020 Jason Wang. All rights reserved.
//

import ARKit
import SceneKit

class PlaneNode: SCNNode {
    public func update(from planeAnchor: ARPlaneAnchor) {
        guard let device = MTLCreateSystemDefaultDevice(), let geom = ARSCNPlaneGeometry(device: device) else {
            fatalError()
        }
        let material = SCNMaterial()
        material.lightingModel = .constant
        material.writesToDepthBuffer = true
        material.colorBufferWriteMask = []
        
        geom.firstMaterial = material
        geom.update(from: planeAnchor.geometry)
        geometry = geom
        
        let shape = SCNPhysicsShape(geometry: geom, options: [SCNPhysicsShape.Option.type: SCNPhysicsShape.ShapeType.boundingBox])
        
        physicsBody = SCNPhysicsBody(type: .static, shape: shape)
    }
}
