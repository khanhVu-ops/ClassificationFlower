////
////  CustomImageView.swift
////  ChatApp
////
////  Created by Vu Khanh on 14/03/2023.
////
//
//import Foundation
//import UIKit
//class CustomImageView: UIImageView {
//
//    override func layoutSubviews() {
//        super.layoutSubviews()
//
//        if let image = self.image {
//            // Calculate the desired size of the image view based on the aspect ratio of the image
//            let imageRatio = image.size.width / image.size.height
//            let viewRatio = self.bounds.width / self.bounds.height
//
//            var newWidth: CGFloat
//            var newHeight: CGFloat
//
////            if imageRatio > viewRatio {
//                newWidth = self.bounds.width
//                newHeight = self.bounds.height / imageRatio
////            } else {
////                newHeight = self.bounds.height
////                newWidth = self.bounds.height * imageRatio
////            }
//
//            // Set the frame of the image view to fit the new size of the image
//            let newX = self.frame.origin.x + self.frame.width - newWidth
//            let newY = self.frame.origin.y
//            let newFrame = CGRect(x: newX, y: newY, width: newWidth, height: newHeight)
//            self.frame = newFrame
//        }
//    }
//
//}
