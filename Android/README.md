# Ditto PoS KDS - Android

Android version of the PoS KDS demo app

Currently a work in progress, but will be expected to have feature parity with the iOS version, as
well as a DQL implementation.

## Building the App

You need to setup some environment variables in order to build this project:

1. Create/login to your account on the [Ditto portal](https://portal.ditto.live/apps)
2. Follow the steps to create/add an app (if you haven't already). Doing so will create the ID and
   token you will need for the next steps.
3. Open your `local.properties` file and add the following variables, replacing with your own
   information:

```  
dittoOnlinePlaygroundAppId="your app id"
dittoOnlinePlaygroundToken="your playground token"
 ```  

* `dittoOnlinePlaygroundAppId` is the App ID used by Ditto; this needs to be the same on each device
  running the
  app in order for them to see each other, including across different platforms.
* `dittoOnlinePlaygroundToken` is the online playground token. This is used when using the online
  playground identity type.