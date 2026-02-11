import Foundation

protocol RewardedAdProvider {
    func loadRewardedAd()
    func presentRewardedAd(from placement: String, completion: @escaping (Bool) -> Void)
}

final class StubRewardedAdProvider: RewardedAdProvider {
    func loadRewardedAd() {}

    func presentRewardedAd(from placement: String, completion: @escaping (Bool) -> Void) {
        _ = placement
        completion(true)
    }
}

#if canImport(StoreKit)
import StoreKit

enum IAPProductID: String {
    case removeAds = "com.example.qbpocket.removeads"
}

@available(iOS 15.0, *)
final class StoreKitManager {
    func purchaseRemoveAds() async throws -> Bool {
        // Placeholder only; real product setup required in App Store Connect.
        _ = IAPProductID.removeAds.rawValue
        return false
    }
}
#endif
