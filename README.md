# DittoPOS

## Overview

A demo Point-of-Sale + Kitchen Display System for a quick service restaurant
chain. Customer orders are entered in the POS view and appear in real time on
the KDS view as they move through the kitchen workflow.

The UI has three tabs:

- **POS** — order entry and payment for the currently selected location.
- **KDS** — orders the kitchen is currently preparing (`inProcess`) or has
  finished (`processed`) for the currently selected location.
- **Locations** — list of demo restaurant locations to switch between.

The app runs on iOS and Android and the two platforms sync with each other
over Ditto.

For support, please contact Ditto Support (<support@ditto.com>).

## Running the apps

See the README in the `iOS` or `Android` folders for build instructions.

App Store builds:
[iOS](https://apps.apple.com/us/app/ditto-pos/id6449074700) ·
[Google Play](https://play.google.com/store/apps/details?id=live.ditto.pos)

## Data model

The demo follows current Ditto guidance for denormalized documents and
read-time conflict resolution. The whole order — cart, payments, status
history — lives in a single `pos_orders` document, which avoids cross-document
joins and lets Ditto's map-merge semantics resolve concurrent edits cleanly.

Collections:

- **`pos_orders`** — one document per order. Embedded fields:
  - `cart: Map<String, CartLineItem>` — line items keyed by a stable
    line-item id so adds and removes from different devices don't conflict.
  - `payments: Map<String, Payment>` — payments keyed by payment id.
  - `status_log: Map<String, String>` — ISO 8601 timestamp → status string.
    The "current" status is *derived* at read time using "most-advanced state
    wins" (`open` → `inProcess` → `processed` → `delivered`, with `canceled`
    as terminal). A stale device that comes online late and writes an older
    state cannot regress the order — the older entry stays in the log for
    auditability but the read-time derivation ignores it. See the
    [conflict-resolution-patterns guide](https://docs.ditto.live/best-practices/conflict-resolution-patterns).
  - `createdAt: ISO 8601 string` — used for the per-location TTL subscription
    and launch-time eviction.

- **`sale_items`** — synced menu items, one document per item per location.
  Hand-curated demo data is seeded once on first launch via
  `INSERT INTO ... INITIAL DOCUMENTS (...)` (idempotent, peer-safe).

- **`locations`** — one document per location.

Documents in `pos_orders` and `sale_items` use a composite `_id` of
`{ id, locationId }`. Putting `locationId` inside `_id` lets Ditto use it as
the document's natural key for sync grouping/routing, and lets DQL filter by
`_id.locationId` without a secondary index. See the
`DocumentID` type in either platform's source.

### Schema migration

This PR introduces the v2 schema in a new `pos_orders` collection (Pattern 2
from the Ditto schema-versioning guide). The old `orders` / `transactions`
schema is left in place but no longer read or written; the major version is
bumped from `1.0.0` to `2.0.0` so old + old peers and new + new peers each
operate independently.

## App features

### Location selection

The app starts in demo-locations mode with seven hand-curated restaurants.
You can also switch to a single user-defined location via Settings → Advanced.

### Order workflow

A new order is created when you select a location or pay an existing one,
starting with status `open`. Adding the first item moves it to `inProcess`
and it becomes visible in the KDS view across the mesh.

In KDS, tap an `inProcess` (blue) order to advance it to `processed` (green).
Tap a `processed` order to mark it `delivered`, which removes it from the
view. A double-dollar-sign on the order border indicates payment.

Because the KDS view shows every device's orders for the current location,
multiple peers running the same demo concurrently will each see the others'
orders. Order status changes by tap from any device.

### "Paid" check

The order document has no `paid` field — an order is paid when its `payments`
map has at least one entry. To find paid orders in the portal data browser:

```
_id.locationId == '00001' && length(keys(payments)) > 0
```

### Time-based eviction

On launch, gated to once per 24h, the app evicts local orders older than the
start of the current day. Subscriptions filter the same way, so the local
store stays bounded over time.

## Scripts

Scripts in `scripts/` exercise insert/observer paths for metric testing. Each
script's header documents its purpose and inputs.

To run a script you'll need:

1. A [Cloud URL endpoint](https://docs.ditto.live/cloud/http-api/getting-started#cloud-url-endpoint).
2. An [HTTP API key](https://docs.ditto.live/cloud/http-api/auth-and-params#api-key).

Available:

- `INSERT_Orders` — inserts generic orders on a configurable interval.
