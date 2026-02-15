import Foundation

struct PhysicsCategory {
    static let none: UInt32 = 0
    static let qb: UInt32 = 1 << 0
    static let football: UInt32 = 1 << 1
    static let receiver: UInt32 = 1 << 2
    static let defender: UInt32 = 1 << 3
    static let ground: UInt32 = 1 << 4
    static let endzone: UInt32 = 1 << 5
    static let boundary: UInt32 = 1 << 6
}
