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
    
    public func findFootBFS(in pixelBuffer: CVPixelBuffer) -> CGPoint? {
        // from the following line to line 99 is some bullsh*t to unlock the buffer to array.
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
        
        CVPixelBufferLockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
        defer {
            CVPixelBufferUnlockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
        }

        var point: CGPoint?
        
        guard let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer) else {
            return point
        }
        let buffer = baseAddress.assumingMemoryBound(to: UInt8.self)
        
        // start of my BFS
        var visit = Array(repeating: Array(repeating: false, count: height), count: width)
        var largestGroup = [CGPoint]()
        for x in 0..<width {
            for y in 0..<height {
                // well this is how we take the pixel out.
                let pixel = buffer[y * bytesPerRow + x * 4]
                if pixel > 0 && !visit[x][y] {
                    visit[x][y] = true
                    // this is the strange part of my BFS.
                    var group = [CGPoint]()
                    var newMembers = [CGPoint]()
                    var oldMembers = [CGPoint]()
                    newMembers.append(CGPoint(x: x, y: y))
                    while newMembers.count != 0 {
                        oldMembers = newMembers
                        group.append(contentsOf: oldMembers)
                        newMembers = [CGPoint]()
                        for point in oldMembers {
                            let i = Int(point.x)
                            let j = Int(point.y)
                            let abovePixel = buffer[min(j + 1, height) * bytesPerRow + i * 4]
                            let belowPixel = buffer[max(j - 1, 0) * bytesPerRow + i * 4]
                            let rightPixel = buffer[j * bytesPerRow + min(i + 1, width) * 4]
                            let leftPixel = buffer[j * bytesPerRow + max(i - 1, 0) * 4]
                            // normal BFS exploring strategy
                            if abovePixel > 0 && !visit[i][min(j+1, height)] {
                                newMembers.append(CGPoint(x: i, y: j + 1))
                                visit[i][j+1] = true
                            }
                            if belowPixel > 0 && !visit[i][max(j-1, 0)] {
                                newMembers.append(CGPoint(x: i, y: j - 1))
                                visit[i][j-1] = true
                            }
                            if leftPixel > 0 && !visit[max(i - 1, 0)][j] {
                                newMembers.append(CGPoint(x: i-1, y: j))
                                visit[i-1][j] = true
                            }
                            if rightPixel > 0 && !visit[min(i + 1, width)][j] {
                                newMembers.append(CGPoint(x: i+1, y: j))
                                visit[i+1][j] = true
                            }
                        }
                    }
                    // only store the largest group of white pixels.
                    if group.count > largestGroup.count {
                        largestGroup = group
                    }
                }
            }
        }
        // if whites aren't too many, it's a false detection.
        if largestGroup.count < 30 {
            return point
        }
        // another piece of sh*t.
        var maxX = largestGroup[0].x
        var minX = maxX
        var maxY = largestGroup[0].y
        var minY = maxY
        for point in largestGroup {
            maxX = max(maxX, point.x)
            minX = min(minX, point.x)
            maxY = max(maxY, point.y)
            minY = min(minY, point.y)
        }
        // compute the mid point of the group and normalize by dividing by width and height
        point = CGPoint(x: (maxX + minX) / 2 / CGFloat(width), y: (maxY + minY) / 2 / CGFloat(height))
        return point
    }
}
