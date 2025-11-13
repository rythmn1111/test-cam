//
//  EventCameraView.swift
//  test-cam
//
//  Disposable camera UI for event photos
//

import SwiftUI

struct EventCameraView: View {
    let eventId: String
    let userName: String

    @StateObject private var cameraManager = CameraManager()
    @State private var participant: EventParticipant?
    @State private var shotsRemaining = 10
    @State private var showingGallery = false
    @State private var isUploading = false
    @State private var showFlash = false
    @State private var filteredImage: UIImage?
    @State private var showingPreview = false

    private let disposableYellow = Color(red: 1.0, green: 0.85, blue: 0.2)
    private let disposableOrange = Color(red: 1.0, green: 0.6, blue: 0.0)

    var body: some View {
        ZStack {
            if showingPreview, let image = filteredImage {
                previewView(image: image)
            } else {
                cameraView
            }

            // Flash effect
            if showFlash {
                Color.white
                    .ignoresSafeArea()
                    .transition(.opacity)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                HStack {
                    Image(systemName: "camera.fill")
                        .foregroundColor(disposableOrange)
                    Text("SnapParty")
                        .font(.headline)
                        .foregroundColor(disposableOrange)
                }
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingGallery = true }) {
                    Image(systemName: "photo.on.rectangle")
                        .foregroundColor(disposableOrange)
                }
            }
        }
        .onAppear {
            cameraManager.checkPermissions()
            loadParticipant()
        }
        .onChange(of: cameraManager.isPhotoTaken) { oldValue, newValue in
            if newValue, let image = cameraManager.capturedImage {
                applyFilterAndShowPreview(image)
            }
        }
        .sheet(isPresented: $showingGallery) {
            EventGalleryView(eventId: eventId)
        }
    }

    private var cameraView: some View {
        ZStack {
            // Camera preview
            CameraPreview(cameraManager: cameraManager)
                .ignoresSafeArea()

            // Disposable camera frame overlay
            VStack {
                Spacer()

                // Bottom control panel (disposable camera style)
                VStack(spacing: 0) {
                    // Shot counter display
                    HStack {
                        Spacer()
                        VStack(spacing: 5) {
                            Text("\(shotsRemaining)")
                                .font(.system(size: 48, weight: .bold, design: .rounded))
                                .foregroundColor(.black)

                            Text("SHOTS LEFT")
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundColor(.black.opacity(0.7))
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.white.opacity(0.9))
                                .shadow(radius: 5)
                        )
                        .padding(.trailing, 20)
                        .padding(.bottom, 20)
                    }

                    // Shutter button area
                    HStack(spacing: 40) {
                        Spacer()

                        Button(action: capturePhoto) {
                            ZStack {
                                // Outer ring
                                Circle()
                                    .fill(disposableYellow)
                                    .frame(width: 90, height: 90)
                                    .shadow(radius: 10)

                                // Inner circle
                                Circle()
                                    .fill(disposableOrange)
                                    .frame(width: 70, height: 70)

                                // Center dot
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 30, height: 30)

                                // Camera icon
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(disposableOrange)
                            }
                        }
                        .disabled(shotsRemaining <= 0 || cameraManager.isCapturing || isUploading)
                        .opacity(shotsRemaining <= 0 ? 0.5 : 1.0)

                        Spacer()
                    }
                    .padding(.vertical, 30)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [disposableYellow, disposableOrange]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                }
            }

            // No shots remaining overlay
            if shotsRemaining <= 0 {
                VStack {
                    Spacer()
                    VStack(spacing: 20) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.white)

                        Text("All Shots Used!")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)

                        Text("View the gallery to see all event photos")
                            .multilineTextAlignment(.center)
                            .foregroundColor(.white.opacity(0.9))

                        Button(action: { showingGallery = true }) {
                            HStack {
                                Image(systemName: "photo.on.rectangle")
                                Text("View Gallery")
                                    .fontWeight(.bold)
                            }
                            .foregroundColor(.black)
                            .padding()
                            .background(disposableYellow)
                            .cornerRadius(15)
                        }
                    }
                    .padding(40)
                    .background(Color.black.opacity(0.8))
                    .cornerRadius(20)
                    .padding()
                    Spacer()
                }
            }

            // Uploading indicator
            if isUploading {
                VStack {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)
                    Text("Uploading...")
                        .foregroundColor(.white)
                        .padding(.top)
                }
                .padding(30)
                .background(Color.black.opacity(0.7))
                .cornerRadius(15)
            }
        }
    }

    private func previewView(image: UIImage) -> some View {
        ZStack {
            Color.black.ignoresSafeArea()

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
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.black.opacity(0.6))
                        .cornerRadius(10)
                    }

                    Button(action: uploadPhoto) {
                        HStack {
                            if isUploading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .black))
                            } else {
                                Image(systemName: "checkmark")
                                Text("Keep It!")
                            }
                        }
                        .foregroundColor(.black)
                        .padding()
                        .background(disposableYellow)
                        .cornerRadius(10)
                    }
                    .disabled(isUploading)
                }
                .padding(.bottom, 40)
            }
        }
    }

    private func loadParticipant() {
        Task {
            do {
                let p = try await PocketBaseService.shared.getParticipant(
                    eventId: eventId,
                    userId: PocketBaseService.shared.deviceId
                )
                await MainActor.run {
                    participant = p
                    shotsRemaining = p.shotsRemaining
                }
            } catch {
                print("Failed to load participant: \(error)")
            }
        }
    }

    private func capturePhoto() {
        guard shotsRemaining > 0, !cameraManager.isCapturing else { return }

        // Flash animation
        withAnimation(.easeInOut(duration: 0.1)) {
            showFlash = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.easeInOut(duration: 0.2)) {
                showFlash = false
            }
        }

        cameraManager.capturePhoto()
    }

    private func applyFilterAndShowPreview(_ image: UIImage) {
        DispatchQueue.global(qos: .userInitiated).async {
            let filter = FujifilmFilter()
            let filtered = filter.applyFilter(to: image, simulation: .classicChrome)

            DispatchQueue.main.async {
                filteredImage = filtered
                showingPreview = true
                cameraManager.stopSession()
            }
        }
    }

    private func uploadPhoto() {
        guard let image = filteredImage, let participant = participant else { return }

        isUploading = true

        Task {
            do {
                // Upload photo
                let _ = try await PocketBaseService.shared.uploadPhoto(eventId: eventId, image: image)

                // Update shots remaining
                let newShotsRemaining = max(0, shotsRemaining - 1)
                try await PocketBaseService.shared.updateShotsRemaining(
                    participantId: participant.id,
                    shotsRemaining: newShotsRemaining
                )

                await MainActor.run {
                    shotsRemaining = newShotsRemaining
                    isUploading = false
                    showingPreview = false
                    filteredImage = nil
                    cameraManager.resetPhoto()
                    cameraManager.startSession()
                }
            } catch {
                await MainActor.run {
                    isUploading = false
                    print("Upload failed: \(error)")
                }
            }
        }
    }
}

#Preview {
    EventCameraView(eventId: "test", userName: "John")
}
