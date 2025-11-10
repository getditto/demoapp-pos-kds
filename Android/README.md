# DittoPOS  

## Overview    

The app is designed to work on both phones and tablets. There is *some* support for dark mode, but some UI elements may not appear correctly in terms of colors.

For support, please contact Ditto Support (<support@ditto.live>). 

## Project Setup and Run

### Installing from the App Store
If you'd like to just view the app, it is available in the [Play store](https://play.google.com/store/apps/details?id=live.ditto.pos). No setup is required for this. If you'd like to build and run the app, see the instructions below.

### Building and Running the App in Android Studio
1. In your [Ditto portal](https://portal.ditto.live), create an app to generate an App ID and 
playground token.  
2. Clone this repo to a location on your machine, and open in Android Studio.    
3. Create a `local.properties` file or if you already have one, open it. 
4. In the `local.properties` file add the following entries (keep the quotes):
```
dittoOnlinePlaygroundAppId="replace-with-your-app-id"
dittoOnlinePlaygroundToken="replace-with-your-playground-token"
dittoWebsocketURL="replace-with-your-websocket-url"
```
5. Hit the green play button to run the app

Compatible with Android Automotive OS (AAOS)