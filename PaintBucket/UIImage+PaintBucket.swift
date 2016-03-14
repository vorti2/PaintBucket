//
//  UIImage+PaintBucket.swift
//  PaintBucket
//
//  Created by Jack Flintermann on 3/13/16.
//  Copyright © 2016 jflinter. All rights reserved.
//

import UIKit

class ImageBuffer {
    let context: CGContextRef
    let pixelBuffer: UnsafeMutablePointer<UInt32>
    let imageWidth: Int
    let imageHeight: Int
    
    init(image: CGImageRef) {
        self.imageWidth = Int(CGImageGetWidth(image))
        self.imageHeight = Int(CGImageGetHeight(image))
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        
        self.context = CGBitmapContextCreate(nil, imageWidth, imageHeight, 8, imageWidth * 4, colorSpace, CGBitmapInfo.ByteOrder32Little.rawValue | CGImageAlphaInfo.PremultipliedFirst.rawValue)!
        CGContextDrawImage(self.context, CGRectMake(0, 0, CGFloat(imageWidth), CGFloat(imageHeight)), image)
        
        self.pixelBuffer = UnsafeMutablePointer<UInt32>(CGBitmapContextGetData(self.context))
    }
    
    func indexFrom(point: Point) -> Int {
        return indexFrom(point.x, point.y)
    }
    
    func indexFrom(x: Int, _ y: Int) -> Int {
        return x + (self.imageWidth * y)
    }
    
    func indicesToModify(startingPoint: Point, tolerance: Int) -> NSIndexSet {
        func indexToX(index: Int) -> Int {
            return index % imageWidth
        }
        
        func indexToY(index: Int) -> Int {
            return index / imageWidth
        }
        
        let pixelsToExamine = NSMutableIndexSet()
        let pixelsSeen = NSMutableIndexSet()
        
        let startingIndex = indexFrom(startingPoint)
        let pixel = self[startingIndex]
        
        pixelsToExamine.addIndex(startingIndex)
        while pixelsToExamine.count > 0 {
            let index = pixelsToExamine.firstIndex
            pixelsToExamine.removeIndex(index)
            
            let newPixel = self[index]
            let diff = pixel.diff(newPixel)
            
            if diff <= tolerance {
                pixelsSeen.addIndex(index)
                let x = indexToX(index)
                let y = indexToY(index)
                var nextPoints: [Point] = []
                let rawPointTuples = [(x+1, y), (x-1, y), (x, y+1), (x, y-1)]
                for (x, y) in rawPointTuples {
                    if x >= 0 && y >= 0 && x < imageWidth && y < imageHeight {
                        nextPoints.append(Point(x, y))
                    }
                }
                for nextPoint in nextPoints {
                    let nextIndex = indexFrom(nextPoint)
                    if !pixelsSeen.containsIndex(nextIndex) {
                        if (nextIndex > imageHeight * imageWidth) {
                            print("Serious error!")
                        }
                        pixelsToExamine.addIndex(nextIndex)
                    }
                }
            }
        }
        return pixelsSeen.copy() as! NSIndexSet
    }
    
    func differenceAtPoint(x: Int, _ y: Int, toPixel pixel: Pixel) -> Int {
        let index = indexFrom(x, y)
        let newPixel = self[index]
        return pixel.diff(newPixel)
    }
    
    func scanline_replaceColor(color: UIColor, startingAtPoint point: Point, withColor replacementColor: UIColor, tolerance: Int) {

        print("scanning at point: \(point)")
        
        let originalColorPixel = Pixel(color: color)
        let replacementPixel = Pixel(color: replacementColor)
        if differenceAtPoint(point.x, point.y, toPixel: originalColorPixel) > tolerance {
            return
        }
        if differenceAtPoint(point.x, point.y, toPixel: replacementPixel) == 0 {
            return
        }
        
        func testPixelAtPoint(x: Int, _ y: Int) -> Bool {
            return differenceAtPoint(x, y, toPixel: originalColorPixel) <= tolerance
        }
        
        self[indexFrom(point)] = replacementPixel
        
        let y = point.y
        var minX = point.x - 1
        var maxX = point.x + 1
        while minX >= 0 && testPixelAtPoint(minX, y) {
            let index = indexFrom(minX, y)
            self[index] = replacementPixel
            minX -= 1
        }
        while maxX < imageWidth && testPixelAtPoint(maxX, y) {
            let index = indexFrom(maxX, y)
            self[index] = replacementPixel
            maxX += 1
        }
        
        for x in ((minX + 1)...(maxX - 1)) {
            if y < imageHeight - 1 && testPixelAtPoint(x, y + 1) {
                self.scanline_replaceColor(color, startingAtPoint: Point(x, y + 1), withColor: replacementColor, tolerance: tolerance)
            }
            if y > 0 && testPixelAtPoint(x, y - 1) {
                self.scanline_replaceColor(color, startingAtPoint: Point(x, y - 1), withColor: replacementColor, tolerance: tolerance)
            }
        }
    }
    
    func replaceColorStartingAt(point: Point, withColor: UIColor, tolerance: Int) {
        let destinationPixel = Pixel(color: withColor)
        let indices = self.indicesToModify(point, tolerance: tolerance)
        for index in indices {
            self[index] = destinationPixel
        }
    }
    
    subscript(index: Int) -> Pixel {
        get {
            let pixelIndex = pixelBuffer + index
            return Pixel(memory: pixelIndex.memory)
        }
        set(pixel) {
            self.pixelBuffer[index] = pixel.uInt32Value
        }
    }
    
    var image: CGImageRef {
        return CGBitmapContextCreateImage(self.context)!
    }
    
}

public extension UIImage {
    
    public func pbk_imageByReplacingColorAt(point: CGPoint, withColor: UIColor, tolerance: Int) -> UIImage {
        return self.pbk_imageByReplacingColorAt(Point(point), withColor: withColor, tolerance: tolerance)
    }
    
    public func pbk_imageByReplacingColorAt(point: Point, withColor: UIColor, tolerance: Int) -> UIImage {
        
        let imageBuffer = ImageBuffer(image: self.CGImage!)
        let pixel = imageBuffer[imageBuffer.indexFrom(point)]
        let color = pixel.color
        imageBuffer.scanline_replaceColor(color, startingAtPoint: point, withColor: withColor, tolerance: tolerance)
        
//        imageBuffer.replaceColorStartingAt(point, withColor: withColor, tolerance: tolerance)
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

public struct Pixel: Equatable {
    let r, g, b, a: UInt8
    
    init(_ r: UInt8, _ g: UInt8, _ b: UInt8, _ a: UInt8) {
        self.r = r
        self.g = g
        self.b = b
        self.a = a
    }
    
    init(memory: UInt32) {
        self.a = UInt8((memory >> 24) & 255)
        self.r = UInt8((memory >> 16) & 255)
        self.g = UInt8((memory >> 8) & 255)
        self.b = UInt8((memory >> 0) & 255)
    }
    
    init(color: UIColor) {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        color.getRed(&r, green: &g, blue: &b, alpha: &a)
        self.r = UInt8(r * 255)
        self.g = UInt8(g * 255)
        self.b = UInt8(b * 255)
        self.a = UInt8(a * 255)
    }
    
    var color: UIColor {
        return UIColor(red: CGFloat(self.r) / 255, green: CGFloat(self.g) / 255, blue: CGFloat(self.b) / 255, alpha: CGFloat(self.a) / 255)
    }
    
    var uInt32Value: UInt32 {
        var total = UInt32(self.a) << 24
        total += (UInt32(self.r) << 16)
        total += (UInt32(self.g) << 8)
        total += (UInt32(self.b) << 0)
        return total
    }
    
    private func componentDiff(l: UInt8, _ r: UInt8) -> UInt8 {
        return max(l, r) - min(l, r)
    }
    
    func diff(other: Pixel) -> Int {
        return Int(componentDiff(self.r, other.r)) +
            Int(componentDiff(self.g, other.g)) +
            Int(componentDiff(self.b, other.b)) +
            Int(componentDiff(self.a, other.a))
    }
    
    
}

public func ==(lhs: Pixel, rhs: Pixel) -> Bool {
    let success = (lhs.r == rhs.r) && (lhs.g == rhs.g) && (lhs.b == rhs.b) && (lhs.a == rhs.a)
    if (!success) {
        print("womp")
    }
    return success
}
