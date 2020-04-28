//
//  SpotlightNode.swift
//  Stress Buster AR
//
//  Created by Jason Wang on 4/19/20.
//  Copyright © 2020 Jason Wang. All rights reserved.
//

import ARKit
import SceneKit

class SpotlightNode: SCNNode {
    public override init() {
        super.init()
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    private func commonInit() {
        let spotlight = SCNLight()
        spotlight.type = .directional
        spotlight.shadowMode = .deferred
        spotlight.castsShadow = true
        spotlight.shadowRadius = 100.0
        spotlight.shadowColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.2)
        
        light = spotlight
        
        eulerAngles = SCNVector3(-Float.pi / 2, 0, 0)
    }
}

