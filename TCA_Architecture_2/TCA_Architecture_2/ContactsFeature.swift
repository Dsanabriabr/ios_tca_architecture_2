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
    @Presents var addContact: AddContactFeature.State?
    var contacts: IdentifiedArrayOf<Contact> = []
  }
  enum Action {
    case addButtonTapped
    case addContact(PresentationAction<AddContactFeature.Action>)
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
      }
    }.ifLet(\.$addContact, action: \.addContact) {
        AddContactFeature()
    }
  }
}

struct ContactsView: View {
  @Bindable var store: StoreOf<ContactsFeature>
  
  var body: some View {
    NavigationStack {
      List {
        ForEach(store.contacts) { contact in
          Text(contact.name)
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
      item: $store.scope(state: \.addContact, action: \.addContact)
    ) { addContactStore in
      NavigationStack {
        AddContactView(store: addContactStore)
      }
    }
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
