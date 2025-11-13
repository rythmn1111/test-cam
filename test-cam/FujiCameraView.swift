//
//  FujiCameraView.swift
//  test-cam
//
//  Fujifilm-inspired camera interface
//

import SwiftUI
import AVFoundation

struct FujiCameraView: View {
    @StateObject private var cameraManager = CameraManager()
    @State private var selectedSimulation: FujifilmFilter.FilmSimulation = .classicChrome
    @State private var showingPreview = false
    @State private var filteredImage: UIImage?
    @State private var isSaving = false

    private let fujiGreen = Color(red: 0.0, green: 0.5, blue: 0.4)
    private let fujiDarkGreen = Color(red: 0.0, green: 0.3, blue: 0.25)

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if cameraManager.isCameraAuthorized {
                if showingPreview, let image = filteredImage {
                    previewView(image: image)
                } else {
                    cameraView
                }
            } else {
                permissionView
            }
        }
        .onAppear {
            cameraManager.checkPermissions()
        }
        .onChange(of: cameraManager.isPhotoTaken) { oldValue, newValue in
            if newValue, let image = cameraManager.capturedImage {
                applyFilterAndShowPreview(image)
            }
        }
        .alert("Camera Error", isPresented: $cameraManager.showingAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(cameraManager.alertMessage)
        }
    }

    private var cameraView: some View {
        GeometryReader { geometry in
            ZStack {
                // Camera Preview
                CameraPreview(cameraManager: cameraManager)
                    .ignoresSafeArea()

                // Fuji-style overlay
                VStack {
                    // Top bar with Fuji branding
                    HStack {
                        Text("FUJI")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(fujiGreen)
                            .padding(.leading)

                        Spacer()

                        Text("RESTAURANT")
                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                            .foregroundColor(.white.opacity(0.8))
                            .padding(.trailing)
                    }
                    .padding(.top, 50)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.black.opacity(0.6), Color.clear]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                    Spacer()

                    // Film simulation selector
                    filmSimulationPicker

                    // Bottom controls
                    bottomControls
                        .padding(.bottom, 40)
                }
            }
        }
    }

    private var filmSimulationPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 15) {
                ForEach([
                    FujifilmFilter.FilmSimulation.classicChrome,
                    .velvia,
                    .provia,
                    .astia
                ], id: \.name) { simulation in
                    FilmSimulationButton(
                        title: simulation.name,
                        isSelected: selectedSimulation.name == simulation.name,
                        fujiGreen: fujiGreen
                    ) {
                        selectedSimulation = simulation
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.bottom, 20)
    }

    private var bottomControls: some View {
        HStack(spacing: 40) {
            Spacer()

            // Shutter button
            Button(action: capturePhoto) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.3))
                        .frame(width: 80, height: 80)

                    Circle()
                        .stroke(fujiGreen, lineWidth: 4)
                        .frame(width: 80, height: 80)

                    Circle()
                        .fill(cameraManager.isCapturing ? fujiDarkGreen : fujiGreen)
                        .frame(width: 60, height: 60)

                    Circle()
                        .fill(fujiDarkGreen)
                        .frame(width: 50, height: 50)
                        .opacity(cameraManager.isCapturing ? 0.5 : 1.0)
                }
            }
            .disabled(cameraManager.isCapturing)

            Spacer()
        }
    }

    private var permissionView: some View {
        VStack(spacing: 20) {
            Image(systemName: "camera.fill")
                .font(.system(size: 60))
                .foregroundColor(fujiGreen)

            Text("Camera Access Required")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)

            Text("Please enable camera access in Settings to capture beautiful restaurant photos.")
                .multilineTextAlignment(.center)
                .foregroundColor(.white.opacity(0.8))
                .padding(.horizontal, 40)

            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .padding()
            .background(fujiGreen)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
    }

    private func previewView(image: UIImage) -> some View {
        VStack {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .ignoresSafeArea()

            HStack(spacing: 30) {
                Button(action: {
                    showingPreview = false
                    filteredImage = nil
                    cameraManager.resetPhoto()
                    cameraManager.startSession()
                }) {
                    HStack {
                        Image(systemName: "arrow.left")
                        Text("Retake")
                    }
                    .foregroundColor(fujiGreen)
                    .padding()
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(10)
                }

                Button(action: savePhoto) {
                    HStack {
                        Image(systemName: "square.and.arrow.down")
                        Text(isSaving ? "Saving..." : "Save")
                    }
                    .foregroundColor(.white)
                    .padding()
                    .background(fujiGreen)
                    .cornerRadius(10)
                }
                .disabled(isSaving)
            }
            .padding(.bottom, 40)
        }
    }

    private func capturePhoto() {
        cameraManager.capturePhoto()
    }

    private func applyFilterAndShowPreview(_ image: UIImage) {
        DispatchQueue.global(qos: .userInitiated).async {
            let filter = FujifilmFilter()
            let filtered = filter.applyFilter(to: image, simulation: selectedSimulation)

            DispatchQueue.main.async {
                filteredImage = filtered
                showingPreview = true
                cameraManager.stopSession()
            }
        }
    }

    private func savePhoto() {
        guard let image = filteredImage else { return }

        isSaving = true
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            isSaving = false
            showingPreview = false
            filteredImage = nil
            cameraManager.resetPhoto()
            cameraManager.startSession()
        }
    }
}

struct FilmSimulationButton: View {
    let title: String
    let isSelected: Bool
    let fujiGreen: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .foregroundColor(isSelected ? .black : .white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(isSelected ? fujiGreen : Color.white.opacity(0.2))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(fujiGreen, lineWidth: isSelected ? 0 : 1)
                )
        }
    }
}

struct CameraPreview: UIViewRepresentable {
    let cameraManager: CameraManager

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = .black

        let previewLayer = cameraManager.getPreviewLayer()
        previewLayer.frame = view.bounds
        view.layer.addSublayer(previewLayer)

        DispatchQueue.main.async {
            cameraManager.startSession()
        }

        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        if let layer = uiView.layer.sublayers?.first as? AVCaptureVideoPreviewLayer {
            DispatchQueue.main.async {
                layer.frame = uiView.bounds
            }
        }
    }
}

#Preview {
    FujiCameraView()
}
