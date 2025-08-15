//
//  MigrationManager.swift
//  WorkTracker
//
//  Created by Tom Speake on 8/15/25.
//


import Foundation

class MigrationManager {
    static let shared = MigrationManager()
    private let standardDefaults = UserDefaults.standard
    private let sharedDefaults = UserDefaults(suiteName: "group.com.TomSpeake.WorkTracker")!
    private let migrationKey = "hasMigratedToiCloud"

    func migrateIfNeeded() {
        if !standardDefaults.bool(forKey: migrationKey) {
            // Step 1: Migrate from standard UserDefaults to App Group UserDefaults
            if let jobsData = standardDefaults.data(forKey: "saved_jobs") {
                sharedDefaults.set(jobsData, forKey: "saved_jobs")
            }
            if let shiftsData = standardDefaults.data(forKey: "saved_shifts") {
                sharedDefaults.set(shiftsData, forKey: "saved_shifts")
            }

            // Step 2: Migrate from App Group UserDefaults to iCloud
            if let jobsData = sharedDefaults.data(forKey: "saved_jobs"),
               let jobs = try? JSONDecoder().decode([Job].self, from: jobsData) {
                DataService.shared.saveJobsToiCloud(jobs: jobs)
            }
            // ... similar logic for shifts ...

            // Step 3: Mark migration as complete
            standardDefaults.set(true, forKey: migrationKey)
        }
    }
}