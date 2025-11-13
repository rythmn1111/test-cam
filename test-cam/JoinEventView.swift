//
//  JoinEventView.swift
//  test-cam
//
//  Join event by scanning QR or entering code
//

import SwiftUI
import AVFoundation

struct JoinEventView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var userName = ""
    @State private var eventCode = ""
    @State private var isJoining = false
    @State private var joinedEvent: Event?
    @State private var error: String?
    @State private var showScanner = false

    private let disposableYellow = Color(red: 1.0, green: 0.85, blue: 0.2)

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.opacity(0.05)
                    .ignoresSafeArea()

                if let event = joinedEvent {
                    eventJoinedView(event: event)
                } else {
                    joinEventForm
                }
            }
            .navigationTitle("Join Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showScanner) {
                QRScannerView { code in
                    eventCode = code
                    showScanner = false
                    joinEvent()
                }
            }
        }
    }

    private var joinEventForm: some View {
        VStack(spacing: 25) {
            Spacer()

            VStack(alignment: .leading, spacing: 15) {
                Text("Join an Event")
                    .font(.title2)
                    .fontWeight(.bold)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Your Name")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    TextField("e.g., John", text: $userName)
                        .textFieldStyle(.roundedBorder)
                        .autocapitalization(.words)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Event Code")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    TextField("Enter code or scan QR", text: $eventCode)
                        .textFieldStyle(.roundedBorder)
                        .autocapitalization(.none)
                }
            }
            .padding(.horizontal)

            if let error = error {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
                    .padding(.horizontal)
            }

            Spacer()

            VStack(spacing: 15) {
                Button(action: { showScanner = true }) {
                    HStack {
                        Image(systemName: "qrcode.viewfinder")
                        Text("Scan QR Code")
                            .fontWeight(.bold)
                    }
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(disposableYellow)
                    .cornerRadius(15)
                }

                Button(action: joinEvent) {
                    HStack {
                        if isJoining {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Image(systemName: "arrow.right.circle.fill")
                            Text("Join Event")
                                .fontWeight(.bold)
                        }
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(15)
                }
                .disabled(userName.isEmpty || eventCode.isEmpty || isJoining)
            }
            .padding(.horizontal)
            .padding(.bottom, 30)
        }
    }

    private func eventJoinedView(event: Event) -> some View {
        VStack(spacing: 30) {
            Spacer()

            VStack(spacing: 15) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.green)

                Text("You're In!")
                    .font(.title)
                    .fontWeight(.bold)

                Text(event.name)
                    .font(.title2)
                    .foregroundColor(.secondary)

                Text("You have 10 shots")
                    .font(.headline)
                    .foregroundColor(.orange)
            }

            Spacer()

            NavigationLink(destination: EventCameraView(eventId: event.id, userName: userName)) {
                HStack {
                    Image(systemName: "camera.fill")
                    Text("Start Taking Photos")
                        .fontWeight(.bold)
                }
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding()
                .background(disposableYellow)
                .cornerRadius(15)
            }
            .padding(.horizontal)
            .padding(.bottom, 30)
        }
    }

    private func joinEvent() {
        guard !userName.isEmpty, !eventCode.isEmpty else { return }

        isJoining = true
        error = nil

        Task {
            do {
                let event = try await PocketBaseService.shared.getEventByQRCode(eventCode)
                let _ = try await PocketBaseService.shared.joinEvent(eventId: event.id, userName: userName)

                await MainActor.run {
                    joinedEvent = event
                    isJoining = false
                }
            } catch {
                await MainActor.run {
                    self.error = "Event not found. Check the code and try again."
                    isJoining = false
                }
            }
        }
    }
}

// QR Code Scanner View
struct QRScannerView: UIViewControllerRepresentable {
    let onCodeScanned: (String) -> Void

    func makeUIViewController(context: Context) -> QRScannerViewController {
        let controller = QRScannerViewController()
        controller.onCodeScanned = onCodeScanned
        return controller
    }

    func updateUIViewController(_ uiViewController: QRScannerViewController, context: Context) {}
}

class QRScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    var onCodeScanned: ((String) -> Void)?
    private var captureSession: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupScanner()
    }

    private func setupScanner() {
        captureSession = AVCaptureSession()

        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return }
        let videoInput: AVCaptureDeviceInput

        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            return
        }

        guard let captureSession = captureSession else { return }

        if captureSession.canAddInput(videoInput) {
            captureSession.addInput(videoInput)
        } else {
            return
        }

        let metadataOutput = AVCaptureMetadataOutput()

        if captureSession.canAddOutput(metadataOutput) {
            captureSession.addOutput(metadataOutput)
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.qr]
        } else {
            return
        }

        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer?.frame = view.layer.bounds
        previewLayer?.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer!)

        DispatchQueue.global(qos: .userInitiated).async {
            captureSession.startRunning()
        }
    }

    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        if let metadataObject = metadataObjects.first,
           let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject,
           let stringValue = readableObject.stringValue {
            captureSession?.stopRunning()
            onCodeScanned?(stringValue)
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        captureSession?.stopRunning()
    }
}

#Preview {
    JoinEventView()
}
