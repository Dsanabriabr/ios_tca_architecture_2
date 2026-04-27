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

    @Test func addFlow() async throws {
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

}
