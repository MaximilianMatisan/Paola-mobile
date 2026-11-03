//
//  CustomButtonIntents.swift
//  Runner
//
//  Created by Maximilian Matisan on 17.08.26.
//

import WidgetKit
import AppIntents
import UserNotifications

struct ToggleTimerIntent: LiveActivityIntent {
    static var title: LocalizedStringResource { "Toggle timer" }
    static var isDiscoverable: Bool { false }
    
    @Parameter(title:"Activity Id")
    var activityId: String

    init() {}
    init(activityId: String) { self.activityId = activityId }
    
    func perform() async throws -> some IntentResult {
        SharedTimerState.toggle(id: activityId)
        await SharedTimerState.refresh(id: activityId)
        return .result()
    }
}

struct EndTimerIntent: LiveActivityIntent {
    static var title: LocalizedStringResource { "End timer" }
    static var isDiscoverable: Bool { false }
    
    @Parameter(title:"Activity Id")
    var activityId: String
    
    init() {}
    init(activityId: String) { self.activityId = activityId }
    
    func perform() async throws -> some IntentResult {
        if !SharedTimerState.isPaused(id: activityId) {
            SharedTimerState.pauseTimer(id: activityId)
        }
        SharedTimerState.safeFinalTime(id: activityId)
        await SharedTimerState.refresh(id: activityId)
        return .result()
    }
}

struct DiscardBreakIntent: LiveActivityIntent {
    static var title: LocalizedStringResource { "Discard break" }
    static var isDiscoverable: Bool { false }
    
    @Parameter(title:"Activity Id")
    var activityId: String
    
    init() {}
    init(activityId: String) { self.activityId = activityId }
    
    func perform() async throws -> some IntentResult {
        SharedTimerState.safeBreakDiscarded()
        await SharedTimerState.end(id: activityId)
        return .result()
    }
}
