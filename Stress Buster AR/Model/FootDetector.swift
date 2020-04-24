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
}
