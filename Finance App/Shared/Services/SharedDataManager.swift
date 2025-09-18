//
//  SharedDataManager.swift
//  Finance App
//
//  Created by Jas  on 7/19/25.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

// MARK: - Shared DTOs

struct SharedBudgetData: Codable {
    let today: Double
    let yesterday: Double
    let weeklyBudget: Double
}

private struct CachedUserProfileHeader: Codable {
    let name: String
    let email: String
    let createdAt: Date
    let isBankConnected: Bool?
    let bankName: String?
}

/// Manages reading/writing small bits of data to the App Group container
/// and provides a simple on-device cache for the user's profile header.
final class SharedDataManager {
    
    // Singleton
    static let shared = SharedDataManager()
    private init() {}
    
    // MARK: Keys & Paths
    
    /// Replace with your actual App Group ID
    private let appGroupID = "group.com.singh.financeapp"
    
    private enum DefaultsKey {
        static let userProfileCache = "userProfileCache"
    }
    
    private var sharedFileURL: URL? {
        guard let groupContainer = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID) else {
            print("Error: Could not get shared container URL.")
            return nil
        }
        return groupContainer.appendingPathComponent("sharedBudgetData.json")
    }
    
    // MARK: State
    
    var currentUserProfile: UserProfile?
    
    // Saves the budget data to the shared JSON file.
    func save(_ data: SharedBudgetData) {
        guard let url = sharedFileURL else { return }
        do {
            let encoded = try JSONEncoder().encode(data)
            try encoded.write(to: url)
            print("Successfully saved data to shared container.")
        } catch {
            print("Error saving shared data: \(error.localizedDescription)")
        }
    }
    
    // Loads the budget data from the shared JSON file.
    func load() -> SharedBudgetData? {
        guard let url = sharedFileURL, FileManager.default.fileExists(atPath: url.path) else {
            return nil
        }
        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode(SharedBudgetData.self, from: data)
        } catch {
            print("Error loading shared data: \(error.localizedDescription)")
            return nil
        }
    }
    
    // MARK: Profile Header Cache (UserDefaults)
    
    /// Saves the user profile to the local device cache (UserDefaults).
    /// - Parameter profile: The UserProfile object to save.
    func saveProfileToCache(_ profile: UserProfile) {
        let header = CachedUserProfileHeader(
            name: profile.name,
            email: profile.email,
            createdAt: profile.createdAt.dateValue(),
            isBankConnected: profile.isBankConnected,
            bankName: profile.bankName
        )
        do {
            let data = try JSONEncoder().encode(header)
            UserDefaults.standard.set(data, forKey: DefaultsKey.userProfileCache)
            print("Successfully saved profile header to cache.")
        } catch {
            print("Error saving profile header to cache: \(error.localizedDescription)")
        }
    }
    
    /// Loads the user profile from the local device cache.
    /// - Returns: A UserProfile object if one is cached, otherwise nil.
    func loadProfileFromCache() -> UserProfile? {
        guard let data = UserDefaults.standard.data(forKey: DefaultsKey.userProfileCache) else {
            return nil
        }
        do {
            let header = try JSONDecoder().decode(CachedUserProfileHeader.self, from: data)
            return UserProfile(
                id: nil,
                name: header.name,
                email: header.email,
                createdAt: Timestamp(date: header.createdAt),
                isBankConnected: header.isBankConnected,
                bankName: header.bankName,
                accountSummaries: nil
            )
        } catch {
            print("Error loading profile header from cache: \(error.localizedDescription)")
            UserDefaults.standard.removeObject(forKey: DefaultsKey.userProfileCache)
            return nil
        }
    }
    
    // MARK: Firestore Reload
    
    func reloadUserProfile(completion: @escaping (Result<UserProfile, Error>) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else {
            completion(.failure(NSError(domain: "Auth", code: -1, userInfo: [NSLocalizedDescriptionKey: "No signed-in user."])))
            return
        }
        
        Firestore.firestore()
            .collection("users")
            .document(uid)
            .getDocument { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                do {
                    guard let profile = try snapshot?.data(as: UserProfile.self) else {
                        let err = NSError(
                            domain: "AppError",
                            code: 404,
                            userInfo: [NSLocalizedDescriptionKey: "User profile not found or could not be decoded."]
                        )
                        completion(.failure(err))
                        return
                    }
                    self.currentUserProfile = profile
                    self.saveProfileToCache(profile)
                    completion(.success(profile))
                } catch {
                    completion(.failure(error))
                }
            }
    }
}

// MARK: - JSON Date Strategies (available if needed elsewhere)

extension JSONEncoder.DateEncodingStrategy {
    static let iso8601withFractionalSeconds = custom { date, encoder in
        var container = encoder.singleValueContainer()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        try container.encode(formatter.string(from: date))
    }
}

extension JSONDecoder.DateDecodingStrategy {
    static let iso8601withFractionalSeconds = custom { decoder in
        let container = try decoder.singleValueContainer()
        let dateString = try container.decode(String.self)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        if let date = formatter.date(from: dateString) {
            return date
        }
        throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid date: \(dateString)")
    }
}
