//
//  CreateEventView.swift
//  test-cam
//
//  Create new event and generate QR code
//

import SwiftUI
import CoreImage.CIFilterBuiltins

struct CreateEventView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var eventName = ""
    @State private var userName = ""
    @State private var isCreating = false
    @State private var createdEvent: Event?
    @State private var error: String?

    private let disposableYellow = Color(red: 1.0, green: 0.85, blue: 0.2)

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.opacity(0.05)
                    .ignoresSafeArea()

                if let event = createdEvent {
                    eventCreatedView(event: event)
                } else {
                    createEventForm
                }
            }
            .navigationTitle("Create Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }

    private var createEventForm: some View {
        VStack(spacing: 25) {
            Spacer()

            VStack(alignment: .leading, spacing: 15) {
                Text("Event Details")
                    .font(.title2)
                    .fontWeight(.bold)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Event Name")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    TextField("e.g., Sarah's Birthday", text: $eventName)
                        .textFieldStyle(.roundedBorder)
                        .autocapitalization(.words)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Your Name")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    TextField("e.g., John", text: $userName)
                        .textFieldStyle(.roundedBorder)
                        .autocapitalization(.words)
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

            Button(action: createEvent) {
                HStack {
                    if isCreating {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .black))
                    } else {
                        Image(systemName: "plus.circle.fill")
                        Text("Create Event")
                            .fontWeight(.bold)
                    }
                }
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding()
                .background(disposableYellow)
                .cornerRadius(15)
            }
            .disabled(eventName.isEmpty || userName.isEmpty || isCreating)
            .padding(.horizontal)
            .padding(.bottom, 30)
        }
    }

    private func eventCreatedView(event: Event) -> some View {
        ScrollView {
            VStack(spacing: 30) {
                VStack(spacing: 15) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.green)

                    Text("Event Created!")
                        .font(.title)
                        .fontWeight(.bold)

                    Text(event.name)
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 40)

                VStack(spacing: 15) {
                    Text("Share this QR Code")
                        .font(.headline)

                    if let qrImage = generateQRCode(from: event.qrCode ?? event.id) {
                        Image(uiImage: qrImage)
                            .interpolation(.none)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 250, height: 250)
                            .background(Color.white)
                            .cornerRadius(20)
                            .shadow(radius: 10)
                    }

                    Text("Event Code: \(event.qrCode ?? event.id)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .textSelection(.enabled)
                }

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

                Button(action: {
                    shareEvent(event)
                }) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text("Share QR Code")
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(15)
                }
                .padding(.horizontal)

                Spacer()
            }
        }
    }

    private func createEvent() {
        guard !eventName.isEmpty, !userName.isEmpty else { return }

        isCreating = true
        error = nil

        Task {
            do {
                let event = try await PocketBaseService.shared.createEvent(name: eventName)
                let _ = try await PocketBaseService.shared.joinEvent(eventId: event.id, userName: userName)

                await MainActor.run {
                    createdEvent = event
                    isCreating = false
                }
            } catch {
                await MainActor.run {
                    self.error = error.localizedDescription
                    isCreating = false
                }
            }
        }
    }

    private func generateQRCode(from string: String) -> UIImage? {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(string.utf8)
        filter.correctionLevel = "M"

        guard let outputImage = filter.outputImage else { return nil }

        let transform = CGAffineTransform(scaleX: 10, y: 10)
        let scaledImage = outputImage.transformed(by: transform)

        guard let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }

    private func shareEvent(_ event: Event) {
        guard let qrImage = generateQRCode(from: event.qrCode ?? event.id) else { return }

        let activityVC = UIActivityViewController(
            activityItems: [
                "Join my event '\(event.name)' on SnapParty! Scan this QR code or use code: \(event.qrCode ?? event.id)",
                qrImage
            ],
            applicationActivities: nil
        )

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootVC = window.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }
}

#Preview {
    CreateEventView()
}
