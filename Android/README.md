# Ditto PoS KDS - Android

Android version of the PoS KDS demo app

Currently a work in progress, but will be expected to have feature parity with the iOS version, as
well as a DQL implementation.

## Building the App

You need to setup some environment variables in order to build this project:

1. Create/login to your account on the [Ditto portal](https://portal.ditto.live/apps)
2. Follow the steps to create/add an app (if you haven't already). Doing so will create the ID and
   token you will need for the next steps.
3. In your Android project root, create a directory called **secure**
4. Add a file to that directory called **creds.properties**, for the build variants as defined in
   the app **build.gradle** file.  
   Add the following environment variables to the credential file, substituting your own values:

```  
 # Environment Variables      
 DITTO_APP_ID = "replace with your app id"  
 DITTO_PLAYGROUND_TOKEN = "replace with your playground token" 
 DITTO_AUTH_PASSWORD = "replace with your auth password" 
 DITTO_AUTH_PROVIDER = "replace with your auth provider"
 DITTO_OFFLINE_TOKEN = "replace with your offline license token if applicable"
 ```  

* `DITTO_APP_ID` is the App ID used by Ditto; this needs to be the same on each device running the
  app in order for them to see each other, including across different platforms.
* `DITTO_PLAYGROUND_TOKEN` is the online playground token. This is used when using the online
  playground identity type.
* `DITTO_AUTH_PROVIDER` is the authentication provider name. This is used when using the online with
  authentication identity type.
* `DITTO_AUTH_PASSWORD` is the authentication password. This is used when using the online with
  authentication identity type.
* `DITTO_OFFLINE_TOKEN` is the offline-only playground token. This is used when using the offline
  playground identity type. Note this feature will be discontinued in the future.