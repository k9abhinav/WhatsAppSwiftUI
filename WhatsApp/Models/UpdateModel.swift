//
//  StatusModel.swift
//  WhatsApp
//
//  Created by Abhinava Krishna on 26/02/25.
//
import SwiftData
import Foundation
// To create a model
@Model
class Update {
    var id: UUID
    var content: String
    var imageData: Data?
    var createdAt: Date
    var expiresAt: Date

    init(content: String, imageData: Data? = nil) {
        self.id = UUID()
        self.content = content
        self.imageData = imageData

        let now = Date()
        self.createdAt = now
        self.expiresAt = Calendar.current.date(byAdding: .hour, value: 24, to: now)!
    }

    var isExpired: Bool {
        Date() > expiresAt
    }

    var timeRemaining: String {
        let remaining = expiresAt.timeIntervalSince(Date())
        if remaining <= 0 { return "Expired" }

        let hours = Int(remaining) / 3600
        let minutes = (Int(remaining) % 3600) / 60

        if hours > 0 {
            return "\(hours)h \(minutes)m remaining"
        } else {
            return "\(minutes)m remaining"
        }
    }
}
