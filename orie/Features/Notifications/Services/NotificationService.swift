//
//  NotificationService.swift
//  orie
//
//  Created by Shareef Evans on 21/01/2026.
//

import Foundation

class NotificationService {
    static let baseURL = APIService.baseURL
    
    struct SystemNotification: Codable {
        let id: String
        let type: String
        let title: String
        let message: String
        let createdAt: String
        
        enum CodingKeys: String, CodingKey {
            case id, type, title, message
            case createdAt = "created_at"
        }
    }
    
    struct NotificationsResponse: Codable {
        let notifications: [SystemNotification]
    }
    
    /// Fetch system-wide notifications from backend
    static func fetchSystemNotifications() async throws -> [SystemNotification] {
        guard let url = URL(string: "\(baseURL)/api/notifications") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
        
        let result = try JSONDecoder().decode(NotificationsResponse.self, from: data)
        return result.notifications
    }
}
