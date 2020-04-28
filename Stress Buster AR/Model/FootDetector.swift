//
//  FootDetector.swift
//  Stress Buster AR
//
//  Created by Jason Wang on 4/24/20.
//  Copyright © 2020 Jason Wang. All rights reserved.
//

import CoreML
import Vision

class FootDetector {
    private let visionQueue = DispatchQueue(label: "vision")
    private var requests = [VNRequest]()
    
    public func setUpVision() {
        guard let model = try? VNCoreMLModel(for: FootSeg().model) else {
            fatalError("Can't load model.")
        }
        let request = VNCoreMLRequest(model: model)
        request.imageCropAndScaleOption = .scaleFill
        requests = [request]
    }
    
    public func predict(input: CVPixelBuffer, orientation: CGImagePropertyOrientation, completion: @escaping (_ outputBuffer: CVPixelBuffer?, _ error: Error?) -> Void) {
        let handler = VNImageRequestHandler(cvPixelBuffer: input, orientation: orientation)
        visionQueue.async {
            do {
                try handler.perform(self.requests)
            } catch {
                completion(nil, error)
            }
            guard let results = self.requests[0].results, !results.isEmpty else {
                return
            }
            guard let obs = results.first as? VNPixelBufferObservation else {
                return
            }
            completion(obs.pixelBuffer, nil)
        }
    }
    
    public func findFoot(in pixelBuffer: CVPixelBuffer) -> CGPoint? {
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
        
        CVPixelBufferLockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
        defer {
            CVPixelBufferUnlockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
        }

        var point: CGPoint?
        var numWhites = 0
        
        if let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer) {
            let buffer = baseAddress.assumingMemoryBound(to: UInt8.self)
        
            
            for y in (0..<height).reversed() {
                for x in (0..<width).reversed() {
                    let pixel = buffer[y * bytesPerRow + x * 4]
                    let abovePixel = buffer[min(y + 1, height) * bytesPerRow + x * 4]
                    let belowPixel = buffer[max(y - 1, 0) * bytesPerRow + x * 4]
                    let rightPixel = buffer[y * bytesPerRow + min(x + 1, width) * 4]
                    let leftPixel = buffer[y * bytesPerRow + max(x - 1, 0) * 4]
                    if pixel > 0 && abovePixel > 0 && belowPixel > 0 && rightPixel > 0 && leftPixel > 0 {
                        let newPoint = CGPoint(x: x, y: y)
                        point = CGPoint(x: newPoint.x / CGFloat(width), y: newPoint.y / CGFloat(height))
                        numWhites += 1
                    }
                }
            }
        }
        
        // if too few pixels are white, call it a false detection.
        if numWhites < 20 {
            point = nil
        }
        return point
    }
}
