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
        @DittoServerUrl serverUrl: String
    ): DittoManager = DittoManager(
        context = context,
        dittoDatabaseId = databaseId,
        dittoDevelopmentToken = developmentToken,
        dittoServerUrl = serverUrl
    )

    @DittoDatabaseId
    @Provides
    fun provideDittoDatabaseId(): String = BuildConfig.DITTO_DATABASE_ID

    @DittoDevelopmentToken
    @Provides
    fun provideDittoDevelopmentToken(): String = BuildConfig.DITTO_DEVELOPMENT_TOKEN

    @DittoServerUrl
    @Provides
    fun provideDittoServerUrl(): String = BuildConfig.DITTO_SERVER_URL

    @Provides
    fun provideAppSettings(@ApplicationContext context: Context): AppSettings = AppSettings(context)

    @Provides
    fun provideDispatcherIO(): CoroutineDispatcher = Dispatchers.IO
}
