//
//  CameraManager.swift
//  test-cam
//
//  Camera functionality handler
//

import AVFoundation
import UIKit
import SwiftUI
import Combine

class CameraManager: NSObject, ObservableObject {
    @Published var capturedImage: UIImage?
    @Published var isPhotoTaken = false
    @Published var isCameraAuthorized = false
    @Published var showingAlert = false
    @Published var alertMessage = ""
    @Published var isCapturing = false

    private let captureSession = AVCaptureSession()
    private var videoOutput = AVCaptureVideoDataOutput()
    private var photoOutput = AVCapturePhotoOutput()
    private let sessionQueue = DispatchQueue(label: "camera.session.queue")

    var previewLayer: AVCaptureVideoPreviewLayer?

    override init() {
        super.init()
    }

    func checkPermissions() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            isCameraAuthorized = true
            setupCamera()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    self?.isCameraAuthorized = granted
                    if granted {
                        self?.setupCamera()
                    }
                }
            }
        case .denied, .restricted:
            isCameraAuthorized = false
            alertMessage = "Camera access is required. Please enable it in Settings."
            showingAlert = true
        @unknown default:
            break
        }
    }

    private func setupCamera() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }

            self.captureSession.beginConfiguration()
            self.captureSession.sessionPreset = .photo

            // Setup camera input
            guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
                  let videoInput = try? AVCaptureDeviceInput(device: videoDevice),
                  self.captureSession.canAddInput(videoInput) else {
                DispatchQueue.main.async {
                    self.alertMessage = "Failed to setup camera"
                    self.showingAlert = true
                }
                return
            }

            self.captureSession.addInput(videoInput)

            // Setup photo output
            if self.captureSession.canAddOutput(self.photoOutput) {
                self.captureSession.addOutput(self.photoOutput)
                self.photoOutput.maxPhotoQualityPrioritization = .quality
            }

            self.captureSession.commitConfiguration()
        }
    }

    func startSession() {
        sessionQueue.async { [weak self] in
            guard let self = self, !self.captureSession.isRunning else { return }
            self.captureSession.startRunning()
        }
    }

    func stopSession() {
        sessionQueue.async { [weak self] in
            guard let self = self, self.captureSession.isRunning else { return }
            self.captureSession.stopRunning()
        }
    }

    func capturePhoto() {
        guard !isCapturing else { return }

        DispatchQueue.main.async {
            self.isCapturing = true
        }

        let photoSettings = AVCapturePhotoSettings()
        photoSettings.flashMode = .auto

        photoOutput.capturePhoto(with: photoSettings, delegate: self)
    }

    func getPreviewLayer() -> AVCaptureVideoPreviewLayer {
        if let existingLayer = previewLayer {
            return existingLayer
        }

        let layer = AVCaptureVideoPreviewLayer(session: captureSession)
        layer.videoGravity = .resizeAspectFill
        previewLayer = layer
        return layer
    }

    func resetPhoto() {
        DispatchQueue.main.async {
            self.capturedImage = nil
            self.isPhotoTaken = false
            self.isCapturing = false
        }
    }
}

extension CameraManager: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            DispatchQueue.main.async {
                self.alertMessage = "Failed to capture photo: \(error.localizedDescription)"
                self.showingAlert = true
                self.isCapturing = false
            }
            return
        }

        guard let imageData = photo.fileDataRepresentation(),
              var image = UIImage(data: imageData) else {
            DispatchQueue.main.async {
                self.isCapturing = false
            }
            return
        }

        // Fix orientation - ensure image is displayed correctly
        if image.imageOrientation != .up {
            UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale)
            image.draw(in: CGRect(origin: .zero, size: image.size))
            if let normalizedImage = UIGraphicsGetImageFromCurrentImageContext() {
                image = normalizedImage
            }
            UIGraphicsEndImageContext()
        }

        DispatchQueue.main.async {
            self.capturedImage = image
            self.isPhotoTaken = true
            self.isCapturing = false
        }
    }
}
