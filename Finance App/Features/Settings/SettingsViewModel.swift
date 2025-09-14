//
//  SettingsViewModel.swift
//  Finance App
//
//  Created by Jas  on 8/7/25.
//

import Foundation

// This ViewModel will manage the data and state for the Settings screen.
final class SettingsViewModel {
    
    // MARK: - Properties
    
    // A reference to our data fetching service.
    private let dataManager: SharedDataManager
    
    // State properties that the ViewController will observe.
    var isLoading: Bool = false {
        didSet {
            onLoadingStateChanged?(isLoading)
        }
    }
    
    // We can hold the profile here, but the primary update mechanism is the callback.
    private(set) var userProfile: UserProfile? {
        didSet {
            if let profile = userProfile {
                onProfileUpdate?(profile)
            }
        }
    }
    
    // MARK: - Callbacks for the View Controller
    
    /// The ViewController will implement this to know when to show/hide a loading indicator.
    var onLoadingStateChanged: ((Bool) -> Void)?
    
    /// The ViewController will implement this to receive the fetched user profile and update the UI.
    var onProfileUpdate: ((UserProfile) -> Void)?
    
    /// The ViewController will implement this to handle any errors during the fetch.
    var onFetchError: ((Error) -> Void)?
    
    
    // MARK: - Init
    
    // We initialize the ViewModel with the services it needs. This is called "Dependency Injection".
    init(dataManager: SharedDataManager = .shared) {
        self.dataManager = dataManager
    }
    
    // MARK: - Public Methods
    
    /// The main function for the ViewController to call to start the data fetching process.
    func loadData() {
        // 1. Try to load from the cache first for an instant UI update.
        if let cachedProfile = dataManager.loadProfileFromCache() {
            self.userProfile = cachedProfile
        }
        
        // 2. Only show the loading/shimmer state if the cache was empty.
        if self.userProfile == nil {
            self.isLoading = true
        }
        
        // 3. Always refresh the data from the server in the background.
        dataManager.reloadUserProfile { [weak self] result in
            // Make sure to switch to the main thread for UI-related updates
            DispatchQueue.main.async {
                // Always turn off the loading indicator once the network call is complete.
                self?.isLoading = false
                
                switch result {
                case .success(let freshProfile):
                    // Update the UI with the fresh profile data.
                    self?.userProfile = freshProfile
                case .failure(let error):
                    // If the fetch fails, we only trigger the error callback
                    // if we didn't have any cached data to show in the first place.
                    if self?.userProfile == nil {
                        self?.onFetchError?(error)
                    }
                }
            }
        }
    }
}
