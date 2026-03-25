//
//  orieWidgetsBundle.swift
//  orieWidgets
//
//  Created by Shareef Evans on 25/3/2026.
//

import WidgetKit
import SwiftUI

@main
struct orieWidgetsBundle: WidgetBundle {
    var body: some Widget {
        if #available(iOS 16.2, *) {
            CalorieProgressLiveActivity()
            StreakLiveActivity()
        }
    }
}
