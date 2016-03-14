//
//  PaintBucketTests.swift
//  PaintBucketTests
//
//  Created by Jack Flintermann on 3/13/16.
//  Copyright © 2016 jflinter. All rights reserved.
//

import XCTest
@testable import PaintBucket

class PaintBucketTests: XCTestCase {
    
    func testBasicSquare() {
        let image = ImageBuilder().addColor(.redColor()).addColor(.greenColor()).image
        let expected = ImageBuilder().addColor(.blueColor()).addColor(.greenColor()).image
        let transformed = image.pbk_imageByReplacingColorAt(CGPointMake(0, 0), withColor: UIColor.blueColor(), tolerance: 100, contiguous: false)
        let data1 = UIImagePNGRepresentation(expected)!
        let data2 = UIImagePNGRepresentation(transformed)!
        XCTAssert(data1.isEqualToData(data2))
        XCTAssert(expected.pixelsEqualToImage(transformed))
    }
    
    func testBasicSquare_CenterCoordinate() {
        let image = ImageBuilder().addColor(.redColor()).addColor(.greenColor()).image
        let expected = ImageBuilder().addColor(.redColor()).addColor(.blueColor()).image
        let transformed = image.pbk_imageByReplacingColorAt(CGPointMake(50, 50), withColor: UIColor.blueColor(), tolerance: 100, contiguous: false)
        let data1 = UIImagePNGRepresentation(expected)!
        let data2 = UIImagePNGRepresentation(transformed)!
        XCTAssert(data1.isEqualToData(data2))
        XCTAssert(expected.pixelsEqualToImage(transformed))
    }
    
    func testBasicSquare_Boundary1() {
        let image = ImageBuilder().addColor(.redColor()).addColor(.greenColor()).image
        let expected = ImageBuilder().addColor(.blueColor()).addColor(.greenColor()).image
        let transformed = image.pbk_imageByReplacingColorAt(CGPointMake(9, 9), withColor: UIColor.blueColor(), tolerance: 100, contiguous: false)
        let data1 = UIImagePNGRepresentation(expected)!
        let data2 = UIImagePNGRepresentation(transformed)!
        XCTAssert(data1.isEqualToData(data2))
        XCTAssert(expected.pixelsEqualToImage(transformed))
    }
    
    func testBasicSquare_Boundary2() {
        let image = ImageBuilder().addColor(.redColor()).addColor(.greenColor()).image
        let expected = ImageBuilder().addColor(.redColor()).addColor(.blueColor()).image
        let transformed = image.pbk_imageByReplacingColorAt(CGPointMake(10, 10), withColor: UIColor.blueColor(), tolerance: 100, contiguous: false)
        let data1 = UIImagePNGRepresentation(expected)!
        let data2 = UIImagePNGRepresentation(transformed)!
        XCTAssert(data1.isEqualToData(data2))
        XCTAssert(expected.pixelsEqualToImage(transformed))
    }
    
    func testPixelWithColor() {
        let pixel = Pixel(color: UIColor.blueColor())
        XCTAssertEqual(pixel.r, 0)
        XCTAssertEqual(pixel.g, 0)
        XCTAssertEqual(pixel.b, 255)
        XCTAssertEqual(pixel.a, 255)
    }
    
    func testPixelMemory() {
        let pixel = Pixel(125, 30, 40, 254)
        let intValue = pixel.uInt32Value
        let pixel2 = Pixel(memory: intValue)
        XCTAssertEqual(intValue, pixel2.uInt32Value)
    }
    
}

class ImageBuilder {
    var squareColors: [UIColor] = []
    func addColor(color: UIColor) -> ImageBuilder {
        self.squareColors.append(color)
        return self
    }
    var image: UIImage {
        UIGraphicsBeginImageContext(CGSizeMake(100, 100))
        let context = UIGraphicsGetCurrentContext()
        for (i, color) in self.squareColors.enumerate() {
            CGContextSetFillColorWithColor(context, color.CGColor)
            let beginningRect = CGRectMake(0, 0, 100, 100)
            CGContextFillRect(context, CGRectInset(beginningRect, CGFloat(i * 10), CGFloat(i * 10)))
        }
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
}

struct PixelSequence: SequenceType, Equatable {
    let image: UIImage
    func generate() -> PixelGenerator {
        return PixelGenerator(image: image)
    }
}

class PixelGenerator: GeneratorType {
    var currentIndex: Int = 0
    let totalIndex: Int
    let context: CGContextRef
    let pixelBuffer: UnsafeMutablePointer<UInt32>
    init(image: UIImage) {
        let cgImage = image.CGImage
        let width = Int(image.size.width)
        let height = Int(image.size.height)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        
        self.context = CGBitmapContextCreate(nil, width, height, 8, width * 4, colorSpace, CGBitmapInfo.ByteOrder32Little.rawValue | CGImageAlphaInfo.PremultipliedFirst.rawValue)!
        CGContextDrawImage(context, CGRectMake(0, 0, image.size.width, image.size.height), cgImage)
        
        let pixelData = CGBitmapContextGetData(context)
        self.pixelBuffer = UnsafeMutablePointer<UInt32>(pixelData)
        self.totalIndex = Int(image.size.width * image.size.height)
    }
    
    typealias Element = Pixel
    func next() -> Pixel? {
        guard currentIndex < totalIndex else { return nil }
        let pixel = UIImage.pbk_pixelAtIndex(currentIndex, pixelBuffer)
        currentIndex += 1
        return pixel
    }
}

func ==(lhs: PixelSequence, rhs: PixelSequence) -> Bool {
    return lhs.elementsEqual(rhs, isEquivalent: { $0 == $1 })
}

extension UIImage {
    func pixelsEqualToImage(other: UIImage) -> Bool {
        let sequences = zip(PixelSequence(image: self), PixelSequence(image: other))
        for x in sequences.enumerate() {
            if x.element.0 != x.element.1 {
                print("bad index: \(x.index)")
            }
        }
        return true
    }
}
