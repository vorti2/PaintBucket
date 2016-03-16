//
//  UIImage+PaintBucket.swift
//  PaintBucket
//
//  Created by Jack Flintermann on 3/13/16.
//  Copyright © 2016 jflinter. All rights reserved.
//

import UIKit

public extension UIImage {
    
    public func pbk_imageByReplacingColorAt(point: CGPoint, withColor: UIColor, tolerance: Int) -> UIImage {
        return self.pbk_imageByReplacingColorAt(Point(point), withColor: withColor, tolerance: tolerance)
    }
    
    public func pbk_imageByReplacingColorAt(point: Point, withColor: UIColor, tolerance: Int) -> UIImage {
        
        let imageBuffer = ImageBuffer(image: self.CGImage!)
        let pixel = imageBuffer[imageBuffer.indexFrom(point)]
        let replacementPixel = Pixel(color: withColor)
        imageBuffer.scanline_replaceColor(pixel, startingAtPoint: point, withColor: replacementPixel, tolerance: tolerance)
        
        return UIImage(CGImage: imageBuffer.image, scale: self.scale, orientation: UIImageOrientation.Up)
    }
}

public struct Point {
    let x, y: Int
    
    init(_ x: Int, _ y: Int) {
        self.x = x
        self.y = y
    }
    
    init(_ point: CGPoint) {
        self.x = Int(point.x)
        self.y = Int(point.y)
    }
}

