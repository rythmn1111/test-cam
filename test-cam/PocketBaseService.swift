//
//  PocketBaseService.swift
//  test-cam
//
//  PocketBase API client
//

import Foundation
import UIKit

class PocketBaseService {
    static let shared = PocketBaseService()

    // MARK: - Configuration
    // TODO: Replace with your PocketBase server URL
    private var baseURL: String {
        UserDefaults.standard.string(forKey: "pocketbase_url") ?? "http://localhost:8090"
    }

    private let session = URLSession.shared
    var deviceId: String {
        if let id = UserDefaults.standard.string(forKey: "device_id") {
            return id
        }
        let id = UUID().uuidString
        UserDefaults.standard.set(id, forKey: "device_id")
        return id
    }

    func setServerURL(_ url: String) {
        UserDefaults.standard.set(url, forKey: "pocketbase_url")
    }

    // MARK: - Events

    func createEvent(name: String) async throws -> Event {
        let url = URL(string: "\(baseURL)/api/collections/events/records")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "name": name,
            "createdBy": deviceId,
            "qrCode": UUID().uuidString
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw NSError(domain: "PocketBase", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to create event"])
        }

        return try JSONDecoder().decode(Event.self, from: data)
    }

    func getEvent(id: String) async throws -> Event {
        let url = URL(string: "\(baseURL)/api/collections/events/records/\(id)")!
        let (data, _) = try await session.data(from: url)
        return try JSONDecoder().decode(Event.self, from: data)
    }

    func getEventByQRCode(_ qrCode: String) async throws -> Event {
        let urlString = "\(baseURL)/api/collections/events/records?filter=(qrCode='\(qrCode)')"
        guard let url = URL(string: urlString) else {
            throw NSError(domain: "PocketBase", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }

        let (data, _) = try await session.data(from: url)
        let response = try JSONDecoder().decode(PocketBaseResponse<Event>.self, from: data)

        guard let event = response.items.first else {
            throw NSError(domain: "PocketBase", code: 404, userInfo: [NSLocalizedDescriptionKey: "Event not found"])
        }

        return event
    }

    // MARK: - Participants

    func joinEvent(eventId: String, userName: String) async throws -> EventParticipant {
        // Check if already joined
        if let existing = try? await getParticipant(eventId: eventId, userId: deviceId) {
            return existing
        }

        let url = URL(string: "\(baseURL)/api/collections/participants/records")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "eventId": eventId,
            "userId": deviceId,
            "userName": userName,
            "shotsRemaining": 10
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw NSError(domain: "PocketBase", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to join event"])
        }

        return try JSONDecoder().decode(EventParticipant.self, from: data)
    }

    func getParticipant(eventId: String, userId: String) async throws -> EventParticipant {
        let urlString = "\(baseURL)/api/collections/participants/records?filter=(eventId='\(eventId)'&&userId='\(userId)')"
        guard let url = URL(string: urlString) else {
            throw NSError(domain: "PocketBase", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }

        let (data, _) = try await session.data(from: url)
        let response = try JSONDecoder().decode(PocketBaseResponse<EventParticipant>.self, from: data)

        guard let participant = response.items.first else {
            throw NSError(domain: "PocketBase", code: 404, userInfo: [NSLocalizedDescriptionKey: "Participant not found"])
        }

        return participant
    }

    func updateShotsRemaining(participantId: String, shotsRemaining: Int) async throws {
        let url = URL(string: "\(baseURL)/api/collections/participants/records/\(participantId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "shotsRemaining": shotsRemaining
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (_, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw NSError(domain: "PocketBase", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to update shots"])
        }
    }

    // MARK: - Photos

    func uploadPhoto(eventId: String, image: UIImage) async throws -> Photo {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw NSError(domain: "PocketBase", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to convert image"])
        }

        let url = URL(string: "\(baseURL)/api/collections/photos/records")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()

        // Add eventId
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"eventId\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(eventId)\r\n".data(using: .utf8)!)

        // Add userId
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"userId\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(deviceId)\r\n".data(using: .utf8)!)

        // Add image file
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"image\"; filename=\"photo.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n".data(using: .utf8)!)

        body.append("--\(boundary)--\r\n".data(using: .utf8)!)

        request.httpBody = body

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw NSError(domain: "PocketBase", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to upload photo"])
        }

        return try JSONDecoder().decode(Photo.self, from: data)
    }

    func getEventPhotos(eventId: String) async throws -> [Photo] {
        let urlString = "\(baseURL)/api/collections/photos/records?filter=(eventId='\(eventId)')&sort=-created"
        guard let url = URL(string: urlString) else {
            throw NSError(domain: "PocketBase", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }

        let (data, _) = try await session.data(from: url)
        let response = try JSONDecoder().decode(PocketBaseResponse<Photo>.self, from: data)
        return response.items
    }

    func getPhotoURL(photo: Photo) -> URL? {
        return URL(string: "\(baseURL)/api/files/photos/\(photo.id)/\(photo.imageUrl)")
    }
}
