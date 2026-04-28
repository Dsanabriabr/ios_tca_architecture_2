//
//  ContactsFeature.swift
//  TCA_Architecture_2
//
//  Created by Daniel Sanabria on 24/04/26.
//

import ComposableArchitecture
import Foundation
import SwiftUI

struct Contact: Equatable, Identifiable {
    let id: UUID
    var name: String
}

// MARK: - Feature
@Reducer
struct ContactsFeature {
    @ObservableState
    struct State: Equatable {
        @Presents var destination: Destination.State?
        var contacts: IdentifiedArrayOf<Contact> = []
        var path = StackState<ContactDetailFeature.State>()
    }
    enum Action {
        case addButtonTapped
        case destination(PresentationAction<Destination.Action>)
        case path(StackActionOf<ContactDetailFeature>)
        @CasePathable
        enum Alert: Equatable {
            case confirmDeletion(id: Contact.ID )
        }
    }
    @Dependency(\.uuid) var uuid
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .addButtonTapped:
                state.destination = .addContact(AddContactFeature.State(contact: Contact(id: uuid(), name: "")))
                return .none
            case .destination(.presented(.addContact(.delegate(.saveContact(let contact))))):
                state.contacts.append(contact)
                return .none
            case .destination(.presented(.alert(.confirmDeletion(id: let id)))):
                state.contacts.remove(id: id)
                return .none
            case .destination(.dismiss):
                return .none
            case .destination(.presented(.addContact(.cancelButtonTapped))):
                return .none
            case .destination(.presented(.addContact(.saveButtonTapped))):
                return .none
            case .destination(.presented(.addContact(.setName(_)))):
                return .none
            case let .path(.element(id: id, action: .delegate(.confirmDeletion))):
                guard let detailState = state.path[id: id]
                else { return .none }
                state.contacts.remove(id: detailState.contact.id)
                return .none
            case .path:
                return .none
            }
        }.ifLet(\.$destination, action: \.destination) {
            Destination.body
        }.forEach(\.path, action: \.path) {
            ContactDetailFeature()
        }
    }
}
extension ContactsFeature {
    @Reducer
    enum Destination {
        case addContact(AddContactFeature)
        case alert(AlertState<ContactsFeature.Action.Alert>)
    }
}
extension ContactsFeature.Destination.State: Equatable {}

// MARK: - View
struct ContactsView: View {
    @Bindable var store: StoreOf<ContactsFeature>
    var addContactStore: Binding<StoreOf<AddContactFeature>?> {
        $store.scope(state: \.$destination, action: \.destination).addContact
    }
    var body: some View {
        NavigationStack(path: $store.scope(state: \.path, action: \.path)) {
            List {
                ForEach(store.contacts) { contact in
                    NavigationLink(state: ContactDetailFeature.State(contact: contact)) {
                        HStack {
                            Text(contact.name)
                            Spacer()
                            Image(systemName: "trash")
                                .foregroundStyle(Color.red)
                        }
                    }
                    .buttonStyle(.borderless)
                }
            }
            .navigationTitle("Contacts")
            .toolbar {
                ToolbarItem {
                    Button {
                        store.send(.addButtonTapped)
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        } destination : { store in
            ContactDetailView(store: store)
        }
        .sheet(
            item: addContactStore) { addContactStore in
                NavigationStack {
                    AddContactView(store: addContactStore)
                }
            }.alert(
                $store.scope(state: \.$destination, action: \.destination).alert
            ) { action in
                guard let action = action else {return}
                store.send(.destination(.presented(.alert(action))))
            }
    }
}

// MARK: - Preview
#Preview {
    ContactsView(
        store: Store(
            initialState: ContactsFeature.State(
                contacts: [
                    Contact(id: UUID(), name: "Blob"),
                    Contact(id: UUID(), name: "Blob Jr"),
                    Contact(id: UUID(), name: "Blob Sr"),
                ]
            )
        ) {
            ContactsFeature()
        }
    )
}

// MARK: - AlertState
extension AlertState where Action == ContactsFeature.Action.Alert {
    static func deleteConfirmation(id: UUID) -> Self {
        Self {
            TextState("Are you sure?")
        } actions: {
            ButtonState(role: .destructive, action: .confirmDeletion(id: id)) {
                TextState("Delete")
            }
        }
    }
}
