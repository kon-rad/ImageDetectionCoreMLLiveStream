//
//  ViewController.swift
//  ImageDetectionCoreMLLiveStream
//
//  Created by Konrad Gnat on 3/13/20.
//  Copyright © 2020 Konrad Gnat. All rights reserved.
//

import UIKit
import AVFoundation
import CoreML
import Vision

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var textView: UITextView!
    
    // initialize core ml model
    private let inceptionModel = Inceptionv3()
    
    private var requests = [VNCoreMLRequest]()
    
    let session = AVCaptureSession()
    
    // program starts here
    override func viewDidLoad() {
        super.viewDidLoad()
        
        createImageRequest()
        startLiveVideo()
    }
    
    private func createImageRequest() {

        print("inside createImageRequest")
        guard let model = try? VNCoreMLModel(for: self.inceptionModel.model) else {
            fatalError("problem creating a core ml model")
        }
        
        let request = VNCoreMLRequest(model: model) {
            request, error in
            
            print("inside request")
            
            if error != nil {
                return
            }
            
            guard let observations = request.results as? [VNClassificationObservation] else {
                return
            }
            
            // observations are found
            // get the identifier (what the model thinks it is)
            // and the confidence
            let classifications = observations.map { observation in
                "\(observation.identifier) \(observation.confidence * 100.0)"
            }
            
            DispatchQueue.main.async {
                self.textView.text = classifications.joined(separator: "\n")
            }
        }
        
        // append coreML request to the request array
        self.requests.append(request)
    }
    
    // capture output method
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        print("inside captureOutput")
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        
        // create request options dictionary
        var requestOptions:[VNImageOption : Any] = [:]
        
        // pass to GM attachment that will give us camera data
        // then pass to get the request options
        if let camData = CMGetAttachment(sampleBuffer, key: kCMSampleBufferAttachmentKey_CameraIntrinsicMatrix, attachmentModeOut: nil) {
            requestOptions = [.cameraIntrinsics:camData]
        }
        
        // the get image request handler, and fire the request
        // will be portrait mode
        // options declared previously
        let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: CGImagePropertyOrientation(rawValue: 6)!, options: requestOptions)
        
        do {
            // pass the vm coreML model request
            try imageRequestHandler.perform(self.requests)
        } catch {
            print(error)
        }
    }

    private func startLiveVideo() {
        
        print("inside startLiveVideo")
        session.sessionPreset = AVCaptureSession.Preset.photo
        let captureDevice = AVCaptureDevice.default(for: .video)
        
        let deviceInput = try! AVCaptureDeviceInput(device: captureDevice!)
        let deviceOutput = AVCaptureVideoDataOutput()
        
        // setup the device video setting
        deviceOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)]
        // setup the device sample delegate
        deviceOutput.setSampleBufferDelegate(self, queue: DispatchQueue.global(qos: DispatchQoS.QoSClass.default))
        
        // add to session
        session.addInput(deviceInput)
        session.addOutput(deviceOutput)
        
        let imageLayer = AVCaptureVideoPreviewLayer(session: session)
        // set image layer frame to image we already have on the screen
        imageLayer.frame = imageView.bounds
        
        // add layer to the image view, a layer that has the actual
        // video that is running
        imageView.layer.addSublayer(imageLayer)
        
        
        // start the session
        session.startRunning()
    }

}

