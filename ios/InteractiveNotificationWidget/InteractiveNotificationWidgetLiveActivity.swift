//
//  InteractiveNotificationWidgetLiveActivity.swift
//  InteractiveNotificationWidget
//
//  Created by Maximilian Matisan on 10.08.26.
//

import ActivityKit
import WidgetKit
import SwiftUI
import AppIntents


// Create shared default with custom group
let sharedDefault = UserDefaults(suiteName: "group.maxi.test.interactivenotification.a")!

let DEFAULT_PADDING = 10.0;
let DEFAULT_CORNER_RADIUS = DEFAULT_PADDING;

struct InteractiveNotificationWidgetLiveActivity: Widget {
    
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: LiveActivitiesAppAttributes.self) { context in
            let timerEnded = sharedDefault.object(forKey: "pendingFinishedSeconds") != nil
            
            if timerEnded {
                createLockscreenSelfAssessment(context: context)
            } else {
                createLockscreenTimerLiveActivity(context: context)
            }

        } dynamicIsland: { context in
            
            let backgroundColor = getBackgroundColor(context: context)
            let shownTime = getShownTime(context: context)
            
            return DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Text("📚").font(.title)
                }
                DynamicIslandExpandedRegion(.center) {
                    VStack {
                        Text("Time studied:").font(.title3)
                        shownTime
                    }
                }
            } compactLeading: {
                Text("📚")
            } compactTrailing: {
                shownTime
            } minimal: {
                Text("📚")
            }
            .keylineTint(backgroundColor)
        }
    }
    
    func createLockscreenTimerLiveActivity(context: ActivityViewContext<LiveActivitiesAppAttributes>) -> some View {
        let backgroundColor = getBackgroundColor(context: context)
        let containerColor = getContainerColor(context: context)
        let textColor = getTextColor(context: context)
        let isPaused = sharedDefault.bool(forKey: context.attributes.prefixedKey("isPaused"))
        
        let activityID = context.attributes.id.uuidString

        return VStack {
            HStack{
                getShownTime(context: context)
                    .padding(DEFAULT_PADDING)
                    .background(
                        RoundedRectangle(cornerRadius: 2*DEFAULT_CORNER_RADIUS)
                            .fill(containerColor)
                    )
                Spacer()
                createTimerLiveActivityButtons(
                    activityID: activityID,
                    isPaused: isPaused,
                    textColor: textColor,
                    containerColor: containerColor
                )
            }.padding(DEFAULT_PADDING)
        }
        .activityBackgroundTint(backgroundColor)
        .activitySystemActionForegroundColor(Color.black)
    }
    func createTimerLiveActivityButtons(
        activityID: String,
        isPaused: Bool,
        textColor: Color,
        containerColor: Color
    ) -> some View {
        
        let toggleIcon = isPaused ? "play.fill" : "pause.fill"
        return HStack {
            createButton(
                textColor: textColor,
                containerColor: containerColor,
                buttonIcon: .system(toggleIcon),
                intent: ToggleTimerIntent(activityId: activityID)
            )
            createButton(
                textColor: textColor,
                containerColor: containerColor,
                buttonIcon: .system("stop.fill"),
                intent: EndTimerIntent(activityId: activityID)
            )
        }
    }
    func createButton(
        textColor: Color,
        containerColor: Color,
        buttonIcon: ButtonIcon,
        intent: any AppIntent
    ) -> some View  {
        return Button(intent: intent) {
            buttonIcon.view(size: 20)
                .padding(DEFAULT_PADDING)
                .foregroundColor(textColor)
                .background(containerColor,
                        in: RoundedRectangle(cornerRadius: DEFAULT_CORNER_RADIUS)
                )
        }
        .buttonStyle(.plain)
    }

    func getShownTime(context: ActivityViewContext<LiveActivitiesAppAttributes>) -> Text {
        if sharedDefault.bool(forKey: context.attributes.prefixedKey("hideTime")) {
            return Text("Paola Timer")
                .font(.title)
                .bold()
                .foregroundStyle(getTextColor(context: context))
        }

        let currentSegmentStartTime = Int(sharedDefault.string(forKey: context.attributes.prefixedKey("currentSegmentStartTimeMs")) ?? "0") ?? 0
        let accumulatedSeconds = Int(sharedDefault.string(forKey: context.attributes.prefixedKey("accumulatedSeconds")) ?? "0") ?? 0
        let isPaused = sharedDefault.bool(forKey: context.attributes.prefixedKey("isPaused"))
        
        let tempStart = Date(timeIntervalSince1970: Double(currentSegmentStartTime)/1000).addingTimeInterval(-Double(accumulatedSeconds))
    
        let shownText = if (isPaused) {
            Text(formatTime(seconds: accumulatedSeconds))
        } else {
            Text(timerInterval: tempStart...Date.distantFuture, countsDown: false)
        }
        
        return shownText
            .font(.title)
            .bold()
            .foregroundStyle(getTextColor(context: context))
        
    }
    func formatTime(seconds: Int) -> String {
        let hs = seconds / 60 / 60
        let mins = (seconds / 60) % 60
        let secs = seconds % 60
        
        if hs <= 0 {
            return String(format: "%d:%02d", mins, secs)
        } else {
            return String(format: "%d:%02d:%02d", hs, mins, secs)
        }
    }
    
    func createLockscreenSelfAssessment(context: ActivityViewContext<LiveActivitiesAppAttributes>) -> some View {
        let backgroundColor = getBackgroundColor(context: context)
        let containerColor = getContainerColor(context: context)
        let textColor = getTextColor(context: context)
        
        let activityID = context.attributes.id.uuidString

        return VStack {
            Text("Rate your study session!")
                .bold()
                .foregroundStyle(textColor)
            HStack{
                ForEach(Mood.allCases, id: \.self) { mood in
                    createButton(
                        textColor: textColor,
                        containerColor: containerColor,
                        buttonIcon: .emoji(mood.emoji),
                        intent: SelfAssessmentIntent(activityId: activityID, moodString: mood.rawValue)
                    )
                }
            }
        }.padding(DEFAULT_PADDING)
        .activityBackgroundTint(backgroundColor)
        .activitySystemActionForegroundColor(Color.black)
    }
    
    func getBackgroundColor(context: ActivityViewContext<LiveActivitiesAppAttributes>) -> Color {
        let backgroundColor = sharedDefault.integer(forKey: context.attributes.prefixedKey("backgroundColor"))
        return Color.init(argb: backgroundColor)
    }
    func getContainerColor(context: ActivityViewContext<LiveActivitiesAppAttributes>) -> Color {
        let containerColor = sharedDefault.integer(forKey: context.attributes.prefixedKey("containerColor"))
        return Color.init(argb: containerColor)
    }
    func getTextColor(context: ActivityViewContext<LiveActivitiesAppAttributes>) -> Color {
        let textColor = sharedDefault.integer(forKey: context.attributes.prefixedKey("textColor"))
        return Color.init(argb: textColor)
    }
}



extension Color {
    init(argb: Int) {
        let alpha = Double((argb >> 24) & 0xFF) / 255
        let red = Double((argb >> 16) & 0xFF) / 255
        let green = Double((argb >> 8) & 0xFF) / 255
        let blue = Double((argb) & 0xFF) / 255
        
        self.init(red: red, green: green, blue: blue, opacity: alpha)
    }
}
