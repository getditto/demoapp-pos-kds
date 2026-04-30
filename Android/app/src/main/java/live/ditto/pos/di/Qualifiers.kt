package live.ditto.pos.di

import javax.inject.Qualifier

@Qualifier
@Retention(AnnotationRetention.BINARY)
annotation class DittoOnlinePlaygroundAppId

@Qualifier
@Retention(AnnotationRetention.BINARY)
annotation class DittoOnlinePlaygroundAppToken

@Qualifier
@Retention(AnnotationRetention.BINARY)
annotation class DittoWebsocketURL
