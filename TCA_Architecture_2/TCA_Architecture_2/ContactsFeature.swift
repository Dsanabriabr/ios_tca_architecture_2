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


@Reducer
struct ContactsFeature {
  @ObservableState
  struct State: Equatable {
    @Presents var alert: AlertState<Action.Alert>?
    @Presents var addContact: AddContactFeature.State?
    var contacts: IdentifiedArrayOf<Contact> = []
  }
    enum Action {
        case addButtonTapped
        case addContact(PresentationAction<AddContactFeature.Action>)
        case deleteButtonTapped(id: Contact.ID)
        case alert(PresentationAction<Alert>)
        enum Alert: Equatable {
            case confirmDeletion(id: Contact.ID )
        }
    }
  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .addButtonTapped:
          state.addContact = AddContactFeature.State(contact: Contact(id: UUID(), name: ""))
        return .none
      case .addContact(.presented(.delegate(.saveContact(let contact)))):
          state.contacts.append(contact)
          return .none
      case .addContact(.dismiss):
          return .none
      case .addContact(.presented(.setName(_))):
          return .none
      case .addContact(.presented(.cancelButtonTapped)):
          return .none
      case .addContact(.presented(.saveButtonTapped)):
          return .none
      case .deleteButtonTapped(id: let id):
          state.alert = AlertState {
                TextState("Are you sure?")
              } actions: {
                ButtonState(role: .destructive, action: .confirmDeletion(id: id)) {
                  TextState("Delete")
                }
              }
          return .none
      case .alert(.presented(.confirmDeletion(id: let id))):
          state.contacts.remove(id: id)
          return .none
      case .alert(.dismiss):
          return .none
      }
    }.ifLet(\.$addContact, action: \.addContact) {
        AddContactFeature()
    }
    .ifLet(\.$alert, action: \.alert)
  }
}

struct ContactsView: View {
  @Bindable var store: StoreOf<ContactsFeature>
    var addContactStore: Binding<StoreOf<AddContactFeature>?> {
      $store.scope(state: \.addContact, action: \.addContact)
    }
  var body: some View {
    NavigationStack {
      List {
        ForEach(store.contacts) { contact in
            HStack {
               Text(contact.name)
               Spacer()
               Button {
                 store.send(.deleteButtonTapped(id: contact.id))
               } label: {
                 Image(systemName: "trash")
                   .foregroundColor(.red)
               }
            }
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
    }
    .sheet(
      item: addContactStore) { addContactStore in
      NavigationStack {
        AddContactView(store: addContactStore)
      }
    }.alert($store.scope(state: \.alert, action: \.alert))
  }
}

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
