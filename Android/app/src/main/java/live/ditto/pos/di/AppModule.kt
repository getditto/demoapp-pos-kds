package live.ditto.pos.di

import android.content.Context
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.android.qualifiers.ApplicationContext
import dagger.hilt.components.SingletonComponent
import kotlinx.coroutines.CoroutineDispatcher
import kotlinx.coroutines.Dispatchers
import live.ditto.ditto_wrapper.DittoManager
import live.ditto.pos.BuildConfig
import live.ditto.pos.settings.AppSettings
import javax.inject.Singleton

@Module
@InstallIn(SingletonComponent::class)
internal object AppModule {

    @Provides
    @Singleton
    fun provideDittoManager(
        @ApplicationContext context: Context,
        @DittoOnlinePlaygroundAppId onlinePlaygroundAppId: String,
        @DittoOnlinePlaygroundAppToken dittoOnlinePlaygroundAppToken: String,
        @DittoWebsocketURL dittoWebsocketURL: String,
        @DittoAuthURL dittoAuthURL: String
    ): DittoManager {
        return DittoManager(
            context = context,
            dittoOnlinePlaygroundAppId = onlinePlaygroundAppId,
            dittoOnlinePlaygroundToken = dittoOnlinePlaygroundAppToken,
            dittoWebsocketURL = dittoWebsocketURL,
            dittoAuthURL = dittoAuthURL
        )
    }

    @DittoOnlinePlaygroundAppId
    @Provides
    fun provideDittoOnlinePlaygroundAppId(): String {
        return BuildConfig.DITTO_ONLINE_PLAYGROUND_APP_ID
    }

    @DittoOnlinePlaygroundAppToken
    @Provides
    fun provideDittoOnlinePlaygroundAppToken(): String {
        return BuildConfig.DITTO_ONLINE_PLAYGROUND_TOKEN
    }

    @DittoWebsocketURL
    @Provides
    fun provideDittoWebsocketURL(): String {
        return BuildConfig.DITTO_WEBSOCKET_URL
    }

    @DittoAuthURL
    @Provides
    fun provideDittoAuthURL(): String {
        return BuildConfig.DITTO_AUTH_URL
    }

    @Provides
    fun provideAppSettings(@ApplicationContext context: Context): AppSettings {
        return AppSettings(context)
    }

    @Provides
    fun provideDispatcherIO(): CoroutineDispatcher {
        return Dispatchers.IO
    }
}
