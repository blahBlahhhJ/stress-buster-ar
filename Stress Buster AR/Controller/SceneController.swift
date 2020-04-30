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
    var ballParent: SCNNode!
    var toBeSettled = Set<SCNNode>()
    var added = false
    var sceneView: ARSCNView!
    
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
        floor.physicsBody = .static()
        floor.physicsBody?.categoryBitMask = FLOOR_MASK
        floor.physicsBody?.collisionBitMask = -1
        return floor
    }
    
    
    
    func setupScene(_ sceneView: ARSCNView, contactDelegate: SCNPhysicsContactDelegate, footNode: SCNNode) {
        self.sceneView = sceneView
        
        let scene = SCNScene(named: "art.scnassets/Environment.scn")!
        scene.physicsWorld.gravity = SCNVector3(0, -9.8, 0)
        sceneView.scene = scene
        sceneView.scene.physicsWorld.speed = 1
        sceneView.scene.physicsWorld.contactDelegate = contactDelegate

        mainNode = SCNNode()
        mainNode.name = "Main"

        footNode.physicsBody?.mass = 1000
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

        node.position = SCNVector3(planeAnchor.center.x, planeAnchor.center.y, planeAnchor.center.z)
        node.addChildNode(mainNode)
        print(setting.selectedModel)
        addStructure(named: setting.selectedModel, at: SCNVector3(planeAnchor.center.x, planeAnchor.center.y, planeAnchor.center.z))
    }
    
    func addStructure(named name: String, at position: SCNVector3 = SCNVector3(0,0,0)) {
        let scene = SCNScene(named: name)!
        scene.rootNode.addChildNode(makeFloor())
        scene.rootNode.addChildNode(makeLights())
        mainNode.addChildNode(scene.rootNode)
        for childNode in scene.rootNode.childNodes {
            if childNode.physicsBody != nil && childNode.name != "floor" && childNode.name != "lights" {
                childNode.physicsBody?.categoryBitMask = STRUCT_MASK
                childNode.physicsBody?.collisionBitMask = BALL_MASK | FLOOR_MASK | FOOT_MASK
                childNode.physicsBody?.contactTestBitMask = BALL_MASK
                childNode.physicsBody?.isAffectedByGravity = false
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
        for node in toBeSettled {
            node.physicsBody!.setResting(true)
        }
    }
    
    func didContact(_ contact: SCNPhysicsContact) {
        let collisionType = contact.nodeA.physicsBody!.categoryBitMask | contact.nodeB.physicsBody!.categoryBitMask
        if (collisionType == BALL_MASK | STRUCT_MASK ||
            collisionType == FOOT_MASK | STRUCT_MASK) {
            let structNode = contact.nodeA.physicsBody!.categoryBitMask == STRUCT_MASK ? contact.nodeA : contact.nodeB
            if toBeSettled.contains(structNode) {
                structNode.physicsBody?.isAffectedByGravity = true
                toBeSettled.remove(structNode)
            }
        }
    }
}
