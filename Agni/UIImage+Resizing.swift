//
//  UIImage+Resizing.swift
//  Agni
//
//  Created by Michael Ginn on 8/30/18.
//  Copyright © 2018 Michael Ginn. All rights reserved.
//

import Foundation
import UIKit

extension UIImage{
    
    func resizeToWidth(width: CGFloat, scale: CGFloat)->UIImage?{
        let scale = UIScreen.main.scale
        let ratio = self.size.height / self.size.width
        let size = CGSize(width: width * scale, height: width * ratio * scale)
        
        let newRect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        let imageRef = self.cgImage!
        
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        let context = UIGraphicsGetCurrentContext()
        
        context?.interpolationQuality = .high
        let flipVertical = CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: 0, ty: size.height)
        
        context?.concatenate(flipVertical)
        context?.draw(imageRef, in: newRect)
        
        guard let newImageRef = context!.makeImage() else {return nil}
        let newImage = UIImage(cgImage: newImageRef)
        
        UIGraphicsEndImageContext()
        
        return newImage
    }
}
