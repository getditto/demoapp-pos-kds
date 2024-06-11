package live.ditto.pos.di

import android.content.Context
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.android.qualifiers.ApplicationContext
import dagger.hilt.components.SingletonComponent
import live.ditto.ditto_wrapper.DittoManager
import live.ditto.pos.BuildConfig
import live.ditto.pos.core.domain.repository.CoreRepository

@Module
@InstallIn(SingletonComponent::class)
internal object AppModule {

    @Provides
    fun provideDittoManager(
        @ApplicationContext context: Context,
        @DittoOnlinePlaygroundAppId onlinePlaygroundAppId: String,
        @DittoOnlinePlaygroundAppToken dittoOnlinePlaygroundAppToken: String
    ): DittoManager {
        return DittoManager(
            context = context,
            dittoOnlinePlaygroundAppId = onlinePlaygroundAppId,
            dittoOnlinePlaygroundToken = dittoOnlinePlaygroundAppToken
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

    @Provides
    fun provideCoreRepository(@ApplicationContext context: Context): CoreRepository {
        return CoreRepository(context)
    }
}
