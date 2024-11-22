//
//  ContentView.swift
//  medilook
//
//  Created by Dalli Sai Tejaswar Reddy on 11/17/24.
//

import SwiftUI
import AVFoundation

struct ContentView: View {
    @StateObject private var viewModel = MedicineViewModel()
    @State private var searchText = ""
    @State private var showingImagePicker = false
    @State private var showingCamera = false
    @State private var selectedImage: UIImage?
    @State private var cameraPermissionGranted = false
    @State private var showingHistory = false
    @State private var showingPermissionAlert = false
    @State private var showingUploadOptions = false
    @FocusState private var isSearchFocused: Bool
    @State private var searchTask: Task<Void, Never>?
    @Environment(\.colorScheme) private var colorScheme
    @State private var showingSettings = false
    
    var body: some View {
        NavigationView {
            mainContent
                .navigationBarHidden(true)
        }
    }
    
    private var mainContent: some View {
        ZStack {
            // Background
            AppColors.backgroundGradient
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                // Header
                headerView
                    .padding(.top, 40)
                
                // Search Bar
                searchBarSection
                    .padding(.horizontal)
                
                // Upload Button
                uploadButton
                    .padding(.horizontal)
                
                // Results
                resultsSection
                
                Spacer(minLength: 0)
            }
        }
        .overlay(alignment: .topTrailing) {
            HStack(spacing: 20) {
                Button(action: {
                    showingHistory = true
                }) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 18))
                        .foregroundColor(.blue)
                }
                
                Button(action: {
                    showingSettings = true
                }) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.blue)
                }
            }
            .padding()
        }
        .sheet(isPresented: $showingHistory) {
            SearchHistoryView(viewModel: viewModel)
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(image: $selectedImage, sourceType: .photoLibrary)
        }
        .sheet(isPresented: $showingCamera) {
            ImagePicker(image: $selectedImage, sourceType: .camera)
        }
        .sheet(isPresented: $showingUploadOptions) {
            UploadOptionsView(selectedImage: $selectedImage, viewModel: viewModel)
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView(viewModel: viewModel)
        }
        .alert("Camera Access Required", isPresented: $showingPermissionAlert) {
            Button("Go to Settings", role: .none) {
                if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsURL)
                }
            }
            Button("Cancel", role: .cancel) {}
        }
        .alert("Error", isPresented: .constant(viewModel.error != nil)) {
            Button("OK") {
                viewModel.error = nil
            }
        } message: {
            if let error = viewModel.error {
                Text(error)
            }
        }
    }
    
    private var headerView: some View {
        VStack(spacing: 15) {
            Text("MediLook")
                .font(.system(size: 35, weight: .bold, design: .rounded))
                .foregroundColor(colorScheme == .dark ? .white : .black)
        }
    }
    
    private var searchBarSection: some View {
        HStack {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(AppColors.secondaryText)
                    .padding(.leading, 12)
                
                TextField("Search medicines...", text: $searchText)
                    .autocapitalization(.none)
                    .focused($isSearchFocused)
                    .submitLabel(.search)
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                    .onChange(of: searchText) { oldValue, newValue in
                        searchTask?.cancel()
                        searchTask = Task {
                            try? await Task.sleep(nanoseconds: 300_000_000)
                            if !Task.isCancelled {
                                await MainActor.run {
                                    viewModel.searchMedicine(query: newValue)
                                }
                            }
                        }
                    }
                
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                        viewModel.searchResults = []
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(AppColors.secondaryText)
                    }
                    .padding(.trailing, 8)
                }
                
                if viewModel.isLoading {
                    ProgressView()
                        .padding(.trailing, 12)
                }
            }
            .padding(.vertical, 12)
            .background(colorScheme == .dark ? Color.black.opacity(0.3) : AppColors.searchBarBackground)
            .cornerRadius(15)
        }
    }
    
    private var uploadButton: some View {
        Button(action: {
            showingUploadOptions = true
        }) {
            HStack {
                Image(systemName: "doc.badge.plus")
                    .font(.system(size: 18))
                Text("Upload Prescription")
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(
                LinearGradient(
                    colors: [.white, .white.opacity(0.9)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .foregroundColor(.blue)
            .cornerRadius(15)
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
        .padding(.horizontal)
    }
    
    private var resultsSection: some View {
        Group {
            if !viewModel.searchResults.isEmpty {
                ScrollView {
                    LazyVStack(spacing: 15) {
                        ForEach(viewModel.searchResults) { medicine in
                            MedicineResultView(
                                medicine: medicine,
                                targetLanguage: "English",
                                viewModel: viewModel
                            )
                            .padding(.horizontal)
                        }
                    }
                }
                .transition(.opacity)
            } else if !searchText.isEmpty && !viewModel.isLoading {
                noResultsView
                    .transition(.opacity)
            } else if searchText.isEmpty {
                emptyStateView
                    .transition(.opacity)
            }
        }
    }
    
    private var noResultsView: some View {
        VStack(spacing: 20) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 45))
                .foregroundColor(.gray.opacity(0.5))
            Text("No results found for '\(searchText)'")
                .font(.headline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
            Text("Try searching with a different term")
                .font(.subheadline)
                .foregroundColor(.gray.opacity(0.7))
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground).opacity(0.5))
        .cornerRadius(15)
        .padding()
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "text.magnifyingglass")
                .font(.system(size: 45))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue.opacity(0.7), .blue.opacity(0.4)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            Text("Search for medicines or upload a prescription")
                .font(.headline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
            Text("Type a medicine name or use the camera")
                .font(.subheadline)
                .foregroundColor(.gray.opacity(0.7))
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.white.opacity(0.5))
        .cornerRadius(15)
        .padding()
    }
}


