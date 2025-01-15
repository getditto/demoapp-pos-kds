# DittoPOS  

## Overview  
This project is to demo very basic features of a POS (Point of Sale) system using Ditto, modeled on a fast food location operation, 
where customer orders can be input and are displayed in real time on a kitchen display that represents the order fulfillment workflow.  

The UI is presented as tabs with three main sections:
- Order input view (POS) to handle input of customer orders of menu items and simple payment function 
- Kitchen Display System view (KDS) to displays all orders for the selected location with a status of `inProcess` - meaning menu items 
are in process of being prepared, and `processed` - meaning prepared and ready for delivery.  
- Locations list (when in "demo locations mode") from which to select a location (restaurant).

The app works on both iOS and Android and can sync between iOS and Android devices as well. 

For support, please contact Ditto Support (<support@ditto.live>).

## Running the Apps
Please see the README in either the `iOS` or `Android` folders for instructions on running for either platform.

## App Features and Notes

### Default Demo Locations or User-defined Location  
The app can be switched from Demo locations mode (a premade list of locations) or user-defined locations mode.    

With user-defined location feature enabled, the Profile screen is displayed at first launch, requiring the user to create a location with 
company name and location name, which together become the location ID. This location ID is persisted locally and this location is 
used exclusively until the app is uninstalled from the device. This feature may be more suitable for a more public demo, e.g., where the 
app is available for installation and operation by potential clients. This feature hides the Locations tab view.    

With default demo locations feature enabled, the Locations tab view is displayed and it is the landing view at the app's first launch. 
The user must select a location from the demo locations list in the tab view before being able to enter orders. In contrast to  
user-defined location mode, the user can switch between locations at any time by selecting a location in the Locations tab view, which 
allows viewing orders in progress in the KDS tab view for the currently selected location. For every Location selection, the location ID 
is persisted locally and is restored on subsequent app launches until changed. This feature may be more suitable for sales  
presentation demos to demonstrate monitoring in-process orders across multiple locations, and where the Big Peer may be demonstrated 
updating order sale items in real time.  

### Demo Operations and Functionality  
Selection of a location is required to begin entering orders; on first launch, the landing view defaults to the Locations list. Enter 
order items in the POS tab view by tapping menu items. The item and its price appears in a list in the POS order view, with a total 
order cost and Pay and Cancel buttons beneath. Tap the Pay button to complete order entry and refresh the view with a new order, or tap 
the Cancel button to remove existing items.  

A new order is created whenever a location is selected or an existing order is paid, and is set with status `open`. For every item added 
to the order, the order status is updated to `inProcess`. This is to demo a feature that the kitchen (KDS view) diplays orders in 
progress in real time so that they may be "in process" of being fulfilled even before order entry is complete. Every connected device 
running the app may individually create orders using the POS view.    

The KDS view displays `inProcess` and `processed` orders to demonstrate the flow of the order through this simplified restaurant 
fulfillment chain. An `inProcess` order is displayed in the KDS view as soon as the first order item is added. When the order is 
paid (in POS view), a double dollar sign will appear on the bottom border of that KDS order view, which indicates order entry is complete. 
Tap once on the blue `inProcess` order to update its status to `processed`, which changes to green. This demonstrates that the order has 
flowed to the next step in the fulfillment workflow to "ready for delivery". It might be that a location has a kitchen team preparing 
orders and a delivery team delivering orders. A kitchen team member would tap the order when finished preparing it, alerting delivery team 
members of its readiness for packaging and delivery to the customer. A tap on a green order advances its status to `delivered`, at which 
point it disappears from KDS view, signifying that the order has been completely fulfilled.  


### Notes 
- It is possible to be entering an order in the POS view, and while also appearing in the KDS view for the status of the order to be 
advanced (by way of two taps) to `delivered` and therefore no longer displayed in the KDS view. Because the KDS view displays orders as 
they are entered from any device on the mesh, and because this demo does not prevent orders from being advanced/fulfilled without being 
paid, it is possible to advance an order out of view before it is completed/paid. However, if another item is added to the order, the 
status will once again become `inProcess` and it will again appear in the KDS view. However, if the order (at this point only visible in 
the POS view) is paid by tapping the Pay button, the POS view will refresh with a new empty order. Though invisible in the app, the order 
will represent a fulfilled, paid order, and this can be viewed in the portal data browser.

- All orders in POS and KDS views are specific to the selected location; when a location is selected from the Locations list, new and 
existing orders that appear are specific to that location. This means you can see the state of all `inProcess` and `processed` orders in the 
KDS for any of the locations. However, it also means that if you are giving a demo for a given location and someone, somewhere else on God's 
green Earth is giving a demo using that location at the same time, you may be surprised to see orders in the KDS view appearing that you are 
not entering. And anyone can advance orders in the KDS view simply by tapping once to turn green and again to have them disappear. So you may 
also be surprised to see them popping out of view.  

- There is no "paid" property in the Order model: "paid" means the order has one or more transactions. Therefore, in the portal data browser, 
there is no "paid" column. If you want to search for paid orders, use something like ```_id.locationId == '00001' && length(keys(transactionIds)) > 0```.  


## Scripts
Scripts are provided as way to perform various metric testing. Within each script are the instructions on how to use it as well as the purpose of each one.

For each script you will need to:
1. Setup your own Cloud URL Endpoint. See [Cloud URL Endpoint](https://docs.ditto.live/cloud/http-api/getting-started#RBdx2) for more info.
2. Setup your own auth token. See [HTTP API - Authorization](https://docs.ditto.live/cloud/http-api/getting-started#RBdx2) for more info.

### Available Scripts:
1. INSERT_Orders - Used to Insert generic orders on an interval.
