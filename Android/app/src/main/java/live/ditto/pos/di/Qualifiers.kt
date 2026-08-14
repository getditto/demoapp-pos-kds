package live.ditto.pos.di

import javax.inject.Qualifier

@Qualifier
@Retention(AnnotationRetention.BINARY)
annotation class DittoDatabaseId

@Qualifier
@Retention(AnnotationRetention.BINARY)
annotation class DittoDevelopmentToken

@Qualifier
@Retention(AnnotationRetention.BINARY)
annotation class DittoServerUrl
