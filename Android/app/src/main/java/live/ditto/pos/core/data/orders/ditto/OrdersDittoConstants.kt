package live.ditto.pos.core.data.orders.ditto

const val ORDERS_COLLECTION_NAME = "orders"

const val LOCATION_ID_ATTRIBUTE_KEY = "locationId"

const val ORDERS_SALE_ITEM_ID_PLACEHOLDER = "{saleItemIdKey}"
const val ORDERS_TRANSACTION_ID_PLACEHOLDER = "{transactionId}"

const val SUBSCRIPTION_QUERY = """
    SELECT * FROM COLLECTION $ORDERS_COLLECTION_NAME (saleItemIds MAP, transactionIds MAP)
    WHERE _id.locationId = :$LOCATION_ID_ATTRIBUTE_KEY
        AND createdOn > :$TTL_ATTRIBUTE_KEY
    """

const val GET_ORDERS_FOR_LOCATION_QUERY = """
    SELECT * FROM COLLECTION $ORDERS_COLLECTION_NAME (saleItemIds MAP, transactionIds MAP)
    WHERE _id.locationId = :$LOCATION_ID_ATTRIBUTE_KEY
"""

const val TTL_ATTRIBUTE_KEY = "ttl"

const val GET_ORDERS_FOR_LOCATION_WITH_TTL_QUERY = """
    SELECT * FROM COLLECTION $ORDERS_COLLECTION_NAME (saleItemIds MAP, transactionIds MAP)
    WHERE _id.locationId = :$LOCATION_ID_ATTRIBUTE_KEY
        AND createdOn > :$TTL_ATTRIBUTE_KEY
"""

const val INSERT_NEW_ORDER_QUERY = """
    INSERT INTO COLLECTION $ORDERS_COLLECTION_NAME (saleItemIds MAP, transactionIds MAP)
    DOCUMENTS (:new)
    ON ID CONFLICT DO NOTHING
"""

const val ADD_ITEM_TO_ORDER_QUERY = """
    UPDATE COLLECTION $ORDERS_COLLECTION_NAME (saleItemIds MAP, transactionIds MAP)
    SET
        saleItemIds -> (
            `$ORDERS_SALE_ITEM_ID_PLACEHOLDER` = :saleItemIdValue
        ),
        status = :status
    WHERE _id = :_id
"""

const val UPDATE_ORDER_STATUS_QUERY = """
    UPDATE $ORDERS_COLLECTION_NAME
    SET status = :status
    WHERE _id = :_id
"""

const val ADD_TRANSACTION_TO_ORDER_QUERY = """
    UPDATE COLLECTION $ORDERS_COLLECTION_NAME (transactionIds MAP)
    SET
        transactionIds -> (
            `$ORDERS_TRANSACTION_ID_PLACEHOLDER` = :status
        )
    WHERE _id = :_id
"""

const val CLEAR_SALE_ITEMS_ORDER_QUERY = """
    UPDATE COLLECTION $ORDERS_COLLECTION_NAME (saleItemIds MAP)
    SET
        saleItemIds -> tombstone()
    WHERE _id = :_id
"""
