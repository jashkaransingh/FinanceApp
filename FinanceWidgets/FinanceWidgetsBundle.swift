//
//  FinanceWidgetsBundle.swift
//  FinanceWidgets
//
//  Created by Jas  on 6/2/25.
//

import WidgetKit
import SwiftUI

@main
struct FinanceWidgetsBundle: WidgetBundle {
    var body: some Widget {
        FinanceWidgets()
        FinanceWidgetsControl()
        FinanceWidgetsLiveActivity()
    }
}
