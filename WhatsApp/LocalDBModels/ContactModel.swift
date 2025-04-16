
import Foundation

struct Contact: Identifiable, Hashable {
    let id = UUID()
    var name: String
    var phone: String
    var imageData: Data?
}
