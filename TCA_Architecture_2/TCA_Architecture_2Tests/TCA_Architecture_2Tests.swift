//
//  TCA_Architecture_2Tests.swift
//  TCA_Architecture_2Tests
//
//  Created by Daniel Sanabria on 24/04/26.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import TCA_Architecture_2

@MainActor
struct TCA_Architecture_2Tests {

    @Test func addContact() async throws {
        let store = TestStore(initialState: ContactsFeature.State()) {
            ContactsFeature()
        } withDependencies: {
            $0.uuid = .incrementing
        }
        await store.send(.addButtonTapped) {
              $0.destination = .addContact(
                AddContactFeature.State(
                  contact: Contact(id: UUID(0), name: "")
                )
              )
            }
        await store.send(\.destination.addContact.setName, "Blob Jr.") {
            $0.destination?.modify(\.addContact) { $0.contact.name = "Blob Jr." }

        }
        await store.send(\.destination.addContact.saveButtonTapped)
            await store.receive(
              \.destination.addContact.delegate.saveContact,
              Contact(id: UUID(0), name: "Blob Jr.")
            ) {
              $0.contacts = [
                Contact(id: UUID(0), name: "Blob Jr.")
              ]
            }
        await store.receive(\.destination.dismiss) {
              $0.destination = nil
            }
    }
    
    @Test func addContactNonExhaustive() async throws {
        let store = TestStore(initialState: ContactsFeature.State()) {
            ContactsFeature()
        } withDependencies: {
            $0.uuid = .incrementing
        }
        store.exhaustivity = .off
        
        await store.send(.addButtonTapped)
        await store.send(\.destination.addContact.setName, "Blob Jr.")
        await store.send(\.destination.addContact.saveButtonTapped)
        await store.skipReceivedActions()
        store.assert {
          $0.contacts = [
            Contact(id: UUID(0), name: "Blob Jr.")
          ]
          $0.destination = nil
        }
    }

    @Test func deleteContactNonExhaustive() async {
        let contactId = UUID(1)
        let contact = Contact(id: contactId, name: "Blob Jr.")
        let store = TestStore(
            initialState: ContactsFeature.State(
                contacts: [
                    Contact(id: UUID(0), name: "Blob"),
                    contact,
                ], path: StackState([
                    ContactDetailFeature.State(contact: contact)
                ])
            )) {
                ContactsFeature()
            }
        store.exhaustivity = .off
        
        // 1. Nav (action on path by stack)
        await store.send(.path(.element(id: 0, action: .deleteButtonTapped)))
        // 2. Confirm alert no detail
        await store.send(
            .path(.element(id: 0, action: .destination(.presented(.alert(.confirmDeletion)))))
        )
        await store.skipReceivedActions()
        store.assert {
            $0.path = StackState()
            $0.contacts = [
                Contact(id: UUID(0), name: "Blob")
            ]
            $0.destination = nil
        }
    }
}
