//
//  Setting.swift
//  Stress Buster AR
//
//  Created by Jason Wang on 4/28/20.
//  Copyright © 2020 Jason Wang. All rights reserved.
//

import Foundation

let setting = Setting()
class Setting {
    var visualAlpha: Float = 0
    
    var selectedModel: String = "art.scnassets/shrek.scn"
    
    let availableModels = ["art.scnassets/shrek.scn", "art.scnassets/Hoover.scn", "art.scnassets/coronavirus.scn"]
    let modelPreviewImgs = ["shrek_preview", "hoover_preview", "covid_preview"]
}
