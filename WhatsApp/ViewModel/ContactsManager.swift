
import Contacts
import SwiftData
import SwiftUI


@Observable class ContactsManager {
    var contacts: [Contact] = []
    private let contactStore = CNContactStore()
    
//    private var modelContext: ModelContext
//
//    init(modelContext: ModelContext) {
//        self.modelContext = modelContext
//    }

    func requestAccess() {
        contactStore.requestAccess(for: .contacts) { granted, error in
            if granted {
                self.fetchContacts()
            } else {
                print("Access Denied: \(error?.localizedDescription ?? "Unknown Error")")
            }
        }
    }

    private func fetchContacts() {
        DispatchQueue.global(qos: .userInitiated).async {
            let keys = [CNContactGivenNameKey, CNContactFamilyNameKey, CNContactPhoneNumbersKey, CNContactImageDataKey] as [CNKeyDescriptor]
            let request = CNContactFetchRequest(keysToFetch: keys)

            var fetchedContacts: [Contact] = []

            do {
                try self.contactStore.enumerateContacts(with: request) { contact, _ in
                    if let phoneNumber = contact.phoneNumbers.first?.value.stringValue {
                        let newContact = Contact(
                            name: "\(contact.givenName) \(contact.familyName)".trimmingCharacters(in: .whitespaces),
                            phone: phoneNumber,
                            imageData: contact.imageData
                        )
                        fetchedContacts.append(newContact)
                    }
                }

                DispatchQueue.main.async {
                    self.contacts = fetchedContacts
//                    self.saveContactsAsUsersIfNeeded()
                }
            } catch {
                print("Failed to fetch contacts: \(error)")
            }
        }
    }

//    private func saveContactsAsUsersIfNeeded() {
//        let modelContext = self.modelContext
//        for contact in contacts {
//            let phone = contact.phone
//            let fetchDescriptor = FetchDescriptor<User>(predicate: #Predicate { $0.phone == phone })
//            do {
//                let existingUsers = try modelContext.fetch(fetchDescriptor)
//                if existingUsers.isEmpty {
//                    let newUser = User(
//                        id: UUID().uuidString,
//                        phone: contact.phone,
//                        name: contact.name,
//                        imageData: contact.imageData,
//                        chats: [] // Initialize with empty chats
//                    )
//                    modelContext.insert(newUser)
//                    try modelContext.save()
//                    print("User created for phone: \(contact.phone)")
//                } else {
//                    print("User already exists for phone: \(contact.phone)")
//                }
//            } catch {
//                print("Error saving or fetching user: \(error)")
//            }
//        }
//    }
}
