package live.ditto.pos.core.data

import kotlinx.datetime.Clock
import kotlinx.datetime.Instant
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import java.util.UUID

@Serializable
enum class PaymentType {
    @SerialName("cash")
    CASH,

    @SerialName("credit")
    CREDIT,

    @SerialName("debit")
    DEBIT,

    @SerialName("refund")
    REFUND
}

@Serializable
enum class PaymentStatus {
    @SerialName("incomplete")
    INCOMPLETE,

    @SerialName("inProcess")
    IN_PROCESS,

    @SerialName("complete")
    COMPLETE,

    @SerialName("failed")
    FAILED
}

@Serializable
data class Payment(
    val type: PaymentType,
    val amount: Price,
    val status: PaymentStatus = PaymentStatus.COMPLETE,
    @Serializable(with = DittoInstantSerializer::class)
    val createdAt: Instant = Clock.System.now()
) {
    companion object {
        fun newPaymentId(): String = UUID.randomUUID().toString()
    }
}
