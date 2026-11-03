//
//  SharedTimerState.swift
//  Runner
//
//  Created by Maximilian Matisan on 18.08.26.
//

import Foundation
import ActivityKit

enum SharedTimerState {
    static let appGroupId = "group.maxi.test.interactivenotification.a"
    static var defaults: UserDefaults {
        UserDefaults(suiteName: appGroupId)!
    }
    
    static func key(_ activityId: String, _ name: String) -> String {
        "\(activityId)_\(name)"
    }
    
    static func isPaused(id: String) -> Bool {
        defaults.bool(forKey: key(id, "isPaused"))
    }
    static func accumulatedSeconds(id: String) -> Int {
        Int(defaults.string(forKey: key(id,"accumulatedSeconds")) ?? "0") ?? 0
    }
    static func currentSegmentStartTime(id: String) -> Int {
        Int(defaults.string(forKey: key(id, "currentSegmentStartTimeMs")) ?? "0") ?? 0
    }
    
    static func totalSeconds(id: String) -> Int {
        if (isPaused(id: id)) {
            return accumulatedSeconds(id: id)
        }
        let currentTimeMs = Int(Date().timeIntervalSince1970 * 1000)
        return accumulatedSeconds(id: id) + ((currentTimeMs - currentSegmentStartTime(id: id))/1000)
        
    }
    
    static func toggle(id: String) {
        if (isPaused(id: id)) {
            resumeTimer(id: id)
        } else {
            pauseTimer(id: id)
        }
    }
    static func pauseTimer(id: String) {
        let currentTimeMs = Int(Date().timeIntervalSince1970 * 1000)
        
        defaults.set(String(totalSeconds(id: id)), forKey: key(id, "accumulatedSeconds"))
        defaults.set(String(currentTimeMs), forKey: key(id, "currentSegmentStartTimeMs"))
        defaults.set(true, forKey: key(id, "isPaused"))
    }
    private static func resumeTimer(id: String) {
        let currentTimeMs = Int(Date().timeIntervalSince1970 * 1000)
        
        defaults.set(String(currentTimeMs), forKey: key(id, "currentSegmentStartTimeMs"))
        defaults.set(false, forKey: key(id, "isPaused"))
    }
    
    static func safeFinalTime(id: String) {
        defaults.set(String(totalSeconds(id: id)), forKey: "pendingFinishedSeconds")
        defaults.set(currentSegmentStartTime(id: id), forKey: "pendingFinishedAtMs")
    }
    
    static func safeBreakDiscarded() {
        defaults.set(true, forKey: "pendingBreakDiscarded")
    }

    static func safeSelfAssessment(id: String, moodString: String) {
        defaults.set(moodString, forKey: "pendingSelfAssessmentMood")
    }
    
    @available(iOS 16.1, *)
    static func refresh(id: String) async {
        for activity in Activity<LiveActivitiesAppAttributes>.activities
        where activity.attributes.id.uuidString == id {
            await activity.update(
                ActivityContent(state: LiveActivitiesAppAttributes.ContentState(), staleDate: nil)
            )
        }
    }
    
    @available(iOS 16.1, *)
    static func end(id: String) async {
        for activity in Activity<LiveActivitiesAppAttributes>.activities
        where activity.attributes.id.uuidString == id {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
    }
}
