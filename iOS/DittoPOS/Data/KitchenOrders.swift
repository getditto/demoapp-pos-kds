import Foundation

enum KitchenOrders {
    static func select(from orders: [Order]) -> [Order] {
        orders.filter { ($0.status == .inProcess || $0.status == .processed) && !$0.cart.isEmpty }
            .sorted { lhs, rhs in
                if lhs.status == rhs.status { return lhs.createdAt > rhs.createdAt }
                return lhs.status.rank < rhs.status.rank
            }
    }
}
