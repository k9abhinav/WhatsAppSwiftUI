//import UIKit
//import FirebaseAuth
//
//class AppDelegate: NSObject, UIApplicationDelegate {
//    func application(
//        _ application: UIApplication,
//        didReceiveRemoteNotification userInfo: [AnyHashable: Any],
//        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
//    ) {
//        if Auth.auth().canHandleNotification(userInfo) {
//            completionHandler(.noData)
//            return
//        }
//        completionHandler(.newData)
//    }
//}
