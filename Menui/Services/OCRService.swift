//
//  OCRService.swift
//  Menui

//  Uses Apple Vision Framework to extract text lines from images.
//  Runs entirely on-device, no network calls
//
//  Created by Alex on 12/27/25.
//

import Vision
import UIKit

class OCRService {
    /// Extracts text lines from an image using Apple Vision OCR.
    ///  - Parameter image: The image to scan for text
    ///  - Returns: Array of deteced text lines, empty if none are found.
    
    func recognizeText(from image: UIImage) async -> [String] {
        guard let cgImage = image.cgImage else { return []}
        
        return await withCheckedContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                guard let observations = request.results as? [VNRecognizedTextObservation] else{
                    continuation.resume(returning: [])
                    return
                }
                
                let centerObservations = observations.filter { obs in
                    let box = obs.boundingBox
                    let centerX = box.midX
                    let centerY = box.midY
                    
                    return centerX > 0.15 && centerX < 0.85 && centerY > 0.1 && centerY < 0.9
                }
                
                let lines = observations.compactMap { $0.topCandidates(1).first?.string }
                continuation.resume(returning: lines)
            }
            
            request.recognitionLevel = .accurate
            request.recognitionLanguages = ["en-US", "es-419"]
            
            let handler = VNImageRequestHandler(cgImage: cgImage)
            try? handler.perform([request])
        }
    }
}
