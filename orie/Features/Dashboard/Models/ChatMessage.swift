//
//  ChatMessage.swift
//  orie
//

import Foundation

struct ChatMessage: Identifiable, Codable, Equatable {
    var id = UUID()
    let role: Role
    let content: String

    enum Role: String, Codable {
        case user, assistant
    }
}
