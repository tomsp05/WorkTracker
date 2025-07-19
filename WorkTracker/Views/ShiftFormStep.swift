// Create a new shared enum for form steps used in both AddShiftView and EditShiftView.
// Place in the project root or a suitable shared directory as appropriate for your project structure.

import Foundation

enum ShiftFormStep: Int, CaseIterable {
    case basics = 0
    case payment = 1
    case review = 2
    
    var title: String {
        switch self {
        case .basics: return "Basic Info"
        case .payment: return "Payment"
        case .review: return "Review & Save"
        }
    }
    
    var systemImage: String {
        switch self {
        case .basics: return "calendar.badge.clock"
        case .payment: return "dollarsign.circle"
        case .review: return "checkmark.circle"
        }
    }
}
