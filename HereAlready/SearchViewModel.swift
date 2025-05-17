//
//  SearchViewModel.swift
//  HereAlready!!
//
//  Created by Curtis chang on 7/5/25.
//

import SwiftUI

class SearchViewModel: ObservableObject {
    @Published var searchText = ""
    @Published var isFocused = false
    
    // TODO: Google maps API for location, try to use async operations for API calls
    let allPlaces: [String] = ["NUS", "NTU", "SMU"]
    let recent: [String] = []
    
    var displayItems : [String] {
        if searchText.isEmpty {
            return recent
        } else {
            return allPlaces.filter {$0.lowercased().contains(searchText.lowercased())}
        }
    }
    
    func selectPlace(_ place: String) {
        searchText = place
        isFocused = false
    }
}
