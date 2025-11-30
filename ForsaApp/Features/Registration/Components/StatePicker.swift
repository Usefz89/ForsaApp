//
//  StatePicker.swift
//  ForsaApp
//
//  Created by AI Assistant on 11/26/25.
//

import SwiftUI

/// US State picker component
struct StatePicker: View {
    @Binding var selectedState: String
    var label: String = "State"
    var placeholder: String = "Select a state"
    
    @State private var showPicker = false
    
    private var selectedUSState: USState? {
        USState(rawValue: selectedState)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.inputLabel)
                .foregroundColor(.textPrimary)
            
            Button(action: { showPicker = true }) {
                HStack {
                    if let state = selectedUSState {
                        Text("\(state.fullName) (\(state.rawValue))")
                            .font(.inputText)
                            .foregroundColor(.textPrimary)
                    } else if !selectedState.isEmpty {
                        Text(selectedState)
                            .font(.inputText)
                            .foregroundColor(.textPrimary)
                    } else {
                        Text(placeholder)
                            .font(.inputText)
                            .foregroundColor(.textTertiary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .foregroundColor(.textTertiary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(Color.backgroundCard)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.borderPrimary, lineWidth: 1)
                )
            }
        }
        .sheet(isPresented: $showPicker) {
            StatePickerListSheet(selectedState: $selectedState)
        }
    }
}

// MARK: - State Picker List Sheet

struct StatePickerListSheet: View {
    @Binding var selectedState: String
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    
    private var filteredStates: [USState] {
        if searchText.isEmpty {
            return USState.allCases
        }
        return USState.allCases.filter {
            $0.fullName.localizedCaseInsensitiveContains(searchText) ||
            $0.rawValue.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    // Group states by region
    private var statesByRegion: [(region: String, states: [USState])] {
        let regions: [(String, [USState])] = [
            ("Northeast", [.CT, .ME, .MA, .NH, .NJ, .NY, .PA, .RI, .VT]),
            ("Southeast", [.AL, .AR, .FL, .GA, .KY, .LA, .MD, .MS, .NC, .SC, .TN, .VA, .WV, .DC]),
            ("Midwest", [.IL, .IN, .IA, .KS, .MI, .MN, .MO, .NE, .ND, .OH, .SD, .WI]),
            ("Southwest", [.AZ, .NM, .OK, .TX]),
            ("West", [.AK, .CA, .CO, .HI, .ID, .MT, .NV, .OR, .UT, .WA, .WY])
        ]
        return regions
    }
    
    var body: some View {
        NavigationStack {
            List {
                if searchText.isEmpty {
                    // Show grouped by region
                    ForEach(statesByRegion, id: \.region) { region in
                        Section(region.region) {
                            ForEach(region.states) { state in
                                stateRow(state)
                            }
                        }
                    }
                } else {
                    // Show flat filtered list
                    ForEach(filteredStates) { state in
                        stateRow(state)
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search states")
            .navigationTitle("Select State")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.primaryPurple)
                }
            }
        }
    }
    
    private func stateRow(_ state: USState) -> some View {
        Button(action: {
            selectedState = state.rawValue
            dismiss()
        }) {
            HStack {
                Text(state.fullName)
                    .font(.body)
                    .foregroundColor(.textPrimary)
                
                Spacer()
                
                Text(state.rawValue)
                    .font(.callout)
                    .foregroundColor(.textTertiary)
                
                if state.rawValue == selectedState {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.body)
                        .foregroundColor(.primaryPurple)
                        .padding(.leading, 8)
                }
            }
            .padding(.vertical, 4)
        }
    }
}

// MARK: - Compact State Selector

/// Compact inline state selector with abbreviations
struct CompactStatePicker: View {
    @Binding var selectedState: String
    var label: String?
    
    @State private var showPicker = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let label = label {
                Text(label)
                    .font(.inputLabel)
                    .foregroundColor(.textPrimary)
            }
            
            Button(action: { showPicker = true }) {
                HStack {
                    Text(selectedState.isEmpty ? "State" : selectedState)
                        .font(.inputText)
                        .foregroundColor(selectedState.isEmpty ? .textTertiary : .textPrimary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.down")
                        .font(.system(size: 10))
                        .foregroundColor(.textTertiary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 14)
                .background(Color.backgroundCard)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.borderPrimary, lineWidth: 1)
                )
            }
        }
        .sheet(isPresented: $showPicker) {
            StatePickerListSheet(selectedState: $selectedState)
        }
    }
}

// MARK: - State Chips Selector

/// Horizontal scrolling state chips for popular states
struct StateChipsSelector: View {
    @Binding var selectedState: String
    var label: String?
    
    // Most populous states
    private let popularStates: [USState] = [
        .CA, .TX, .FL, .NY, .PA, .IL, .OH, .GA, .NC, .MI
    ]
    
    @State private var showFullPicker = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let label = label {
                HStack {
                    Text(label)
                        .font(.inputLabel)
                        .foregroundColor(.textPrimary)
                    
                    Spacer()
                    
                    Button(action: { showFullPicker = true }) {
                        Text("See all")
                            .font(.caption1)
                            .foregroundColor(.primaryPurple)
                    }
                }
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(popularStates) { state in
                        StateChip(
                            state: state,
                            isSelected: state.rawValue == selectedState,
                            action: { selectedState = state.rawValue }
                        )
                    }
                    
                    // "Other" button
                    Button(action: { showFullPicker = true }) {
                        Text("Other...")
                            .font(.caption1Medium)
                            .foregroundColor(.primaryPurple)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.primaryPurple.opacity(0.1))
                            .cornerRadius(20)
                    }
                }
                .padding(.horizontal, 1)
            }
        }
        .sheet(isPresented: $showFullPicker) {
            StatePickerListSheet(selectedState: $selectedState)
        }
    }
}

struct StateChip: View {
    let state: USState
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(state.rawValue)
                .font(.caption1Medium)
                .foregroundColor(isSelected ? .white : .textPrimary)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(isSelected ? Color.primaryPurple : Color.backgroundCard)
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(isSelected ? Color.primaryPurple : Color.borderPrimary, lineWidth: 1)
                )
        }
    }
}

// MARK: - State Grid Picker

/// Grid layout state picker for full-screen selection
struct StateGridPicker: View {
    @Binding var selectedState: String
    var columns: Int = 4
    
    private var gridColumns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 8), count: columns)
    }
    
    var body: some View {
        LazyVGrid(columns: gridColumns, spacing: 8) {
            ForEach(USState.allCases) { state in
                Button(action: { selectedState = state.rawValue }) {
                    Text(state.rawValue)
                        .font(.calloutMedium)
                        .foregroundColor(state.rawValue == selectedState ? .white : .textPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(state.rawValue == selectedState ? Color.primaryPurple : Color.backgroundCard)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(state.rawValue == selectedState ? Color.primaryPurple : Color.borderPrimary, lineWidth: 1)
                        )
                }
            }
        }
    }
}

// MARK: - Previews

#Preview("State Picker") {
    VStack(spacing: 24) {
        StatePicker(selectedState: .constant(""))
        StatePicker(selectedState: .constant("CA"))
    }
    .padding()
}

#Preview("Compact State Picker") {
    HStack(spacing: 12) {
        CompactStatePicker(selectedState: .constant(""), label: "State")
        CompactStatePicker(selectedState: .constant("NY"), label: "State")
    }
    .padding()
}

#Preview("State Chips") {
    StateChipsSelector(selectedState: .constant("TX"), label: "Select State")
        .padding()
}

#Preview("State Grid") {
    ScrollView {
        StateGridPicker(selectedState: .constant("CA"))
            .padding()
    }
}


