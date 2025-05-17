//
//  SearchPage.swift
//  HereAlready!!
//
//  Created by Curtis chang on 7/5/25.
//

import SwiftUI

struct SearchPage: View {
    @StateObject var searchViewModel: SearchViewModel
    
    // Local FocusState for the TextField, specific to this View's instance of the TextField
    @FocusState private var textFieldIsFocused: Bool
    
    // This is basically a constructor
    init(viewModel: SearchViewModel = SearchViewModel()) {
        _searchViewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        VStack {
            TextField("Where do you want to go?", text: $searchViewModel.searchText)
                .padding()
                .textFieldStyle(.roundedBorder)
                .focused($textFieldIsFocused)
            
            // Results list, only shows when the ViewModel indicates it should be focused, if textfield is empty, nothing will show
            // TODO: change it to show recent if empty
            if searchViewModel.isFocused {
                if !searchViewModel.displayItems.isEmpty {
                    List(searchViewModel.displayItems, id: \.self) { place in
                        Text(place)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                searchViewModel.selectPlace(place)
                            }
                    }
                    .listStyle(.plain)
                    .frame(maxHeight: 250)
                    .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8) // Match corner radius with typical UI elements
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1) // Subtle border
                    )
                    .padding(.horizontal) // Add some horizontal padding for the list container itself
                } else if !searchViewModel.searchText.isEmpty {
                    Text("No results found")
                        .padding()
                        .foregroundColor(.gray)
                }
            }

            Spacer()
        }
        .background(Material.regular)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
        .padding(.vertical)
        .onChange(of: searchViewModel.isFocused) { oldValue, newValue in
            if textFieldIsFocused != newValue {
                textFieldIsFocused = newValue
            }
        }
        .onChange(of: textFieldIsFocused) { oldValue, newValue in
            if searchViewModel.isFocused != newValue {
                searchViewModel.isFocused = newValue
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if searchViewModel.isFocused {
                searchViewModel.isFocused = false
            }
        }
    }

}

#Preview {
    SearchPage()
}
