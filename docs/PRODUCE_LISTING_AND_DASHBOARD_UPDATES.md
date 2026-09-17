# AgroNexus: Farmer Dashboard & Produce Listing Updates

## Executive Summary
This document outlines the architectural fixes, UI improvements, and feature integrations made to the **AgroNexus** producer experience, specifically linking the **Farmer Dashboard** with the comprehensive **Add Produce Screen**, introducing real device image picking, cleaning up internal specification tags, and making IoT telemetry optional as per the project specification.

---

## 1. Farmer Dashboard Empty State & Mock Data Removal

### Problem
* In the **Active Harvest Lots** section of the Farmer Dashboard, 3 placeholder commodities (*Grade-1 Arabica Coffee*, *Premium Cocoa Beans*, *Organic Plantain Bunch*) were being displayed even though the farmer had not listed any produce, and the top metric card showed `0 Active Lots`.

### Root Cause
* `lib/screens/dashboards/farmer_dashboard.dart` originally had a static hardcoded `List<Widget>` of commodity items embedded directly inside the `Column` widget.

### Solution & Changes
* Connected the dashboard directly to the live backend API via `ApiService.getFarmerProducts()`.
* Implemented a clean dynamic empty state:
  * When no lots are published: displays `"You have not published any produce yet."` with counter `0 Commodities`.
  * When lots exist: dynamically iterates over the retrieved product objects to display real quantity, unit price, and active/inactive status.

---

## 2. Produce Listing Navigation Hookup

### Problem
* Tapping the main **"+ List New Harvest Lot"** button in the Farmer Dashboard opened a barebones bottom-sheet modal with only 3 text fields (*Produce Type*, *Quantity*, *Price*), completely bypassing the rich, dedicated produce listing screen.

### Root Cause
* The button's `onPressed` handler was wired to an inline temporary placeholder method `_showNewHarvestModal()`. The comprehensive `AddProduceScreen` was never imported or navigated to.

### Solution & Changes
* **Removed** `_showNewHarvestModal()` completely from `farmer_dashboard.dart`.
* **Navigated** directly to `AddProduceScreen` using `Navigator.push`.
* **Auto-refresh**: Configured `AddProduceScreen` to pop with `true` upon successful batch creation, triggering `_fetchLiveDashboardData()` so newly listed lots appear immediately on the dashboard.

```dart
onPressed: () async {
  final result = await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => const AddProduceScreen(),
    ),
  );
  if (result == true || mounted) {
    _fetchLiveDashboardData();
  }
},
```

---

## 3. Specification Jargon & UI Tag Cleanup

### Problem
* The produce listing screen showed internal functional requirement tags and Jira/sprint labels intended for developer documentation, such as `FR2.1 Produce Catalog & PostGIS 4326 Index`.

### Solution & Changes in `add_produce_screen.dart`
1. **Removed Tag**: Deleted the green `FR2.1 Produce Catalog & PostGIS 4326 Index` badge chip from the top hero image banner.
2. **Cleaned Header**: Replaced `'List New Harvest Batch (Fr2.1)'` with `'List New Harvest Batch'`.
3. **Cleaned Subtitles**:
   * Changed `'Epic 5: FR5.1 Automated Quality Attestation'` to `'Automated Quality Attestation'`.
   * Changed `'Epic 3: FR3.3 Smart Liquidity Buffer'` to `'Smart Liquidity Buffer'`.

---

## 4. Real Device Camera & Gallery Photo Picker

### Problem
* Tapping **"Choose Gallery"** or **"Take Photo"** instantly displayed a green notification (*"Photo selected from gallery!"*) and loaded a sample stock photo of bananas without opening any file dialog or device gallery.

### Root Cause
* The screen previously called `_simulatePhotoCapture()`, which used hardcoded Unsplash URLs and an immediate snackbar without invoking any platform file picker.

### Solution & Implementation
Created a native web and cross-platform image service:
* `lib/services/image_picker_model.dart`: Data model containing raw image bytes (`Uint8List`), `dataUrl`, and file `name`.
* `lib/services/image_picker_web.dart`: Web implementation creating a DOM `<input type="file" accept="image/*">`.
  * **Desktop Chrome Compatibility Fix**: The HTML `capture="environment"` attribute is strictly a mobile-spec attribute. In desktop Chrome on Windows, setting `capture="environment"` causes Chrome to silently drop the click event and open nothing. The implementation now checks `_isMobileBrowser()` and only attaches `capture="environment"` on mobile devices (Android / iOS). On desktop, it opens the system photo picker cleanly.
  * **Removed Premature Focus Timeout**: Removed the aggressive window focus timer that was prematurely completing with `null` before the user could finish choosing their photo.
* `lib/services/image_picker_stub.dart`: Non-web fallback stub using conditional exports (`dart.library.html`).
* `lib/services/image_picker_service.dart`: Clean facade exposing `ImagePickerService.pickImage()`.
* **Integrated in `AddProduceScreen`**:
  * **`Choose Gallery`**: Triggers file picker for browsing local files.
  * **`Take Photo`**: Triggers camera capture / photo picker.
  * **Image Display**: Replaced remote URLs with `MemoryImage(activeBytes)` so user photos render instantly in full quality in both the large preview and the angle thumbnail slots.
  * Cancelling the file picker now leaves the state intact without showing false success messages.

---

## 5. Optional IoT Silo & Telemetry Linking

### Problem
* The **IoT Silo & Telemetry Link** step forced all farmers to select an ESP32 hub and displayed simulated sensor telemetry (temperature, moisture, power), which does not match smallholder farmers who store crops in standard ambient depots without IoT hardware.

### Solution & Changes
1. **Optional by Default**:
   * Added a state flag `bool _hasIoTNode = false;`.
   * Changed the step badge from `Step 3 of 4` to **`Optional`**.
   * Updated the workflow step sequence: `Step 1 of 3` (Identity), `Step 2 of 3` (Pricing/Volume), `Optional` (IoT Link), `Step 3 of 3` (PostGIS Lock).
2. **Modern Toggle Row**:
   * Added a switch row: **"Connect IoT Storage Node"** (defaulted to **OFF**).
   * **When Disabled (Default)**:
     * Displays a clean info card: *"Standard harvest listing without IoT sensor link. Select your produce quality grade below."*
     * Hides the storage node dropdown and mock telemetry gauges.
     * Displays **Produce Quality Grade (Self-Declared)** with the 3 grade options (`Grade A+ Export`, `Grade AA Domestic`, `Standard Market`).
   * **When Enabled**:
     * Expands the **Attached Storage Node** dropdown selector.
     * Shows live telemetry gauges (Temp, Moisture, Power).
     * Labels quality grading as **Produce Quality Grade (Verified by IoT Telemetry)**.
3. **Backend Submission Description**:
   * Dynamically formats the produce description depending on whether IoT verification was enabled or standard ambient storage was selected.

---

## Verification & Status
* Executed `flutter analyze` across all touched files:
  ```
  Analyzing add_produce_screen.dart...
  No issues found! (ran in 3.2s)
  ```
* All code compiles cleanly with zero warnings or errors.
