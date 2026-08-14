# DittoPOS  

## Overview   

This app is designed to work on iPhone and iPad devices in both Portrait and Landscape orientation modes. It may be optimal to use 
iPhones as order entry devices in the POS tab in Landscape orientation, and iPad for KDS view, also in Landscape mode.

For support, please contact Ditto Support (<support@ditto.com>). 

## Project Setup and Run

### Installing from the App Store
If you'd like to just view the app, it is available in the [app store](https://apps.apple.com/us/app/ditto-pos/id6449074700). No setup is required for this. If you'd like to build and run the app, see the instructions below.

### Building and Running the App in Xcode
1. Clone this repo to a location on your machine, and open in Xcode.    
2. Navigate to the project `Signing & Capabilities` tab and modify the `Team and Bundle Identifier` settings to your Apple developer account 
credentials to provision building to your device.  
3. In your [Ditto portal](https://portal.ditto.live), create a database to generate a Database ID,
development token, and URL.   
4. In Terminal, from the **repository root** run `cp .env.template .env`. This `.env` is shared by the
iOS and Android apps.   
5. Edit `.env` to add the values from the portal (no quotes):   
``` bash
DITTO_DATABASE_ID=replace_with_your_database_id
DITTO_DEVELOPMENT_TOKEN=replace_with_your_development_token
DITTO_SERVER_URL=replace_with_your_server_url
```
6. Clean (**Command + Shift + K**), then build (**Command + B**). This generates `Env.swift` from the
root `.env`. The project is now configured for the portal app.    

