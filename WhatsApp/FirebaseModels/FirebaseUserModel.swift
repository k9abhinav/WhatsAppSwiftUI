
import Foundation

struct FirebaseUserModel: Identifiable {
    var id: String { uid }  // Use uid as the identifier
    var uid: String
    var fullName: String
    var email: String?
    var phoneNumber: String?
    var profileImageURL: String?
   
}

