package live.ditto.pos.core.data.ditto.orders

const val ORDERS_COLLECTION_NAME = "orders"

const val LOCATION_ID_ATTRIBUTE_KEY = "locationId"

const val SALE_ITEM_ID_KEY = ":saleItemIdKey"

const val SUBSCRIPTION_QUERY = """
    SELECT * FROM COLLECTION $ORDERS_COLLECTION_NAME (saleItemIds MAP, transactionIds MAP)
    WHERE _id.locationId = :$LOCATION_ID_ATTRIBUTE_KEY
    """

const val GET_ORDERS_FOR_LOCATION_QUERY = """
    SELECT * FROM COLLECTION $ORDERS_COLLECTION_NAME (saleItemIds MAP, transactionIds MAP)
    WHERE _id.locationId = :$LOCATION_ID_ATTRIBUTE_KEY 
"""

const val INSERT_NEW_ORDER_QUERY = """
    INSERT INTO COLLECTION $ORDERS_COLLECTION_NAME (saleItemIds MAP, transactionIds MAP)
    DOCUMENTS (:new)
"""

const val ADD_ITEM_TO_ORDER_QUERY = """
    UPDATE COLLECTION $ORDERS_COLLECTION_NAME (saleItemIds MAP, transactionIds MAP)
    SET
        saleItemIds -> (
            $SALE_ITEM_ID_KEY = :saleItemIdValue
        ),
        status = :status
    WHERE _id = :_id
"""
