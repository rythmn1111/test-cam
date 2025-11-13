//
//  EventGalleryView.swift
//  test-cam
//
//  View all photos from an event
//

import SwiftUI

struct EventGalleryView: View {
    let eventId: String

    @Environment(\.dismiss) private var dismiss
    @State private var photos: [Photo] = []
    @State private var event: Event?
    @State private var isLoading = true
    @State private var refreshTimer: Timer?

    private let disposableYellow = Color(red: 1.0, green: 0.85, blue: 0.2)

    let columns = [
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2)
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                if isLoading {
                    ProgressView()
                } else if photos.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 2) {
                            ForEach(photos) { photo in
                                NavigationLink(destination: PhotoDetailView(photo: photo)) {
                                    AsyncImageView(url: PocketBaseService.shared.getPhotoURL(photo: photo))
                                        .aspectRatio(1, contentMode: .fill)
                                        .clipped()
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle(event?.name ?? "Event Gallery")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: refreshPhotos) {
                            Label("Refresh", systemImage: "arrow.clockwise")
                        }

                        Button(action: downloadAllPhotos) {
                            Label("Download All", systemImage: "square.and.arrow.down")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .onAppear {
                loadEvent()
                loadPhotos()
                startAutoRefresh()
            }
            .onDisappear {
                stopAutoRefresh()
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 60))
                .foregroundColor(.gray)

            Text("No Photos Yet")
                .font(.title2)
                .fontWeight(.bold)

            Text("Photos will appear here as people take them")
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button(action: refreshPhotos) {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("Refresh")
                }
                .foregroundColor(.black)
                .padding()
                .background(disposableYellow)
                .cornerRadius(10)
            }
        }
    }

    private func loadEvent() {
        Task {
            do {
                let loadedEvent = try await PocketBaseService.shared.getEvent(id: eventId)
                await MainActor.run {
                    event = loadedEvent
                }
            } catch {
                print("Failed to load event: \(error)")
            }
        }
    }

    private func loadPhotos() {
        Task {
            do {
                let loadedPhotos = try await PocketBaseService.shared.getEventPhotos(eventId: eventId)
                await MainActor.run {
                    photos = loadedPhotos
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                }
                print("Failed to load photos: \(error)")
            }
        }
    }

    private func refreshPhotos() {
        isLoading = true
        loadPhotos()
    }

    private func startAutoRefresh() {
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { _ in
            loadPhotos()
        }
    }

    private func stopAutoRefresh() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }

    private func downloadAllPhotos() {
        // TODO: Implement download all functionality
        print("Download all photos")
    }
}

struct AsyncImageView: View {
    let url: URL?
    @State private var image: UIImage?
    @State private var isLoading = true

    var body: some View {
        ZStack {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
            } else {
                Color.gray.opacity(0.3)
                if isLoading {
                    ProgressView()
                }
            }
        }
        .onAppear {
            loadImage()
        }
    }

    private func loadImage() {
        guard let url = url else {
            isLoading = false
            return
        }

        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                if let loadedImage = UIImage(data: data) {
                    await MainActor.run {
                        image = loadedImage
                        isLoading = false
                    }
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                }
            }
        }
    }
}

struct PhotoDetailView: View {
    let photo: Photo

    @State private var image: UIImage?
    @State private var isLoading = true

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
            } else if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if let image = image {
                    Button(action: { saveImage(image) }) {
                        Image(systemName: "square.and.arrow.down")
                            .foregroundColor(.white)
                    }
                }
            }
        }
        .onAppear {
            loadImage()
        }
    }

    private func loadImage() {
        guard let url = PocketBaseService.shared.getPhotoURL(photo: photo) else {
            isLoading = false
            return
        }

        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                if let loadedImage = UIImage(data: data) {
                    await MainActor.run {
                        image = loadedImage
                        isLoading = false
                    }
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                }
            }
        }
    }

    private func saveImage(_ image: UIImage) {
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
    }
}

#Preview {
    EventGalleryView(eventId: "test")
}
