import Foundation

final class ProgressionStore {
    enum Attribute: String, CaseIterable, Codable {
        case power
        case accuracy
        case releaseTime
        case speed
        case awareness
    }

    struct Attributes: Codable {
        var power = 1
        var accuracy = 1
        var releaseTime = 1
        var speed = 1
        var awareness = 1
    }

    struct Model: Codable {
        var coins: Int
        var attributes: Attributes
        var cosmetics: [String]
        var removeAdsEntitled: Bool
    }

    private let key = "progression.store.model"
    private let defaults: UserDefaults

    private(set) var model: Model
    let maxTier = 10

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: key),
           let decoded = try? JSONDecoder().decode(Model.self, from: data) {
            self.model = decoded
        } else {
            self.model = Model(coins: 0, attributes: Attributes(), cosmetics: [], removeAdsEntitled: false)
        }
    }

    func addCoins(_ amount: Int) {
        model.coins += max(0, amount)
        save()
    }

    @discardableResult
    func applyUpgrade(_ attribute: Attribute, cost: Int) -> Bool {
        guard model.coins >= cost else { return false }

        switch attribute {
        case .power:
            guard model.attributes.power < maxTier else { return false }
            model.attributes.power += 1
        case .accuracy:
            guard model.attributes.accuracy < maxTier else { return false }
            model.attributes.accuracy += 1
        case .releaseTime:
            guard model.attributes.releaseTime < maxTier else { return false }
            model.attributes.releaseTime += 1
        case .speed:
            guard model.attributes.speed < maxTier else { return false }
            model.attributes.speed += 1
        case .awareness:
            guard model.attributes.awareness < maxTier else { return false }
            model.attributes.awareness += 1
        }

        model.coins -= cost
        save()
        return true
    }

    func unlockCosmetic(_ id: String) {
        guard !model.cosmetics.contains(id) else { return }
        model.cosmetics.append(id)
        save()
    }

    func setRemoveAdsEntitlement(_ entitled: Bool) {
        model.removeAdsEntitled = entitled
        save()
    }

    /// UI plan (non-SwiftUI implementation notes):
    /// 1) Upgrade screen: list attributes with current level, next effect, and cost button.
    /// 2) Header bar: coins total + draft stock quick chip.
    /// 3) Confirm modal before spending coins.
    /// 4) Cosmetics tab: owned/unowned grid, no gameplay stats shown.
    func save() {
        if let data = try? JSONEncoder().encode(model) {
            defaults.set(data, forKey: key)
        }
    }
}
