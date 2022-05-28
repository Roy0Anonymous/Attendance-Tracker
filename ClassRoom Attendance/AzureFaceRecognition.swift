//
//  AzureFaceRecognition.swift
//  ClassRoom Attendance
//
//  Created by Rahul Roy on 13/05/22.
//

import UIKit

let APIKey = "ff746215b1ce47c0b2652dd401c093fc"
let Region = "centralindia"
let FindSimilarsUrl = "https://\(Region).api.cognitive.microsoft.com/face/v1.0/findsimilars"
let DetectUrl = "https://\(Region).api.cognitive.microsoft.com/face/v1.0/detect?returnFaceId=true&recognitionModel=recognition_04&detectionModel=detection_03"

var confidence: Float = 0.7

class AzureFaceRecognition: NSObject {

    static let shared = AzureFaceRecognition()
    
    //Provides the Face ID of each face
    func syncDetectFaceIds(imageData: Data) -> [String] {
        var headers: [String: String] = [:]
        headers["Content-Type"] = "application/octet-stream"
        headers["Ocp-Apim-Subscription-Key"] = APIKey
        
        let response = self.makePOSTRequest(url: DetectUrl, postData: imageData, headers: headers)
        let faceIds = extractFaceIds(fromResponse: response)
        
        return faceIds
    }
    
    //Returns matching faces
    func findSimilars(faceId: String, faceIds: [String], completion: @escaping ([String]) -> Void) {
        
        var headers: [String: String] = [:]
        headers["Content-Type"] = "application/json"
        headers["Ocp-Apim-Subscription-Key"] = APIKey
        
        let params: [String: Any] = [
            "faceId": faceId,
            "faceIds": faceIds,
            "mode": "matchPerson"
        ]
        
        // Convert the Dictionary to Data
        let data = try! JSONSerialization.data(withJSONObject: params)
        
        DispatchQueue.global(qos: .background).async {
            let response = self.makePOSTRequest(url: FindSimilarsUrl, postData: data, headers: headers)
            
            let faceIds = self.extractFaceIds(fromResponse: response, minConfidence: confidence)

            DispatchQueue.main.async {
              completion(faceIds)
            }
        }
    }
    
    //Extracts Face IDs
    private func extractFaceIds(fromResponse response: [AnyObject], minConfidence: Float? = nil) -> [String] {
        var faceIds: [String] = []
        for faceInfo in response {
            if let faceId = faceInfo["faceId"] as? String {
                var canAddFace = true
                if minConfidence != nil {
                    let confidence = (faceInfo["confidence"] as! NSNumber).floatValue
                    canAddFace = confidence >= minConfidence!
                }
                if canAddFace {
                    faceIds.append(faceId)
                }
            }
        }
        return faceIds
    }
    
    // Just a function that makes a POST request.
    private func makePOSTRequest(url: String, postData: Data, headers: [String: String] = [:]) -> [AnyObject] {
        var object: [AnyObject] = []

        var request = URLRequest(url: URL(string: url)!)
        request.httpMethod = "POST"
        request.httpBody = postData

        for header in headers {
            request.addValue(header.value, forHTTPHeaderField: header.key)
        }

        // Using semaphore to make request synchronous
        let semaphore = DispatchSemaphore(value: 0)

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let data = data, let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [AnyObject] {
                object = json
            } else {
                if data != nil {
                    print("ERROR response: \(String(data: data!, encoding: .utf8) ?? "")")
                }
            }
            semaphore.signal()
        }

        task.resume()
        _ = semaphore.wait(timeout: DispatchTime.distantFuture)

        return object
    }
}
