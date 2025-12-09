# Orie - Calorie Tracking iOS App

Orie is a Swift-based iOS calorie tracking application that helps users log their food intake, track nutritional information, and monitor their calorie goals through an intuitive interface.

## Features

### 📱 Core Functionality
- **Food Entry Logging**: Simple text-based food entry with automatic nutritional data fetching
- **Date-based Tracking**: View and log entries for different dates with calendar selection
- **Real-time Nutrition Data**: Integration with nutrition API to fetch calorie, protein, carb, and fat information
- **Time-based Organization**: Chronological sorting of food entries throughout the day

### 🏆 Gamification
- **Achievement System**: Unlock badges for various milestones (streak tracking, deficit maintenance, etc.)
- **Streak Tracking**: Monitor consecutive days of calorie goal adherence
- **Progress Monitoring**: Visual feedback for nutritional targets and goals

### 🎨 User Interface
- **Clean Design**: Minimalist interface with focus on usability
- **Floating Navigation**: Top navigation bar with quick access to profile, awards, and notifications
- **Swipe Actions**: Easy deletion of food entries with swipe gestures
- **Date Selection Modal**: Easy switching between different tracking dates

## Technical Stack

- **Language**: Swift 5.0
- **Framework**: SwiftUI
- **Platform**: iOS (iPhone & iPad)
- **Deployment Target**: iOS 26.1+
- **Architecture**: MVVM pattern with async/await for API calls

## Project Structure

```
orie/
├── components/           # Reusable UI components
│   ├── CalorieIndicator.swift
│   ├── FoodInputField.swift
│   └── TopNavigationBar.swift
├── models/              # Data models
│   ├── FoodEntry.swift
│   └── UserProfile.swift
├── services/            # API and data services
│   ├── APIService.swift
│   └── APIservices.swift
├── views/               # Main view components
│   ├── AwardSheet.swift
│   ├── DataSelectionModal.swift
│   ├── FoodEntryRow.swift
│   ├── MainView.swift
│   ├── Notificationsheet.swift
│   └── ProfileSheet.swift
├── resources/           # Assets and images
│   └── Assets.xcassets/
└── orieApp.swift        # Main app entry point
```

## Getting Started

### Prerequisites
- Xcode 15.0 or later
- iOS 17.0+ simulator/device
- Apple Developer Account (for device deployment)

### Installation
1. Clone the repository
2. Open `orie.xcodeproj` in Xcode
3. Select your target device/simulator
4. Build and run the project (⌘+R)

### Configuration
- The app is configured with bundle identifier: `com.shareefevans.orie`
- Development team: AM959VBNCT
- Supports both Portrait and Landscape orientations

## Key Features Detail

### Food Entry System
- Users can type food names in natural language
- Automatic nutritional data fetching via API integration
- Loading states with fallback handling for API failures
- Timestamp tracking for meal timing

### Awards & Gamification
The app includes a comprehensive badge system with achievements such as:
- **Deficit Devotee**: 30 days under calorie goal
- **Macro Obsessive**: Complete macro tracking for a week
- **2000 Club**: Hitting 2000 calorie targets
- **Weekend Warrior**: Tracking on weekends

### User Interface Highlights
- Dynamic date formatting and selection
- Floating UI elements with glass morphism effects
- Smooth animations and transitions
- Keyboard-aware scrolling and input handling

## Development Notes

- The project uses modern Swift concurrency with async/await
- SwiftUI 5.0 features including @FocusState and sheet presentations
- Modular component architecture for reusability
- Mock data system for development and testing

## App Bundle Information
- **Product Name**: orie
- **Version**: 1.0
- **Build**: 1
- **Bundle ID**: com.shareefevans.orie

## Author
Created by Shareef Evans (2025)
