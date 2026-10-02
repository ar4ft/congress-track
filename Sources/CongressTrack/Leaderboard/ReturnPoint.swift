import Foundation

struct ReturnPoint: Identifiable, Sendable {
    var id: Int { progress }
    let progress: Int
    let model: Double
    let benchmark: Double
}
