//
//  ImageBuffer.swift
//  PaintBucket
//
//  Created by Jack Flintermann on 3/15/16.
//  Copyright © 2016 jflinter. All rights reserved.
//

import CoreGraphics

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
    
    func indexFrom(x: Int, _ y: Int) -> Int {
        return x + (self.imageWidth * y)
    }
    
    func differenceAtPoint(x: Int, _ y: Int, toPixel pixel: Pixel) -> Int {
        let index = indexFrom(x, y)
        let newPixel = self[index]
        return pixel.diff(newPixel)
    }
    
    func differenceAtIndex(index: Int, toPixel pixel: Pixel) -> Int {
        let newPixel = self[index]
        return pixel.diff(newPixel)
    }
    
    func scanline_replaceColor(colorPixel: Pixel, startingAtPoint startingPoint: (Int, Int), withColor replacementPixel: Pixel, tolerance: Int, antialias: Bool) {
        
        func testPixelAtPoint(x: Int, _ y: Int) -> Bool {
            return differenceAtPoint(x, y, toPixel: colorPixel) <= tolerance
        }
        
        let seenIndices = NSMutableIndexSet()
        let indices = NSMutableIndexSet(index: indexFrom(startingPoint))
        while indices.count > 0 {
            let index = indices.firstIndex
            indices.removeIndex(index)
            
            if seenIndices.containsIndex(index) {
                continue
            }
            seenIndices.addIndex(index)
            
            if differenceAtIndex(index, toPixel: colorPixel) > tolerance {
                continue
            }
            if differenceAtIndex(index, toPixel: replacementPixel) == 0 {
                continue
            }
            
            let pointX = index % imageWidth
            let y = index / imageWidth
            var minX = pointX
            var maxX = pointX + 1
            
            while minX >= 0 {
                let index = indexFrom(minX, y)
                let pixel = self[index]
                let diff = pixel.diff(colorPixel)
                if diff > tolerance { break }
                let alphaMultiplier = (tolerance == 0) ? 1 : CGFloat(diff) / CGFloat(tolerance)
                let newPixel = antialias ? pixel.multiplyAlpha(alphaMultiplier).blend(replacementPixel) : replacementPixel
                self[index] = newPixel
                minX -= 1
            }
            while maxX < imageWidth {
                let index = indexFrom(maxX, y)
                let pixel = self[index]
                let diff = pixel.diff(colorPixel)
                if diff > tolerance { break }
                let alphaMultiplier = (tolerance == 0) ? 1 : CGFloat(diff) / CGFloat(tolerance)
                let newPixel = antialias ? pixel.multiplyAlpha(alphaMultiplier).blend(replacementPixel) : replacementPixel
                self[index] = newPixel
                maxX += 1
            }
            
            for x in ((minX + 1)...(maxX - 1)) {
                if y < imageHeight - 1 {
                    let index = indexFrom(x, y + 1)
                    if !seenIndices.containsIndex(index) && differenceAtIndex(index, toPixel: colorPixel) <= tolerance {
                        indices.addIndex(index)
                    }
                }
                if y > 0 {
                    let index = indexFrom(x, y - 1)
                    if !seenIndices.containsIndex(index) && differenceAtIndex(index, toPixel: colorPixel) <= tolerance {
                        indices.addIndex(index)
                    }
                }
            }
            
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
