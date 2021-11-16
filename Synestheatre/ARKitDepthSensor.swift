//
//  ARKitDepthSensor.swift
//  Synestheatre
//
//  Created by James on 12/10/2021.
//  Copyright © 2021 James. All rights reserved.
//

import Foundation
import ARKit

/**
  *
  * Launches the ARKit API and passes depth and rgb data to synestheatre
  * https://www.it-jim.com/blog/iphones-12-pro-lidar-how-to-get-and-interpret-data/
 */
class ARKitDepthSensor : NSObject, DepthSensor, ARSessionDelegate {
    var session: ARSession!
    
    var updateStatusBlock: ((String?) -> Void)!
    
    var newDataBlock: (() -> Void)!
    
    var _rows : Int = 0
    var _cols : Int = 0
    var _heightScale : Double = 0
    var _widthScale : Double = 0
    
    func start() {
        session = ARSession()
        session.delegate = self
        
        let configuration = setupARConfiguration()
        session.run(configuration)
    }
    
    func setupARConfiguration() -> ARConfiguration{
        let configuration = ARWorldTrackingConfiguration()
        
        if ARWorldTrackingConfiguration.supportsFrameSemantics(.sceneDepth) {
            configuration.frameSemantics = .sceneDepth
        }
        
        return configuration
    }
    
    func stop() {
        guard let session = session else { return }
        session.pause()
        self.session = nil
    }
    
    func getImage() -> UIImage! {
        guard let currentFrame = session.currentFrame else { return nil }
        
    
        // Prepare RGB image to save
        let frameImage = currentFrame.capturedImage
        let imageSize = CGSize(width: CVPixelBufferGetWidth(frameImage),
                               height: CVPixelBufferGetHeight(frameImage))
        let ciImage = CIImage(cvPixelBuffer: frameImage)
        let context = CIContext.init(options: nil)
        
        guard let cgImageRef = context.createCGImage(ciImage, from: CGRect(x: 0, y: 0, width: imageSize.width, height: imageSize.height)) else { return nil }
        let uiImage = UIImage(cgImage: cgImageRef)
        
        return uiImage
    
    }
    
    func setViewWindowWithRows(_ rows: Int32, cols: Int32, heightScale: Float, widthScale: Float) {
        _rows = Int(rows)
        _cols = Int(cols)
        _heightScale = Double(heightScale)
        _widthScale = Double(widthScale)
    }
    
    func getDepthInMillimeters(_ outArray: UnsafeMutablePointer<Float>!) -> Bool {
        guard let currentFrame = session.currentFrame else { return false }
            

        guard let depthData = currentFrame.sceneDepth?.depthMap else { return false }
    
    
        CVPixelBufferLockBaseAddress(depthData, CVPixelBufferLockFlags(rawValue: 0));
        let width = CVPixelBufferGetWidth(depthData)
        let height = CVPixelBufferGetHeight(depthData)
        
        let baseAddress = CVPixelBufferGetBaseAddress(depthData);
        
        if (baseAddress == nil) {
            CVPixelBufferUnlockBaseAddress(depthData, CVPixelBufferLockFlags(rawValue: 0));
            return false;
        }
        
        let floatBuffer = unsafeBitCast(baseAddress, to: UnsafeMutablePointer<Float32>.self)
        
        //https://developer.apple.com/videos/play/wwdc2017/507/
        //Use 32 bit when on cpu, 16 on gpu
        //OSType type = CVPixelBufferGetPixelFormatType( pixelBuffer);
        //if (type != kCVPixelFormatType_DepthFloat32) {exit(0);}
        
        var x_ratio : Double
        var y_ratio : Double
        
        var x_left : Double
        var y_top : Double
        
        // Case when only one col or row
        if (_cols == 1) {
            x_ratio = 0
            x_left = Double(width) / 2
        } else {
            x_ratio = _widthScale * (Double(width) - 1) / Double(_cols - 1)
            x_left = (Double(width) - (Double(width) * _widthScale)) / 2
        }
        
        if (_rows == 1) {
            y_ratio = 0;
            y_top = Double(height) / 2;
        } else {
            y_ratio = _heightScale * (Double(height) - 1) / Double(_rows - 1);
            y_top = (Double(height) - (Double(height) * _heightScale)) / 2;
        }
        
        
        //sample using nearest neighbor
        for col in 0..._cols-1 {
            for row in 0..._rows-1 {

                let nearestX = Int(round(x_left + (x_ratio * Double(col))))
                let nearestY = Int(round(y_top + (y_ratio * Double(row))))
                

                let depthArrayIndex = nearestY  * width + nearestX;
                let depthPixel = floatBuffer[depthArrayIndex];
                
                let arrayIndex : Int = (row * _cols) + col;
                
                outArray[arrayIndex] = Float(depthPixel * 1000); // Convert from meters to mm
                
            }
        }
        CVPixelBufferUnlockBaseAddress(depthData, CVPixelBufferLockFlags(rawValue: 0));
        return true;
    }
    
    func getColours(_ outArray: UnsafeMutablePointer<Colour>!) -> Bool {
        
        guard let currentFrame = session.currentFrame else { return false }
        
        let frameImage : CVPixelBuffer = currentFrame.capturedImage
        let imageSize = CGSize(width: CVPixelBufferGetWidth(frameImage),
                               height: CVPixelBufferGetHeight(frameImage))
        let ciImage = CIImage(cvPixelBuffer: frameImage)
        let context = CIContext.init(options: nil)
        
        guard let cgImageRef = context.createCGImage(ciImage, from: CGRect(x: 0, y: 0, width: imageSize.width, height: imageSize.height)) else { return false }
        
        let width = cgImageRef.width;
        let height = cgImageRef.height;
        let bytesPerPixel = 4;
        let bytesPerRow = bytesPerPixel * width;
        let bitsPerComponent = 8;
        
        let pixels = [UInt32](repeating: 0, count: height * width)
        
        
        let colorSpace = CGColorSpaceCreateDeviceRGB();


        let ctx = CGContext(data: UnsafeMutableRawPointer(mutating: pixels), width: width, height: height, bitsPerComponent: bitsPerComponent, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: CGBitmapInfo.byteOrder32Big.rawValue);
            
        ctx?.draw(cgImageRef, in: CGRect(x: 0, y: 0, width: CGFloat(width), height: CGFloat(height)) );
            

        
        var x_ratio : Double
        var y_ratio : Double
        
        var x_left : Double
        var y_top : Double
        
        // Case when only one col or row
        if (_cols == 1) {
            x_ratio = 0
            x_left = Double(width) / 2
        } else {
            x_ratio = _widthScale * (Double(width) - 1) / Double(_cols - 1)
            x_left = (Double(width) - (Double(width) * _widthScale)) / 2
        }
        
        if (_rows == 1) {
            y_ratio = 0;
            y_top = Double(height) / 2;
        } else {
            y_ratio = _heightScale * (Double(height) - 1) / Double(_rows - 1);
            y_top = (Double(height) - (Double(height) * _heightScale)) / 2;
        }
       
        
        let gridWidth = 10;
        let gridSize = 2;
        let limit = gridWidth * gridSize;
            
        //sample using nearest neighbor
        for col in 0..._cols-1 {
            for row in 0..._rows-1 {

                let nearestX = Int(round(x_left + (x_ratio * Double(col))))
                let nearestY = Int(round(y_top + (y_ratio * Double(row))))
                
                
                var c = Colour(r: 0, g: 0, b: 0)
                var nPixels : UInt32 = 0;
                
                let leftX = max(0, nearestX - limit);
                let rightX = min(width, nearestX + limit);
                let topY = max(0,nearestY - limit);
                let bottomY = min(height, nearestY + limit);
                
                for innerX in stride(from: leftX, through: rightX, by: gridWidth) {
                    for innerY in stride(from: topY, through: bottomY, by: gridWidth) {
                        
                        let depthArrayIndex = innerY  * width + innerX;
                        let color : UInt32 = pixels[depthArrayIndex];
                        let newC = ConvertUint32(color);
                        
                        c.r += newC.r;
                        c.g += newC.g;
                        c.b += newC.b;
                        nPixels += 1;
                        
                    }
                }
                
                c.r /= nPixels;
                c.g /= nPixels;
                c.b /= nPixels;
                
                
                let arrayIndex = (row * _cols) + col;
                
                outArray[arrayIndex] = c;
            }
        }
            
        return true;
    }
    
    func getColourImage() -> UIImage! {
        
        guard let currentFrame = session.currentFrame else { return nil }
        
        // Prepare RGB image to save
        let frameImage : CVPixelBuffer = currentFrame.capturedImage
        let imageSize = CGSize(width: CVPixelBufferGetWidth(frameImage),
                               height: CVPixelBufferGetHeight(frameImage))
        let ciImage = CIImage(cvPixelBuffer: frameImage)
        
        return UIImage(ciImage: ciImage)
    }
    
    func getCentreDebugInfo() -> String! {
        
        guard let currentFrame = session.currentFrame else { return "No session active" }
            

        guard let depthData = currentFrame.sceneDepth?.depthMap else { return "No depth data from session" }
    
    
        CVPixelBufferLockBaseAddress(depthData, CVPixelBufferLockFlags(rawValue: 0))
        defer {
            CVPixelBufferUnlockBaseAddress(depthData, CVPixelBufferLockFlags(rawValue: 0))
        }
        
        let width = CVPixelBufferGetWidth(depthData)
        let height = CVPixelBufferGetHeight(depthData)
        
        if (frame_cols == 0 || frame_rows == 0) {
            return "No data"
        }
        
        guard let baseAddress = CVPixelBufferGetBaseAddress(depthData) else {
            return "Error 41"
        }
        
        let floatBuffer = unsafeBitCast(baseAddress, to: UnsafeMutablePointer<Float32>.self)
    
        let nearestX = width / 2
        let nearestY = height / 2
        let depthArrayIndex : Int = nearestY  * width + nearestX
        let depthPixel : Float32 = baseAddress[depthArrayIndex];
        

        return String(format:"Dual cam depth: %.f mm",depthPixel * 1000);
    }
    
    func getType() -> String! {
        return "ARKit"
    }
    
    func isSensorConnected() -> Bool {
        return true
    }
    
    func sensorDisconnectionReason() -> String! {
        return "Unknown"
    }
    
}
