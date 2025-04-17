//
//  Job.swift
//  WorkTracker
//
//  Created by Tom Speake on 4/17/25.
//


import Foundation

struct Job: Identifiable, Codable {
    var id = UUID()
    var name: String
    var hourlyRate: Double
    var color: String // For visual identification
    var isActive: Bool = true
}