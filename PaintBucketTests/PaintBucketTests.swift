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
    
    func benchmarkLargeImagePerformance() {
        let image = UIImage(named: "benchmark", inBundle: NSBundle(forClass: self.dynamicType), compatibleWithTraitCollection: nil)!
        measureBlock {
            image.pbk_imageByReplacingColorAt(1, 1, withColor: UIColor.clearColor(), tolerance: 70)
        }
    }
    
    func testLargeImage_backgroundThread() {
        let image = UIImage(named: "test", inBundle: NSBundle(forClass: self.dynamicType), compatibleWithTraitCollection: nil)!
        let expectation = self.expectationWithDescription("yay")
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            image.pbk_imageByReplacingColorAt(1, 1, withColor: UIColor.clearColor(), tolerance: 70)
            expectation.fulfill()
        }
        waitForExpectationsWithTimeout(10, handler: nil)
    }
    
    func testLoadedImage() {
        let image = UIImage(named: "test", inBundle: NSBundle(forClass: self.dynamicType), compatibleWithTraitCollection: nil)!
        let expected = UIImage(named: "test_output", inBundle: NSBundle(forClass: self.dynamicType), compatibleWithTraitCollection: nil)!
        let transformed = image.pbk_imageByReplacingColorAt(1, 1, withColor: UIColor.clearColor(), tolerance: 100)
        let data1 = UIImagePNGRepresentation(expected)!
        let data2 = UIImagePNGRepresentation(transformed)!
        XCTAssert(data1.isEqualToData(data2))
    }
    
    func testTinySquare() {
        let image = ImageBuilder(edgeLength: 4).addColor(.redColor()).addColor(.greenColor()).image
        let expected = ImageBuilder(edgeLength: 4).addColor(.blueColor()).addColor(.greenColor()).image
        let transformed = image.pbk_imageByReplacingColorAt(0, 0, withColor: UIColor.blueColor(), tolerance: 100)
        let data1 = UIImagePNGRepresentation(expected)!
        let data2 = UIImagePNGRepresentation(transformed)!
        XCTAssert(data1.isEqualToData(data2))
    }
    
    func testTinySquare_CenterCoordinate() {
        let image = ImageBuilder(edgeLength: 5).addColor(.redColor()).addColor(.greenColor()).image
        let expected = ImageBuilder(edgeLength: 5).addColor(.redColor()).image
        let transformed = image.pbk_imageByReplacingColorAt(2, 2, withColor: UIColor.redColor(), tolerance: 100)
        let data1 = UIImagePNGRepresentation(expected)!
        let data2 = UIImagePNGRepresentation(transformed)!
        XCTAssert(data1.isEqualToData(data2))
    }
    
    func testTinySquare_Boundary() {
        let image = ImageBuilder(edgeLength: 9).addColor(.blueColor()).addColor(.greenColor()).image
        let expected = ImageBuilder(edgeLength: 9).addColor(.greenColor()).image
        let transformed = image.pbk_imageByReplacingColorAt(1, 1, withColor: UIColor.greenColor(), tolerance: 100)
        let data1 = UIImagePNGRepresentation(expected)!
        let data2 = UIImagePNGRepresentation(transformed)!
        XCTAssert(data1.isEqualToData(data2))
    }
    
    func testTolerance() {
        let color1 = UIColor(red: 1.0, green: 1.0, blue: 254.0/255.0, alpha: 1.0)
        let color2 = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        let color3 = UIColor.redColor()
        let image = ImageBuilder().addColor(color1).addColor(color2).image
        let expected = ImageBuilder().addColor(color3).addColor(color2).image
        let transformed = image.pbk_imageByReplacingColorAt(0, 0, withColor: color3, tolerance: 0)
        let data1 = UIImagePNGRepresentation(expected)!
        let data2 = UIImagePNGRepresentation(transformed)!
        XCTAssert(data1.isEqualToData(data2))
    }
    
    func testTolerance_High() {
        let color1 = UIColor(red: 1.0, green: 1.0, blue: 254.0/255.0, alpha: 1.0)
        let color2 = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        let color3 = UIColor.redColor()
        let image = ImageBuilder().addColor(color1).addColor(color2).image
        let expected = ImageBuilder().addColor(color3).image
        let transformed = image.pbk_imageByReplacingColorAt(0, 0, withColor: color3, tolerance: 2)
        let data1 = UIImagePNGRepresentation(expected)!
        let data2 = UIImagePNGRepresentation(transformed)!
        XCTAssert(data1.isEqualToData(data2))
    }
    
    func testBasicSquare() {
        let image = ImageBuilder().addColor(.redColor()).addColor(.greenColor()).image
        let expected = ImageBuilder().addColor(.blueColor()).addColor(.greenColor()).image
        let transformed = image.pbk_imageByReplacingColorAt(0, 0, withColor: UIColor.blueColor(), tolerance: 100)
        let data1 = UIImagePNGRepresentation(expected)!
        let data2 = UIImagePNGRepresentation(transformed)!
        XCTAssert(data1.isEqualToData(data2))
    }
    
    func testBasicSquare_CenterCoordinate() {
        let image = ImageBuilder().addColor(.redColor()).addColor(.greenColor()).image
        let expected = ImageBuilder().addColor(.redColor()).addColor(.blueColor()).image
        let transformed = image.pbk_imageByReplacingColorAt(50, 50, withColor: UIColor.blueColor(), tolerance: 100)
        let data1 = UIImagePNGRepresentation(expected)!
        let data2 = UIImagePNGRepresentation(transformed)!
        XCTAssert(data1.isEqualToData(data2))
    }
    
    func testBasicSquare_Boundary1() {
        let image = ImageBuilder().addColor(.redColor()).addColor(.greenColor()).image
        let expected = ImageBuilder().addColor(.blueColor()).addColor(.greenColor()).image
        let transformed = image.pbk_imageByReplacingColorAt(10, 40, withColor: UIColor.blueColor(), tolerance: 100)
        let data1 = UIImagePNGRepresentation(expected)!
        let data2 = UIImagePNGRepresentation(transformed)!
        XCTAssert(data1.isEqualToData(data2))
    }
    
    func testBasicSquare_Boundary2() {
        let image = ImageBuilder().addColor(.redColor()).addColor(.greenColor()).image
        let expected = ImageBuilder().addColor(.redColor()).addColor(.blueColor()).image
        let transformed = image.pbk_imageByReplacingColorAt(25, 50, withColor: UIColor.blueColor(), tolerance: 100)
        let data1 = UIImagePNGRepresentation(expected)!
        let data2 = UIImagePNGRepresentation(transformed)!
        XCTAssert(data1.isEqualToData(data2))
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
    let edgeLength: CGFloat
    init(edgeLength: CGFloat = 100) {
        self.edgeLength = edgeLength
    }
    var squareColors: [UIColor] = []
    func addColor(color: UIColor) -> ImageBuilder {
        self.squareColors.append(color)
        return self
    }
    var image: UIImage {
        UIGraphicsBeginImageContext(CGSizeMake(self.edgeLength, self.edgeLength))
        let context = UIGraphicsGetCurrentContext()
        for (i, color) in self.squareColors.enumerate() {
            CGContextSetFillColorWithColor(context, color.CGColor)
            let beginningRect = CGRectMake(0, 0, self.edgeLength, self.edgeLength)
            let inset = CGFloat(Int(CGFloat(i) * (self.edgeLength / CGFloat(self.squareColors.count))) / 2)
            CGContextFillRect(context, CGRectInset(beginningRect, inset, inset))
        }
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
}
