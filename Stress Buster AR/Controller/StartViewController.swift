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
    @IBOutlet weak var footLeadingConstraint: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        setBackgroundImg()
        playButton.layer.shadowOffset = CGSize(width: 0, height: 2)
        playButton.layer.shadowColor = UIColor.black.cgColor
        playButton.layer.shadowRadius = 8
        playButton.layer.shadowOpacity = 0.5
        launchScreenAnimation()
    }
    
    private func launchScreenAnimation() {
        playButton.alpha = 0
        playButton.transform = CGAffineTransform.init(scaleX: 0.5, y: 0.5)
        
        titleLabel.center.y += 80
        
        self.footLeadingConstraint.constant = -0.7 * self.foregroundImageView.bounds.width
        self.foregroundImageView.transform = .init(rotationAngle: -CGFloat.pi / 180 * 8)
        UIView.animate(withDuration: 0.5, animations: {
            self.playButton.alpha = 1
            self.playButton.transform = CGAffineTransform.identity
            self.titleLabel.center.y -= 80
            self.view.layoutIfNeeded()
        }, completion: {(finished) in
            UIView.animateKeyframes(withDuration: 4, delay: 0, options: [.repeat, .calculationModeCubic], animations: {
                UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 0.2, animations: {
                    self.foregroundImageView.transform = .init(rotationAngle: -CGFloat.pi / 180 * 8)
                })
                UIView.addKeyframe(withRelativeStartTime: 0.2, relativeDuration: 0.08, animations: {
                    self.foregroundImageView.transform = .init(rotationAngle: -CGFloat.pi / 180 * 2)
                })
                UIView.addKeyframe(withRelativeStartTime: 0.28, relativeDuration: 0.16, animations: {
                    self.foregroundImageView.transform = .init(rotationAngle: CGFloat.pi / 180 * 20)
                })
                UIView.addKeyframe(withRelativeStartTime: 0.44, relativeDuration: 0.16, animations: {
                    self.foregroundImageView.transform = .init(rotationAngle: CGFloat.pi / 180 * 12)
                })
                UIView.addKeyframe(withRelativeStartTime: 0.6, relativeDuration: 0.16, animations: {
                    self.foregroundImageView.transform = .init(rotationAngle: CGFloat.pi / 180 * 20)
                })
                UIView.addKeyframe(withRelativeStartTime: 0.76, relativeDuration: 0.16, animations: {
                    self.foregroundImageView.transform = .init(rotationAngle: -CGFloat.pi / 180 * 2)
                })
                UIView.addKeyframe(withRelativeStartTime: 0.92, relativeDuration: 0.08, animations: {
                    self.foregroundImageView.transform = .init(rotationAngle: -CGFloat.pi / 180 * 8)
                })
            })
        })
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
