//
//  ViewController.swift
//  ulyanov-lab3
//
//  Created by xcode on 12.12.2025.
//  Copyright © 2025 VSU. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        
        let slider = CircularSlider()
        slider.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(slider)
        
        NSLayoutConstraint.activate([
            slider.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            slider.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            slider.widthAnchor.constraint(equalToConstant: 300),
            slider.heightAnchor.constraint(equalToConstant: 300)
        ])
        
        slider.addTarget(self, action: #selector(handle), for: .valueChanged)
    }
    
    @objc func handle(_ sender: CircularSlider) {
        print(sender.value)
    }
}
