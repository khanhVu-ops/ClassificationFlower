//
//  ViewController.swift
//  FlowerClassification
//
//  Created by Khanh Vu on 30/03/5 Reiwa.
//

import UIKit

class MainViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    @IBAction func btnOpenCameraTapped(_ sender: UIButton) {
        let cameraVC = CameraViewController()
        self.navigationController?.pushViewController(cameraVC, animated: true)
    }

    @IBAction func btnOpenLibraryTapped(_ sender: UIButton) {
        
    }

}

