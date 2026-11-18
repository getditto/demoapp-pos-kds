import Foundation

private final class StockPhotoBundle: NSObject {}

enum StockPhotos {
    private static let resources = [
        "00001": "burger", "00002": "burrito", "00003": "chicken", "00004": "chips",
        "00005": "coffee", "00006": "cookies", "00007": "corn", "00008": "fries",
        "00009": "fruit-salad", "00010": "gumbo", "00011": "ice-cream", "00012": "milk",
        "00013": "onion-rings", "00014": "pancakes", "00015": "pie", "00016": "salad",
        "00017": "sandwich", "00018": "soft-drink", "00019": "tacos", "00020": "veggies"
    ]

    static func data(for itemId: String) throws -> Data {
        let resource = resources[itemId]!
        let url = Bundle(for: StockPhotoBundle.self).url(forResource: resource, withExtension: "png", subdirectory: "StarterImages")!
        return try Data(contentsOf: url)
    }
}
