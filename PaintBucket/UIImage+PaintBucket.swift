//
//  UIImage+PaintBucket.swift
//  PaintBucket
//
//  Created by Jack Flintermann on 3/13/16.
//  Copyright © 2016 jflinter. All rights reserved.
//

import UIKit

public extension UIImage {
    
    public func pbk_imageByReplacingColorAt(point: CGPoint, withColor: UIColor, tolerance: Int, contiguous: Bool) -> UIImage {
        return self.pbk_imageByReplacingColorAt(Point(point), withColor: withColor, tolerance: tolerance, contiguous: contiguous)
    }
    
    private func pbk_imageByReplacingColorAt(point: Point, withColor: UIColor, tolerance: Int, contiguous: Bool) -> UIImage {
        
        let cgImage = self.CGImage
        let width = Int(size.width)
        let height = Int(size.height)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        
        let context = CGBitmapContextCreate(nil, width, height, 8, width * 4, colorSpace, CGBitmapInfo.ByteOrder32Little.rawValue | CGImageAlphaInfo.PremultipliedFirst.rawValue)!
        CGContextDrawImage(context, CGRectMake(0, 0, size.width, size.height), cgImage)

        let pixelData = CGBitmapContextGetData(context)
        let pixelBuffer = UnsafeMutablePointer<UInt32>(pixelData)
        
        let imageWidth = Int(CGImageGetWidth(cgImage))
        let imageHeight = Int(CGImageGetHeight(cgImage))
        
        let indices = pbx_indicesToModify(point, imageWidth: imageWidth, imageHeight: imageHeight, tolerance: tolerance, pixelBuffer: pixelBuffer)
        
        let destinationPixel = Pixel(color: withColor)
        
        for index in indices {
            self.pbk_setPixel(destinationPixel, atIndex: index, inBuffer: pixelBuffer)
        }
        
        let imageRef = CGBitmapContextCreateImage(context)!
        return UIImage(CGImage: imageRef)
    }
    
    private func pbx_indicesToModify(startingPoint: Point, imageWidth: Int, imageHeight: Int, tolerance: Int, pixelBuffer: UnsafeMutablePointer<UInt32>) -> NSIndexSet {
        
        func indexToX(index: Int) -> Int {
            return index % imageWidth
        }
        
        func indexToY(index: Int) -> Int {
            return index / imageWidth
        }
        
        let pixelsToExamine = NSMutableIndexSet()
        let pixelsSeen = NSMutableIndexSet()
        
        let startingIndex = UIImage.pbk_indexFrom(startingPoint, imageWidth)
        guard let pixel = UIImage.pbk_pixelAtIndex(startingIndex, pixelBuffer) else { fatalError("womp") }
        
        pixelsToExamine.addIndex(startingIndex)
        while pixelsToExamine.count > 0 {
            let index = pixelsToExamine.firstIndex
            pixelsToExamine.removeIndex(index)
            
            guard let newPixel = UIImage.pbk_pixelAtIndex(index, pixelBuffer) else { fatalError("womp") }
            let diff = pixel.diff(newPixel)
            
            if diff <= tolerance {
                pixelsSeen.addIndex(index)
                let x = indexToX(index)
                let y = indexToY(index)
                let pointTuples = [(x+1, y), (x-1, y), (x, y+1), (x, y-1)]
                let points: [Point] = pointTuples.map { x, y in
                    return Point(x, y)
                }
                let nextPoints = points.filter { $0.x >= 0 }.filter { $0.y >= 0 }.filter { $0.x < imageWidth }.filter { $0.y < imageHeight }
                for nextPoint in nextPoints {
                    let nextIndex = UIImage.pbk_indexFrom(nextPoint, imageWidth)
                    if !pixelsSeen.containsIndex(nextIndex) {
                        pixelsToExamine.addIndex(nextIndex)
                    }
                }
            }
        }
        return pixelsSeen.copy() as! NSIndexSet
    }
    
    internal static func pbk_pixelAtIndex(index: Int, _ pixelBuffer: UnsafePointer<UInt32>) -> Pixel? {
        let pixelIndex = pixelBuffer + index
        return Pixel(memory: pixelIndex.memory)
    }
    
    private func pbk_setPixel(pixel: Pixel, atIndex: Int, inBuffer: UnsafeMutablePointer<UInt32>) {
        inBuffer[atIndex] = pixel.uInt32Value
    }
    
    private static func pbk_indexFrom(point: Point, _ imageWidth: Int) -> Int {
        return point.x + (point.y * imageWidth)
    }
}

struct Point {
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

struct Pixel: Equatable {
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
        return [
            componentDiff(self.r, other.r),
            componentDiff(self.g, other.g) +
            componentDiff(self.b, other.b) +
            componentDiff(self.a, other.a)
        ].map(Int.init).reduce(0, combine: +)
    }
    
    
}

func ==(lhs: Pixel, rhs: Pixel) -> Bool {
    let success = (lhs.r == rhs.r) && (lhs.g == rhs.g) && (lhs.b == rhs.b) && (lhs.a == rhs.a)
    if (!success) {
        print("womp")
    }
    return success
}
