//
//  ContentView.swift
//  HereAlready!!
//
//  Created by Curtis chang on 2/5/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject var sharedSearchViewModel = SearchViewModel()
    var body: some View {
        GeometryReader { geometry in
            let screenHeight = geometry.size.height
            let bottomSafeArea = geometry.safeAreaInsets.bottom

            let expandedYOffset = screenHeight * 0.05
            let collapsedYOffset = screenHeight - 100
            
            _SlidingPanelView(
                sharedSearchViewModel: sharedSearchViewModel,
                expandedYOffset: expandedYOffset,
                collapsedYOffset: collapsedYOffset,
                screenHeight: screenHeight,
                bottomSafeArea: bottomSafeArea
            )
        }
        .edgesIgnoringSafeArea(.all)
    }
}

fileprivate struct _SlidingPanelView: View {
    @ObservedObject var sharedSearchViewModel: SearchViewModel
    let expandedYOffset: CGFloat
    let collapsedYOffset: CGFloat
    let screenHeight: CGFloat
    let bottomSafeArea: CGFloat

    @State private var currentYOffset: CGFloat

    init(sharedSearchViewModel: SearchViewModel, expandedYOffset: CGFloat, collapsedYOffset: CGFloat, screenHeight: CGFloat, bottomSafeArea: CGFloat) {
        self.sharedSearchViewModel = sharedSearchViewModel
        self.expandedYOffset = expandedYOffset
        self.collapsedYOffset = collapsedYOffset
        self.screenHeight = screenHeight
        self.bottomSafeArea = bottomSafeArea
        _currentYOffset = State(initialValue: sharedSearchViewModel.isFocused ? expandedYOffset : collapsedYOffset)
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            Map()
                .edgesIgnoringSafeArea(.all)
            
            SearchPage(viewModel: sharedSearchViewModel)
                .frame(height: screenHeight - expandedYOffset + bottomSafeArea)
                .offset(y: currentYOffset)
        }
        .onChange(of: sharedSearchViewModel.isFocused) { _, isFocused in
            withAnimation(.interactiveSpring(response: 0.45, dampingFraction: 0.75, blendDuration: 0.3)) {
                currentYOffset = isFocused ? expandedYOffset : collapsedYOffset
            }
        }
    }
}

#Preview {
    ContentView()
}
