import Flutter
import UIKit
import ActivityKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
      if #available(iOS 10.0, *) {
          UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
      }
      return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
      
      guard let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "TimerState")
      else { return }
      
      let channel = FlutterMethodChannel(
        name: "interactivenotification/state",
        binaryMessenger: registrar.messenger()
      )
      
      //self.channel = channel
      
      channel.setMethodCallHandler { call, result in
          switch call.method {
          case "getState":
              guard #available(iOS 16.1, *),
                    let activity = Activity<LiveActivitiesAppAttributes>.activities.first else {
                  result(nil); return
              }
              let id = activity.attributes.id.uuidString
              
              result([
                "isPaused": SharedTimerState.isPaused(id: id),
                "accumulatedSeconds": SharedTimerState.accumulatedSeconds(id: id),
                "currentSegmentStartTimeMs": SharedTimerState.currentSegmentStartTime(id: id),
              ])
              
          case "consumeFinishedSeconds":
              let defaults = SharedTimerState.defaults
              let key = "pendingFinishedSeconds"
              
              if defaults.object(forKey: key) != nil {
                  let value = defaults.integer(forKey: key)
                  defaults.removeObject(forKey: key)
                  result(value)
              } else { result(nil) }
              
          case "consumeFinishedAtMs":
              let defaults = SharedTimerState.defaults
              let key = "pendingFinishedAtMs"

              if defaults.object(forKey: key) != nil {
                  let value = defaults.integer(forKey: key)
                  defaults.removeObject(forKey: key)
                  result(value)
              } else { result(nil) }

          case "consumeBreakDiscarded":
              let defaults = SharedTimerState.defaults
              let key = "pendingBreakDiscarded"

              let value = defaults.bool(forKey: key)
              defaults.removeObject(forKey: key)
              result(value)

          case "consumeSelfAssessmentMoodString":
              let defaults = SharedTimerState.defaults
              let key = "pendingSelfAssessmentMood"
              
              if defaults.object(forKey: key) != nil {
                  let value = defaults.string(forKey: key)
                  defaults.removeObject(forKey: key)
                  result(value)
              } else { result(nil) }
              
          default: result(FlutterMethodNotImplemented)
          }
      }
  }
}
