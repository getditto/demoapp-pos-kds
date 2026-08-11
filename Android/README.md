# DittoPOS  

## Overview    

The app is designed to work on both phones and tablets. There is *some* support for dark mode, but some UI elements may not appear correctly in terms of colors.

For support, please contact Ditto Support (<support@ditto.com>). 

## Project Setup and Run

### Installing from the App Store
If you'd like to just view the app, it is available in the [Play store](https://play.google.com/store/apps/details?id=live.ditto.pos). No setup is required for this. If you'd like to build and run the app, see the instructions below.

### Building and Running the App in Android Studio
1. In your [Ditto portal](https://portal.ditto.live), create a database to generate a Database ID,
development token, and URL.  
2. Clone this repo to a location on your machine, and open the `Android` project in Android Studio.    
3. From the **repository root**, run `cp .env.template .env`. This `.env` is shared by the iOS and
Android apps.
4. Edit `.env` to add the values from the portal (no quotes):
```
DITTO_DATABASE_ID=replace-with-your-database-id
DITTO_DEVELOPMENT_TOKEN=replace-with-your-development-token
DITTO_SERVER_URL=replace-with-your-server-url
```
5. Hit the green play button to run the app. (Android Studio manages `local.properties` for the
Android SDK location; credentials no longer go there.)

Compatible with Android Automotive OS (AAOS)
