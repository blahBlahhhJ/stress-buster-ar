//
//  StartViewController.swift
//  Stress Buster AR
//
//  Created by Jason Wang on 5/1/20.
//  Copyright © 2020 Jason Wang. All rights reserved.
//

import UIKit

class StartViewController: UIViewController {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var backgroundImageView: UIImageView!
    @IBOutlet weak var playButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        setBackgroundImg()
        playButton.layer.shadowColor = UIColor.black.cgColor
        playButton.layer.shadowRadius = 8
        playButton.layer.shadowOpacity = 0.5
        titleFadeIn()
    }
    
    private func titleFadeIn() {
        titleLabel.center.y += 180
        UIView.animate(withDuration: 0.5) {
            self.titleLabel.center.y -= 180
        }
    }
    
    private func setBackgroundImg() {
        let width = self.view.bounds.width
        let height = self.view.bounds.height
        if width < height {
            backgroundImageView.image = UIImage(named: "starting_page_portrait")
        } else {
            backgroundImageView.image = UIImage(named: "starting_page_landscape")
        }
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
    
    override func didRotate(from: UIInterfaceOrientation) {
        setBackgroundImg()
    }
    
    @IBAction func settingPressed(_ sender: Any) {
        performSegue(withIdentifier: "startToSetting", sender: nil)
    }
    @IBAction func playPressed(_ sender: Any) {
        performSegue(withIdentifier: "toGame", sender: nil)
    }
    
}
