//
//  ReplaceSegue.swift
//  Stress Buster AR
//
//  Created by Jason Wang on 5/1/20.
//  Copyright © 2020 Jason Wang. All rights reserved.
//

import UIKit

class ReplaceSegue: UIStoryboardSegue {
    override func perform() {
        let containerView = source.view.superview
        containerView?.addSubview(destination.view)
        destination.modalPresentationStyle = .fullScreen
        source.present(destination, animated: false)
    }
}
