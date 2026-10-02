import Foundation

enum ReturnFormat {
    static func percent(_ value: Double) -> String {
        (value / 100).formatted(.percent.precision(.fractionLength(2)).sign(strategy: .always(includingZero: false)))
    }
    static func points(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(2)).sign(strategy: .always(includingZero: false))) + " pp"
    }
}
