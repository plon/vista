import Foundation

enum ProcessingStatus: Equatable {
    case none
    case processing
    case success
    case cancelled
    case error(String)
}
