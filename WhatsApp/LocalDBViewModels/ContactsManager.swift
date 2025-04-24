import Contacts
import SwiftData
import SwiftUI

@Observable
class ContactsManager {
    var contacts: [Contact] = []
    private let contactStore = CNContactStore()
    private let modelContext: ModelContext
    var isAccessGranted: Bool {
        get { UserDefaults.standard.bool(forKey: "ContactsAccessGranted") }
        set { UserDefaults.standard.set(newValue, forKey: "ContactsAccessGranted") }
    }

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        if isAccessGranted {
            fetchContactsIfNeeded()
        }
    }

    func requestAccess() {
        contactStore.requestAccess(for: .contacts) { granted, error in
            DispatchQueue.main.async {
                if granted {
                    self.isAccessGranted = true
                    self.fetchContactsIfNeeded()
                } else {
                    print("Access Denied: \(error?.localizedDescription ?? "Unknown Error")")
                }
            }
        }
    }

    private func fetchContactsIfNeeded() {
        guard contacts.isEmpty else { return } // Avoid redundant fetching

        DispatchQueue.global(qos: .background).async {
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
                    self.createUsersIfNeeded()
                }
            } catch {
                print("Failed to fetch contacts: \(error)")
            }
        }
    }

    private func createUsersIfNeeded() {
        for contact in contacts {
            if !isUserExisting(phone: contact.phone) {
                let newUser = User(
                    id: UUID().uuidString,
                    phone: contact.phone,
                    name: contact.name,
                    imageData: contact.imageData,
                    chats: []
                )
                modelContext.insert(newUser)
            }
        }

        do {
            try modelContext.save()
        } catch {
            print("Failed to save users: \(error)")
        }
    }

    private func isUserExisting(phone: String) -> Bool {
        let descriptor = FetchDescriptor<User>(predicate: #Predicate { $0.phone == phone })
        return (try? modelContext.fetch(descriptor))?.isEmpty == false
    }
}
