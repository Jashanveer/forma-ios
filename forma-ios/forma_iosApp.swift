import SwiftUI
import SwiftData
import UserNotifications

#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

@main
struct FormaIosApp: App {
    #if os(iOS)
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    #elseif os(macOS)
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    #endif

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([Habit.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        if let container = try? ModelContainer(for: schema, configurations: [config]) {
            return container
        }

        let storeURL = config.url
        let fm = FileManager.default
        for url in [storeURL,
                    storeURL.appendingPathExtension("shm"),
                    storeURL.appendingPathExtension("wal")] {
            try? fm.removeItem(at: url)
        }

        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Could not create ModelContainer even after store reset: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                #if os(macOS)
                .frame(minWidth: 900, minHeight: 600)
                #endif
                .task { WidgetSnapshotWriter.shared.start(container: sharedModelContainer) }
        }
        .modelContainer(sharedModelContainer)
        #if os(macOS)
        .defaultSize(width: 1080, height: 720)
        .windowResizability(.contentMinSize)
        #endif
    }
}

// MARK: - App Delegate

#if os(iOS)

final class AppDelegate: NSObject, UIApplicationDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            guard granted else { return }
            Task { @MainActor in
                UIApplication.shared.registerForRemoteNotifications()
            }
        }
        return true
    }

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        NotificationCenter.default.post(name: .apnsTokenReceived, object: deviceToken)
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        print("[APNs] Registration failed: \(error.localizedDescription)")
    }

    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable: Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        if
            let aps = userInfo["aps"] as? [String: Any],
            let alert = aps["alert"] as? [String: Any],
            let body = alert["body"] as? String
        {
            NotificationCenter.default.post(name: .apnsNudgeReceived, object: body)
        }
        completionHandler(.newData)
    }
}

#elseif os(macOS)

final class AppDelegate: NSObject, NSApplicationDelegate {

    func applicationDidFinishLaunching(_ notification: Notification) {
        UNUserNotificationCenter.current().delegate = self
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            guard granted else { return }
            Task { @MainActor in
                NSApp.registerForRemoteNotifications()
            }
        }
    }

    func application(_ application: NSApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        NotificationCenter.default.post(name: .apnsTokenReceived, object: deviceToken)
    }

    func application(_ application: NSApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("[APNs] Registration failed: \(error.localizedDescription)")
    }

    func application(_ application: NSApplication, didReceiveRemoteNotification userInfo: [String: Any]) {
        if
            let aps = userInfo["aps"] as? [String: Any],
            let alert = aps["alert"] as? [String: Any],
            let body = alert["body"] as? String
        {
            NotificationCenter.default.post(name: .apnsNudgeReceived, object: body)
        }
    }
}

#endif

// MARK: - UNUserNotificationCenterDelegate

extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }
}

// MARK: - Notification names

extension Notification.Name {
    static let apnsTokenReceived = Notification.Name("apnsTokenReceived")
    static let apnsNudgeReceived = Notification.Name("apnsNudgeReceived")
}
