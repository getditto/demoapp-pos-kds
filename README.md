# DittoPOS  

## Overview  
This project is to demo very basic features of a POS (Point of Sale) system using Ditto, modeled on a fast food location operation, where customer orders can be input and are displayed in real time on a kitchen display that represents the order fulfillment workflow.  

The UI is presented as TabView with three tabs:  
- Locations list from which to select a location (restaurant)   
- Order input view (POS) to handle input of customer orders of menu items and simple payment function   
- Kitchen Display System view (KDS) to displays all orders for the selected location with a status of `inProcess` - meaning menu items are in process of being prepared, and `processed` - meaning prepared and ready for delivery  

This app is designed to work on iPhone and iPad devices in both Portrait and Landscape orientation modes. It may be optimal to use iPhones as order entry devices in the POS tab in Landscape orientation, and iPad for KDS view, also in Landscape mode.

## Demo Operations and Functionality  
Selection of a location is required to begin entering orders; on first launch, the landing view defaults to the Locations list. Enter order items in the POS tab view by tapping menu items. The item and its price appears in a list in the POS order view, with a total order cost and Pay and Cancel buttons beneath. Tap the Pay button to complete order entry and refresh the view with a new order, or tap the Cancel button to remove existing items.

A new order is created whenever a location is selected or an existing order is paid, and is set with status `open`. For every item added to the order, the order status is updated to `inProcess`. This is to demo a feature that the kitchen (KDS view) diplays orders in progress in real time so that they may be "in process" of being fulfilled even before order entry is complete. Every connected device running the app may individually create orders using the POS view.  

The KDS view displays `inProcess` and `processed` orders to demonstrate the flow of the order through this simplified restaurant fulfillment chain. An `inProcess` order is displayed in the KDS view as soon as the first order item is added. When the order is paid (in POS view), a double dollar sign will appear on the bottom border of that KDS order view, which indicates order entry is complete. Tap once on the blue `inProcess` order to update its status to `processed`, which changes to green. This demonstrates that the order has flowed to the next step in the fulfillment workflow to "ready for delivery". It might be that a location has a kitchen team preparing orders and a delivery team delivering orders. A kitchen team member would tap the order when finished preparing it, alerting delivery team members of its readiness for packaging and delivery to the customer. A tap on a green order advances its status to `delivered`, at which point it disappears from KDS view, signifying that the order has been completely fulfilled.  

## Notes 
- It is possible to be entering an order in the POS view, and while also appearing in the KDS view for the status of the order to be advanced (by way of two taps) to `delivered` and therefore no longer displayed in the KDS view. Because the KDS view displays orders as they are entered from any device on the mesh, and because this demo does not prevent orders from being advanced/fulfilled without being paid, it is possible to advance an order out of view before it is completed/paid. However, if another item is added to the order, the status will once again become `.inProcess` and it will again appear in the KDS view. However, if the order (at this point only visible in the POS view) is paid by tapping the Pay button, the POS view will refresh with a new empty order. Though invisible in the app, the order will represent a fulfilled, paid order, and this can be viewed in the portal data browser. 

    Additionally, the app may be force quit at any time with an empty or unpaid order, or similarly, the selected location may be changed while an incomplete order is in the POS view. When the app is again launched, or when a location is changed, an existing empty/unpaid order for that location, if one exists, will be set as the current order in the POS view. This is so that empty and unpaid orders aren't accumulated unecessarily.  

- All orders in POS and KDS views are specific to the selected location; when a location is selected from the Locations list, new and existing orders that appear are specific to that location. This means you can see the state of all `inProcess` and `processed` orders in the KDS for any of the locations. However, it also means that if you are giving a demo for a given location and someone, somewhere else on God's green Earth is giving a demo using that location at the same time, you may be surprised to see orders in the KDS view appearing that you are not entering. And anyone can advance orders in the KDS view simply by tapping once to turn green and again to have them disappear. So you may also be surprised to see them popping out of view.  

- There is no "paid" property in the Order model: "paid" means the order has one or more transactions. Therefore, in the portal data browser, there is no "paid" column. If you want to search for paid orders, use something like ```_id.locationId == '00001' && length(keys(transactionIds)) > 0```.  

## Future  
This README reflects the initial state of the first draft of this demo app. Features and fixes may change the project, and it is hoped that any notable changes will be accompanied by updates to this README.  

- Expected: All orders for all locations are in a single monolithic Orders collection. This is to simulate real world data modeling where a franchise operator will want a single point of access for all orders for all locations. Currently, the Orders collection subscription is `findAll()`, which can be expected to cause performance problems for small peers over time as the orders collection grows potentially very large. Thus an expected update to the app is the implementation of a finer-grained subscription to subscribe to just the orders for the selected location and to update for selection changes. 

- Expected: Since orders will continue to accumulate in the Big Peer over time, local peers will want to evict order data regularly. The expected eviction strategy feature to be implemented is to regularly (maybe in an AppWillBecomeActive callback) evict orders over a day old, and the subscription would need to additionally filter out orders over a day old.  
 
- Expected: There is a known issue with POS grid layout where there is an inconsistent number of columns when rotating and/or adding order items. The KDS grid view implementation seems more stable and may inform a fix for the POS grid view.  


## Project Setup and Run
1. Clone this repo to a location on your machine, and open in Xcode.    
2. Navigate to the project `Signing & Capabilities` tab and modify the `Team and Bundle Identifier` settings to your Apple developer account credentials to provision building to your device.  
3. In your [Ditto portal](https://portal.ditto.live), create an app to generate an App ID and 
playground token.   
4. In Terminal, run `cp .env.template .env` at the Xcode project root directory.   
5. Edit `.env` to add environment variables from the portal as in the following example:   
```DITTO_APP_ID=a01b2c34-5d6e-7fgh-ijkl-8mno9p0q12r3``` 
```DITTO_PLAYGROUND_TOKEN=a01b2c34-5d6e-7fgh-ijkl-8mno9p0q12r3```.  
6. Clean (**Command + Shift + K**), then build (**Command + B**). This will generate `Env.swift`. 
The project is now configured for the portal app.    
