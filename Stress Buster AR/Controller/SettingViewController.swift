//
//  SettingViewController.swift
//  Stress Buster AR
//
//  Created by Jason Wang on 4/25/20.
//  Copyright © 2020 Jason Wang. All rights reserved.
//

import UIKit

class SettingViewController: UIViewController {

    @IBOutlet weak var visualizeDetectionSwitch: UISwitch!
    
    var visualizeDetection = false
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        visualizeDetectionSwitch.isOn =  visualizeDetection
    }
    
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
