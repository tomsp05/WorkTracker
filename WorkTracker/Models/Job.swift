//
//  Job.swift
//  WorkTracker
//
//  Created by Tom Speake on 4/17/25.
//


import Foundation

struct Job: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String
    var hourlyRate: Double
    var color: String // For visual identification
    var isActive: Bool = true
    var presetShifts: [PresetShift] = [] // Added preset shifts array
}


//thifvnsfdeilvweivs is a a ttesdfnewijfnerkjfvnerwjkvnerwojvnweprivnewi
