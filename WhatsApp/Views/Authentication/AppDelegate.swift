import UIKit
import Firebase
import FirebaseAuth
import FirebaseCore

@MainActor
class NotificationDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {

//        let firebaseAuthCompletion: (Result<Bool, Error>) -> Void = { result in
//            switch result {
//            case .success(let handled):
//                if handled {
//                    completionHandler(.noData)
//                } else {
//                    // Handle other notifications
//                    completionHandler(.newData)
//                }
//            case .failure(_):
//                completionHandler(.failed)
//            }
//        }

        if Auth.auth().canHandleNotification(userInfo) {
            return;
        }

        completionHandler(.newData)
    }
}
