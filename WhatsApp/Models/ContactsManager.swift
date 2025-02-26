import Foundation
import Contacts
import SwiftUI

struct Contact: Identifiable {
    let id = UUID()
    let name: String
    let phone: String
    let imageData: Data?
}

@Observable class ContactsManager {
    var contacts: [Contact] = []
    private let contactStore = CNContactStore()

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
        DispatchQueue.global(qos: .userInitiated).async { // Run in background
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
                    self.contacts = fetchedContacts  // Update UI on main thread
                }

            } catch {
                print("Failed to fetch contacts: \(error)")
            }
        }
    }

}

