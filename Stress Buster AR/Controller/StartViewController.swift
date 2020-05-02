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
    @IBOutlet weak var foregroundImageView: UIImageView!
    @IBOutlet weak var playButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        setBackgroundImg()
        playButton.layer.shadowColor = UIColor.black.cgColor
        playButton.layer.shadowRadius = 8
        playButton.layer.shadowOpacity = 0.5
        foregroundImageView.translatesAutoresizingMaskIntoConstraints = false
        foregroundImageView.topAnchor.constraint(equalTo: backgroundImageView.topAnchor, constant: 0.06 * backgroundImageView.bounds.height).isActive = true
        foregroundImageView.leadingAnchor.constraint(equalTo: backgroundImageView.leadingAnchor, constant: 0.3 * backgroundImageView.bounds.width).isActive = true
        launchScreenAnimation()
    }
    
    private func launchScreenAnimation() {
        playButton.alpha = 0
        playButton.transform = CGAffineTransform.init(scaleX: 0.5, y: 0.5)
        
        titleLabel.center.y += 80
        
        UIView.animate(withDuration: 0.5) {
            self.playButton.alpha = 1
            self.playButton.transform = CGAffineTransform.identity
            
            self.titleLabel.center.y -= 80
            
//            self.foregroundImageView.center.x = self.backgroundImageView.center.x + 0.5 * self.backgroundImageView.bounds.width
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
