package live.ditto.pos.core.data.transactions.ditto

const val TRANSACTIONS_COLLECTION_NAME = "transactions"

const val INSERT_NEW_TRANSACTION_QUERY = """
    INSERT INTO $TRANSACTIONS_COLLECTION_NAME
    DOCUMENTS (:new)
    ON ID CONFLICT DO UPDATE
"""
