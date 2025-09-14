//
//  SharedDataManager.swift
//  Finance App
//
//  Created by Jas  on 7/19/25.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

// A Codable struct to easily save/load the data your widget needs.
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

// Manages reading and writing data to the shared App Group container.
final class SharedDataManager {
    static let shared = SharedDataManager()
    private init() {}
    // The App Group ID you created in Step 1.
    // !! IMPORTANT: Replace with your actual App Group ID !!
    private let appGroupID = "group.com.singh.financeapp"
    private static let userProfileCacheKey = "userProfileCache"
    
    var currentUserProfile: UserProfile?
    
    // The specific file URL within the shared container.
    private var sharedFileURL: URL? {
        guard let groupContainer = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID) else {
            print("Error: Could not get shared container URL.")
            return nil
        }
        return groupContainer.appendingPathComponent("sharedBudgetData.json")
    }
    
    // Saves the budget data to the shared JSON file.
    func save(_ data: SharedBudgetData) {
        guard let url = sharedFileURL else { return }
        do {
            let encodedData = try JSONEncoder().encode(data)
            try encodedData.write(to: url)
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
            let decodedData = try JSONDecoder().decode(SharedBudgetData.self, from: data)
            return decodedData
        } catch {
            print("Error loading shared data: \(error.localizedDescription)")
            return nil
        }
    }
    
    /// Saves the user profile to the local device cache (UserDefaults).
    /// - Parameter profile: The UserProfile object to save.
    func saveProfileToCache(_ profile: UserProfile) {
        // Map Firestore Timestamp -> Date for caching
        let header = CachedUserProfileHeader(
            name: profile.name,
            email: profile.email,
            createdAt: profile.createdAt.dateValue(),
            isBankConnected: profile.isBankConnected,
            bankName: profile.bankName
        )
        do {
            // For this DTO, default JSONEncoder is fine (no custom date strategy needed)
            let data = try JSONEncoder().encode(header)
            UserDefaults.standard.set(data, forKey: Self.userProfileCacheKey)
            print("Successfully saved profile header to cache.")
        } catch {
            print("Error saving profile header to cache: \(error.localizedDescription)")
        }
    }

    /// Loads the user profile from the local device cache.
    /// - Returns: A UserProfile object if one is cached, otherwise nil.
    func loadProfileFromCache() -> UserProfile? {
        guard let data = UserDefaults.standard.data(forKey: Self.userProfileCacheKey) else {
            return nil
        }
        do {
            let header = try JSONDecoder().decode(CachedUserProfileHeader.self, from: data)
            // Rehydrate a UserProfile just enough for UI (id/accountSummaries stay nil)
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
            UserDefaults.standard.removeObject(forKey: Self.userProfileCacheKey)
            return nil
        }
    }
    
    func reloadUserProfile(completion: @escaping (Result<UserProfile, Error>) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else {
            return completion(.failure(NSError(domain: "", code: -1)))
        }
        Firestore.firestore()
            .collection("users")
            .document(uid)
            .getDocument { snapshot, error in
                if let error = error {
                    return completion(.failure(error))
                }
                do {
                    guard let profile = try snapshot?.data(as: UserProfile.self) else {
                        // Create a custom error or use a generic one
                        let error = NSError(domain: "AppError", code: 404, userInfo: [NSLocalizedDescriptionKey: "User profile not found or could not be decoded."])
                        completion(.failure(error))
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
extension JSONEncoder.DateEncodingStrategy {
    static let iso8601withFractionalSeconds = custom { date, encoder in
        var container = encoder.singleValueContainer()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        let dateString = formatter.string(from: date)
        try container.encode(dateString)
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
