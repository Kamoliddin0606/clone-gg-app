import Flutter
import UIKit
import workmanager

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Visits v2 background sync. The identifier must match
    // `visitsOutboxTaskName` in `visits_background_sync.dart` AND the
    // `BGTaskSchedulerPermittedIdentifiers` entry in Info.plist —
    // iOS rejects any unlisted identifier at scheduling time.
    //
    // `frequency` is the *minimum* delay; iOS opportunistically batches
    // BGProcessingTask runs and may defer well past 15 minutes depending
    // on charge state, network, and user activity. The foreground
    // `VisitsSyncCoordinator` is what makes the queue feel live; this
    // task is the safety net for visits that finish while the app is
    // killed.
    WorkmanagerPlugin.registerTask(withIdentifier: "visits_v2.outbox_sync")

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
