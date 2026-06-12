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
        @DittoDatabaseId databaseId: String,
        @DittoDevelopmentToken developmentToken: String,
        @DittoUrl url: String
    ): DittoManager {
        return DittoManager(
            context = context,
            dittoDatabaseId = databaseId,
            dittoDevelopmentToken = developmentToken,
            dittoUrl = url
        )
    }

    @DittoDatabaseId
    @Provides
    fun provideDittoDatabaseId(): String {
        return BuildConfig.DITTO_DATABASE_ID
    }

    @DittoDevelopmentToken
    @Provides
    fun provideDittoDevelopmentToken(): String {
        return BuildConfig.DITTO_DEVELOPMENT_TOKEN
    }

    @DittoUrl
    @Provides
    fun provideDittoUrl(): String {
        return BuildConfig.DITTO_URL
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
