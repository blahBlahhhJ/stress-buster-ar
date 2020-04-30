//
//  SettingViewController.swift
//  Stress Buster AR
//
//  Created by Jason Wang on 4/25/20.
//  Copyright © 2020 Jason Wang. All rights reserved.
//

import UIKit

class SettingViewController: UIViewController {

    @IBOutlet weak var sliderValueLabel: UILabel!
    
    @IBOutlet weak var visualizeAlphaSlider: UISlider!
    
    @IBOutlet weak var selectModelSegment: UISegmentedControl!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        visualizeAlphaSlider.value = setting.visualAlpha
        sliderValueLabel.text = "\(round(visualizeAlphaSlider.value * 100) / 100)"
        if setting.selectedModel == "art.scnassets/shrek.scn" {
            selectModelSegment.selectedSegmentIndex = 0
        } else if setting.selectedModel == "art.scnassets/Hoover.scn" {
            selectModelSegment.selectedSegmentIndex = 1
        }
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
    }
}
