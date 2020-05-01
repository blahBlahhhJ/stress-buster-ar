//
//  StartViewController.swift
//  Stress Buster AR
//
//  Created by Jason Wang on 5/1/20.
//  Copyright © 2020 Jason Wang. All rights reserved.
//

import UIKit

class StartViewController: UIViewController {

    @IBOutlet weak var playButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        playButton.layer.cornerRadius = 10
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let identifier = segue.identifier else {
            return
        }
        if identifier == "toGame" {
            guard let dest = segue.destination as? ViewController else {
                return
            }
        } else if identifier == "startToSetting" {
            guard let dest = segue.destination as? SettingViewController else {
                return
            }
        }
    }
    
    @IBAction func settingPressed(_ sender: Any) {
        performSegue(withIdentifier: "startToSetting", sender: nil)
    }
    @IBAction func playPressed(_ sender: Any) {
        performSegue(withIdentifier: "toGame", sender: nil)
    }
    
}
