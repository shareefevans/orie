//
//  NotificationSheet.swift
//  orie
//
//  Created by Shareef Evans on 26/11/2025.
//

import SwiftUI

struct NotificationSheet: View {
    @Environment(\.dismiss) var dismiss
    
    // Mock data
    @State private var unreadCount = 0
    
    var body: some View {
        NavigationView {
            VStack {
                // Header - Notifications and unread count
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Notifications")
                            .font(.title)
                            .fontWeight(.semibold)
                            .foregroundColor(
                                Color(
                                    red: 69 / 255,
                                    green: 69 / 255,
                                    blue: 69 / 255
                                )
                            )
                        
                        Text("\(unreadCount) unread")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, 32)
                
                Spacer()
                
                // Empty State
                VStack(spacing: 0) {
                    Image("AppLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 48, height: 48)
                        .opacity(0.5)
                    
                    Text("Nothing New")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .padding(.top, 8)
                        .foregroundColor(
                            Color(
                                red: 69 / 255,
                                green: 69 / 255,
                                blue: 69 / 255
                            )
                        )
                    
                    Text("no new notifications")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDragIndicator(.visible)
    }
}

#Preview {
    NotificationSheet()
}
