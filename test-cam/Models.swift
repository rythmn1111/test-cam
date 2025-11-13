//
//  Models.swift
//  test-cam
//
//  Data models for events and photos
//

import Foundation

struct Event: Codable, Identifiable {
    let id: String
    let name: String
    let createdBy: String
    let created: String
    let qrCode: String?

    var createdDate: Date {
        let formatter = ISO8601DateFormatter()
        return formatter.date(from: created) ?? Date()
    }
}

struct Photo: Codable, Identifiable {
    let id: String
    let eventId: String
    let userId: String
    let imageUrl: String
    let created: String

    var createdDate: Date {
        let formatter = ISO8601DateFormatter()
        return formatter.date(from: created) ?? Date()
    }
}

struct EventParticipant: Codable, Identifiable {
    let id: String
    let eventId: String
    let userId: String
    let userName: String
    let shotsRemaining: Int
    let created: String
}

struct PocketBaseResponse<T: Codable>: Codable {
    let page: Int
    let perPage: Int
    let totalItems: Int
    let totalPages: Int
    let items: [T]
}

struct PocketBaseError: Codable {
    let code: Int
    let message: String
    let data: [String: String]?
}
