# Food artwork

Original food illustrations supplied by Brian Plattenburg for Ditto's existing
20-item demo menu. The original `food.zip` and source manifest are retained in
COMMERC-148. No menu names, prices, IDs or location assignments change here.

`manifest.json` maps stable catalog item IDs to the original source hashes and
each platform's existing native resource. Source filenames describe the artwork;
for example, `chicken-sandwich.png` remains the menu's **Burger**.

Packaged copies use the same PNG bytes on both platforms, downsampled to 384 × 384
with macOS `sips -Z 384`. They preserve transparency and are each below 200 KiB.
The original 1000 × 1000 sources are unchanged. Manifest hashes describe the
checked-in PNG files, before native resource compilation.

These replace the existing bundled artwork. The attachment migration consumes
these new images by stable item ID; it must not choose a file from a document's
legacy `imageName` value. After that cutover, product UI uses attachments or the
generic placeholder, and bundled food is initialization/migration input only.
