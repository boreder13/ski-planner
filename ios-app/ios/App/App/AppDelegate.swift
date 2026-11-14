import UIKit
import Capacitor

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

    func application(_ application: UIApplication,
                     configurationForConnecting connectingSceneSession: UISceneSession,
                     options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        let config = UISceneConfiguration(name: "Default Configuration",
                                          sessionRole: connectingSceneSession.role)
        config.delegateClass = SceneDelegate.self
        return config
    }
}

// MARK: - Ski Planner: Apple Health bridge (local Capacitor plugin)
import HealthKit
import CoreLocation

/// Hosts the web app and registers the app's own native plugins.
class SkiBridgeViewController: CAPBridgeViewController {
    override open func capacitorDidLoad() {
        bridge?.registerPluginInstance(HealthPlugin())
    }
}

@objc(HealthPlugin)
public class HealthPlugin: CAPPlugin, CAPBridgedPlugin {
    public let identifier = "HealthPlugin"
    public let jsName = "Health"
    public let pluginMethods: [CAPPluginMethod] = [
        CAPPluginMethod(name: "isAvailable", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "requestAuthorization", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "saveWorkout", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "heartRate", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "shareFile", returnType: CAPPluginReturnPromise)
    ]
    private let store = HKHealthStore()
    private var distanceType: HKQuantityType { HKQuantityType.quantityType(forIdentifier: .distanceDownhillSnowSports)! }
    private var heartType: HKQuantityType { HKQuantityType.quantityType(forIdentifier: .heartRate)! }

    @objc func isAvailable(_ call: CAPPluginCall) {
        call.resolve(["available": HKHealthStore.isHealthDataAvailable()])
    }

    @objc func requestAuthorization(_ call: CAPPluginCall) {
        guard HKHealthStore.isHealthDataAvailable() else { call.reject("Health is not available on this device"); return }
        let share: Set<HKSampleType> = [HKObjectType.workoutType(), HKSeriesType.workoutRoute(), distanceType]
        let read: Set<HKObjectType> = [heartType, HKObjectType.workoutType()]
        store.requestAuthorization(toShare: share, read: read) { ok, error in
            if let error = error { call.reject(error.localizedDescription); return }
            call.resolve(["granted": ok])
        }
    }

    /// points: [[unixSeconds, lat, lng, elevation|null, speed|null], ...]
    @objc func saveWorkout(_ call: CAPPluginCall) {
        guard let raw = call.getArray("points"), raw.count >= 2 else { call.reject("No GPS points to save"); return }
        let meters = call.getDouble("distance") ?? 0
        let title = call.getString("title") ?? "Snowboarding"
        var locations: [CLLocation] = []
        for item in raw {
            guard let p = item as? [Any], p.count >= 3,
                  let t = (p[0] as? NSNumber)?.doubleValue,
                  let lat = (p[1] as? NSNumber)?.doubleValue,
                  let lng = (p[2] as? NSNumber)?.doubleValue else { continue }
            let ele = (p.count > 3 ? (p[3] as? NSNumber)?.doubleValue : nil) ?? 0
            let spd = (p.count > 4 ? (p[4] as? NSNumber)?.doubleValue : nil) ?? -1
            locations.append(CLLocation(coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lng), altitude: ele,
                                        horizontalAccuracy: 10, verticalAccuracy: 15, course: -1, speed: spd,
                                        timestamp: Date(timeIntervalSince1970: t)))
        }
        guard let start = locations.first?.timestamp, let end = locations.last?.timestamp, end > start else {
            call.reject("GPS points have no usable time range"); return
        }
        let config = HKWorkoutConfiguration()
        config.activityType = .snowboarding
        config.locationType = .outdoor
        let builder = HKWorkoutBuilder(healthStore: store, configuration: config, device: .local())
        builder.beginCollection(withStart: start) { ok, error in
            if let error = error { call.reject(error.localizedDescription); return }
            var samples: [HKSample] = []
            if meters > 0 {
                samples.append(HKQuantitySample(type: self.distanceType, quantity: HKQuantity(unit: .meter(), doubleValue: meters), start: start, end: end))
            }
            builder.addMetadata([HKMetadataKeyWorkoutBrandName: title]) { _, _ in
                builder.add(samples) { _, _ in
                    builder.endCollection(withEnd: end) { _, _ in
                        builder.finishWorkout { workout, error in
                            guard let workout = workout else { call.reject(error?.localizedDescription ?? "Could not save the workout"); return }
                            let route = HKWorkoutRouteBuilder(healthStore: self.store, device: .local())
                            route.insertRouteData(locations) { _, _ in
                                route.finishRoute(with: workout, metadata: nil) { _, _ in
                                    call.resolve(["saved": true, "id": workout.uuid.uuidString])
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    /// Returns heart-rate samples between start and end (unix seconds): [{t, bpm}]
    @objc func heartRate(_ call: CAPPluginCall) {
        guard let s = call.getDouble("start"), let e = call.getDouble("end") else { call.reject("start and end are required"); return }
        let predicate = HKQuery.predicateForSamples(withStart: Date(timeIntervalSince1970: s), end: Date(timeIntervalSince1970: e))
        let sort = [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)]
        let query = HKSampleQuery(sampleType: heartType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: sort) { _, samples, error in
            if let error = error { call.reject(error.localizedDescription); return }
            let unit = HKUnit.count().unitDivided(by: .minute())
            var out: JSArray = []
            for sample in (samples as? [HKQuantitySample]) ?? [] {
                let row: JSObject = ["t": sample.startDate.timeIntervalSince1970, "bpm": sample.quantity.doubleValue(for: unit)]
                out.append(row)
            }
            call.resolve(["samples": out])
        }
        store.execute(query)
    }

    // Writes a text file (e.g. a GPX track) to a temp folder and opens the iOS share sheet for it.
    @objc func shareFile(_ call: CAPPluginCall) {
        guard let name = call.getString("name"), let text = call.getString("text") else { call.reject("name and text are required"); return }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(name)
        do { try text.write(to: url, atomically: true, encoding: .utf8) } catch { call.reject(error.localizedDescription); return }
        DispatchQueue.main.async {
            guard let vc = self.bridge?.viewController else { call.reject("No view to present from"); return }
            let sheet = UIActivityViewController(activityItems: [url], applicationActivities: nil)
            sheet.popoverPresentationController?.sourceView = vc.view
            sheet.completionWithItemsHandler = { _, completed, _, error in
                if let error = error { call.reject(error.localizedDescription) } else { call.resolve(["completed": completed]) }
            }
            vc.present(sheet, animated: true)
        }
    }
}
