//
//  SceneController.swift
//  Stress Buster AR
//
//  Created by Richard Yan on 4/28/20.
//  Copyright © 2020 Jason Wang. All rights reserved.
//

import UIKit
import ARKit
import SceneKit

let sceneController = SceneController()
class SceneController {
    
    let BALL_MASK = 1
    let STRUCT_MASK = 2
    let FLOOR_MASK = 4
    let FOOT_MASK = 8

    var mainNode: SCNNode!
    var structNode: SCNNode?
    var ballParent: SCNNode!
    var toBeSettled = Set<SCNNode>()
    var collided = false
    var added = false
    var sceneView: ARSCNView!
    var anchor: ARPlaneAnchor!
    var newPosition: SCNVector3?
    
    func makeLights() -> SCNNode {
        let lightParent = SCNNode()
        lightParent.name = "lights"
        let lightNode = SCNNode()
        lightNode.light = SCNLight()
        lightNode.light!.type = .directional
        lightNode.light!.intensity = 1000
        lightNode.position = SCNVector3(x: 0, y: 0.5, z: 0)
        lightNode.eulerAngles = SCNVector3(-Float.pi/2, 0, 0)
        lightNode.light?.castsShadow = true
        lightNode.light?.shadowMode = .deferred
        lightNode.light?.automaticallyAdjustsShadowProjection = true
        lightNode.light?.shadowColor = UIColor.black.withAlphaComponent(0.80)
        lightNode.light?.shadowSampleCount = 2
        lightNode.light?.shadowRadius = 8
        //lightNode.light?.shadowMapSize = CGSize(width: 2048, height: 2048)
        lightNode.light?.categoryBitMask = ~FOOT_MASK
        lightParent.addChildNode(lightNode)
        return lightParent
    }
    
    func makeFloor() -> SCNNode {
        let worldGroundMaterial = SCNMaterial()
        worldGroundMaterial.lightingModel = .constant
        worldGroundMaterial.writesToDepthBuffer = true
        worldGroundMaterial.colorBufferWriteMask = [.alpha]
        worldGroundMaterial.isDoubleSided = true
        let floor = SCNNode(geometry: SCNFloor())
        floor.name = "floor"
        floor.geometry?.materials = [worldGroundMaterial]
        floor.position = SCNVector3(0, 0, 0)
        let shape = SCNPhysicsShape(shapes: [SCNPhysicsShape(geometry: SCNBox(width:1000, height:0.5, length:1000, chamferRadius: 0))], transforms: [NSValue(scnMatrix4: SCNMatrix4MakeTranslation(0, -0.25, 0))])
        let floorPhysicsBody = SCNPhysicsBody(type: .static, shape: shape)
        floor.physicsBody = floorPhysicsBody
        floor.physicsBody?.categoryBitMask = FLOOR_MASK
        floor.physicsBody?.collisionBitMask = BALL_MASK | STRUCT_MASK
        return floor
    }
    
    func setupScene(_ sceneView: ARSCNView, contactDelegate: SCNPhysicsContactDelegate, footNode: SCNNode) {
        self.sceneView = sceneView
        
        let scene = SCNScene(named: "art.scnassets/Environment.scn")!
        scene.physicsWorld.gravity = SCNVector3(0, 0, 0)
        sceneView.scene = scene
        sceneView.scene.physicsWorld.speed = 0.5
        sceneView.scene.physicsWorld.contactDelegate = contactDelegate

        mainNode = SCNNode()
        mainNode.name = "Main"

        footNode.categoryBitMask = FOOT_MASK
        footNode.physicsBody?.mass = 5
        footNode.physicsBody?.collisionBitMask = BALL_MASK | STRUCT_MASK
        footNode.physicsBody?.categoryBitMask = FOOT_MASK
        footNode.physicsBody?.contactTestBitMask = STRUCT_MASK

        ballParent = SCNNode()
        sceneView.scene.rootNode.addChildNode(ballParent)
        sceneView.scene.rootNode.addChildNode(footNode)
        
        //sceneView.autoenablesDefaultLighting = true
        //sceneView.automaticallyUpdatesLighting = true
    }
    
    func beginAR(anchorAt planeAnchor: ARPlaneAnchor, node: SCNNode) {
        if (added) {
            return
        }
        added = true
        anchor = planeAnchor
        node.position = SCNVector3(planeAnchor.center.x, planeAnchor.center.y, planeAnchor.center.z)
        node.addChildNode(mainNode)
    }
    
    func clearStructure() {
        disableGravity()
        collided = false
        toBeSettled.removeAll()
        structNode?.removeFromParentNode()
    }
    
    func placeStructure(atPosition position: SCNVector3) {
        newPosition = position
    }
    
    func addStructure(named name: String, at position: SCNVector3 = SCNVector3(0,0,0)) {
        let scene = SCNScene(named: name)!
        let structNode = SCNNode()
        structNode.name = "struct"
        for node in scene.rootNode.childNodes {
            structNode.addChildNode(node)
        }
        structNode.addChildNode(makeFloor())
        structNode.addChildNode(makeLights())
        mainNode.addChildNode(structNode)
        for childNode in structNode.childNodes {
            if childNode.physicsBody != nil && childNode.name != "floor" && childNode.name != "lights" {
                childNode.physicsBody?.categoryBitMask = STRUCT_MASK
                childNode.physicsBody?.collisionBitMask = BALL_MASK | FLOOR_MASK | FOOT_MASK
                childNode.physicsBody?.contactTestBitMask = BALL_MASK
                childNode.physicsBody?.isAffectedByGravity = true
                childNode.runAction(.move(by: position, duration: 0))
                toBeSettled.insert(childNode)
            } else{
                childNode.runAction(.move(by: position, duration: 0))
            }
        }
    }
    
    func addFlyingBall() {
        let flyingBall = SCNSphere(radius: 0.03)
        let ballMaterial = SCNMaterial()
        ballMaterial.lightingModel = .physicallyBased
        ballMaterial.diffuse.contents = UIColor(displayP3Red: 0, green: 0, blue: 0, alpha: 0.5)
        ballMaterial.metalness.contents = 0
        ballMaterial.roughness.contents = 0.8
        flyingBall.firstMaterial = ballMaterial
        let ballNode = SCNNode(geometry: flyingBall)
        let worldFront = sceneView.pointOfView!.worldFront
        let cameraForce = SCNVector3(worldFront.x * 15, worldFront.y * 15, worldFront.z * 15)
        ballParent.addChildNode(ballNode)
        ballNode.position = sceneView.pointOfView!.position
        ballNode.physicsBody = .dynamic()
        ballNode.physicsBody?.categoryBitMask = BALL_MASK
        ballNode.physicsBody?.collisionBitMask = STRUCT_MASK | FLOOR_MASK | FOOT_MASK
        ballNode.physicsBody?.contactTestBitMask = STRUCT_MASK
        ballNode.physicsBody?.mass = 5
        ballNode.physicsBody?.applyForce(cameraForce, asImpulse: true)
        ballNode.runAction(SCNAction.sequence([.wait(duration: 10), .removeFromParentNode()]))
    }
    
    private func getBall() -> SCNNode {
        let ball = SCNSphere(radius: 0.03)
        let ballMaterial = SCNMaterial()
        ballMaterial.lightingModel = .physicallyBased
        ballMaterial.diffuse.contents = UIColor(displayP3Red: 0, green: 0, blue: 0, alpha: 0.8)
        ballMaterial.metalness.contents = 1
        ballMaterial.roughness.contents = 0.5
        ball.firstMaterial = ballMaterial
        return SCNNode(geometry: ball)
    }
    
    func addStaticBall() {
        let ballNode = getBall()
        ballParent.addChildNode(ballNode)
        ballNode.position = sceneView.pointOfView!.position
        ballNode.physicsBody = .dynamic()
        ballNode.physicsBody?.categoryBitMask = BALL_MASK
        ballNode.physicsBody?.collisionBitMask = STRUCT_MASK | FLOOR_MASK | FOOT_MASK
        ballNode.physicsBody?.contactTestBitMask = STRUCT_MASK
        ballNode.physicsBody?.mass = 50
    }
    
    func addStaticBall(at position: simd_float4x4) {
        let ballNode = getBall()
        ballParent.addChildNode(ballNode)
        ballNode.simdTransform = position
        ballNode.position.y += 0.05
        ballNode.physicsBody = .dynamic()
        ballNode.physicsBody?.categoryBitMask = BALL_MASK
        ballNode.physicsBody?.collisionBitMask = STRUCT_MASK | FLOOR_MASK | FOOT_MASK
        ballNode.physicsBody?.contactTestBitMask = STRUCT_MASK
        ballNode.physicsBody?.mass = 50
    }

    func frameUpdate() {
        if let newPos = newPosition {
            addStructure(named: setting.selectedModel, at: newPos)
            newPosition = nil
        }
        if !collided {
            if let sNode = structNode {
                for node in sNode.childNodes {
                    node.physicsBody!.setResting(true)
                }
            }
        }
    }
    
    func didContact(_ contact: SCNPhysicsContact) {
        if (toBeSettled.count == 0) {
            return
        }
        let collisionType = contact.nodeA.physicsBody!.categoryBitMask | contact.nodeB.physicsBody!.categoryBitMask
        if (collisionType == BALL_MASK | STRUCT_MASK ||
            collisionType == FOOT_MASK | STRUCT_MASK) {
            let structNode = contact.nodeA.physicsBody!.categoryBitMask == STRUCT_MASK ? contact.nodeA : contact.nodeB
            if toBeSettled.contains(structNode) {
                if !collided {
                    enableGravity()
                    collided = true
                }
            }
        }
    }
    
    func enableGravity() {
        sceneView.scene.physicsWorld.gravity = SCNVector3(0, -4.9, 0)
        for structNode in toBeSettled {
            structNode.physicsBody?.collisionBitMask = STRUCT_MASK | BALL_MASK | FOOT_MASK | FLOOR_MASK
        }
        toBeSettled.removeAll()
    }
    
    func disableGravity() {
        sceneView.scene.physicsWorld.gravity = SCNVector3(0, 0, 0)
    }
}
