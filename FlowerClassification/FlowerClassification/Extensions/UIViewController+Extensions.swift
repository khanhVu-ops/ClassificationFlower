//
//  UIViewController+Extensions.swift
//  ChatApp
//
//  Created by Vu Khanh on 09/03/2023.
//

import Foundation
import UIKit

extension UIViewController {
    
    func showAlert(title: String?, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alertController.addAction(okAction)
        present(alertController, animated: true, completion: nil)
    }
    
    func showActivityIndicator() {
        // Create the activity indicator
        let activityIndicator = UIActivityIndicatorView(style: .large)
        
        activityIndicator.color = .gray
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        
        // Add the activity indicator to the view hierarchy
        view.addSubview(activityIndicator)
        
        // Add constraints to center the activity indicator
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        
        // Start animating the activity indicator
        activityIndicator.startAnimating()
        view.isUserInteractionEnabled = false
    }
    
    func hideActivityIndicator() {
        // Find the activity indicator view and remove it from the view hierarchy
        if let activityIndicator = view.subviews.first(where: { $0 is UIActivityIndicatorView }) as? UIActivityIndicatorView {
            activityIndicator.stopAnimating()
            view.isUserInteractionEnabled = true
            activityIndicator.removeFromSuperview()
        }
    }
    
    func showIndicatorWithMessage(_ message: String) {
        let indicatorView = IndicatorView(message: message)
        indicatorView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(indicatorView)
        view.isUserInteractionEnabled = false
        NSLayoutConstraint.activate([
            indicatorView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            indicatorView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    func hideIndicatorWithMessage() {
        
        if let activityIndicator = view.subviews.first(where: { $0 is IndicatorView }) as? IndicatorView {
            activityIndicator.stopAnimation()
            activityIndicator.removeFromSuperview()
            view.isUserInteractionEnabled = true
        }
    }

    
}
