import SwiftUI

@Observable
class UtilityClass {
    var chatCategories: [String] = ["All","Archived","Family ❤️","Friends","Work","Unread"]
    @MainActor var profileImageData: Data? = nil
     func timeStringShort(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
     func timeString(from date: Date) -> String {
        let calendar = Calendar.current
        let formatter = DateFormatter()

        if calendar.isDateInToday(date) {
            formatter.timeStyle = .short
            return formatter.string(from: date)  // Example: "2:30 PM"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            formatter.dateStyle = .medium
            formatter.timeStyle = .none
            return formatter.string(from: date)  // Example: "Mar 4, 2025"
        }
    }

}

extension Color {
    static let customGreen = Color(UIColor(red: 0.22, green: 0.67, blue: 0.49, alpha: 1.0))
}

extension Color {
    static var rainbow: some ShapeStyle {
        LinearGradient(
            stops: [
                .init(color: Color(red: 122/255, green: 229/255, blue: 83/255), location: 0.0),
                .init(color: Color(red: 179/255, green: 203/255, blue: 54/255), location: 0.143),
                .init(color: Color(red: 216/255, green: 78/255, blue: 87/255), location: 0.286),
                .init(color: Color(red: 242/255, green: 191/255, blue: 28/255), location: 0.429),
                .init(color: Color(red: 42/255, green: 161/255, blue: 208/255), location: 0.572),
                .init(color: Color(red: 94/255, green: 196/255, blue: 138/255), location: 0.714),
                .init(color: Color(red: 97/255, green: 124/255, blue: 184/255), location: 0.857),
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}
extension LinearGradient {
    static let rainbow = LinearGradient(
        stops: [
            .init(color: Color(red: 122/255, green: 229/255, blue: 83/255), location: 0.0),
            .init(color: Color(red: 179/255, green: 203/255, blue: 54/255), location: 0.143),
            .init(color: Color(red: 216/255, green: 78/255, blue: 87/255), location: 0.286),
            .init(color: Color(red: 242/255, green: 191/255, blue: 28/255), location: 0.429),
            .init(color: Color(red: 42/255, green: 161/255, blue: 208/255), location: 0.572),
            .init(color: Color(red: 94/255, green: 196/255, blue: 138/255), location: 0.714),
            .init(color: Color(red: 97/255, green: 124/255, blue: 184/255), location: 0.857),
        ],
        startPoint: .leading,
        endPoint: .trailing
    )
}

//func clearUserDefaults() {
//    let defaults = UserDefaults.standard
//    for key in defaults.dictionaryRepresentation().keys {
//        defaults.removeObject(forKey: key)
//    }
//    defaults.synchronize()
//}
//    -----------------------------------------------------------------------------------------------------------
//            PhoneAuthTestView()
//                .onOpenURL { url in
//                          print("Received URL: \(url)")
//                          Auth.auth().canHandle(url) // <- just for information purposes
//                        }


//class AppDelegate: NSObject, UIApplicationDelegate {
//  func application(_ application: UIApplication,
//                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
//    FirebaseApp.configure()
//
//    return true
//  }
//}

//        Auth.auth().settings?.isAppVerificationDisabledForTesting = false
//        print("Firebase Auth settings updated (Testing mode enabled)")

//    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
