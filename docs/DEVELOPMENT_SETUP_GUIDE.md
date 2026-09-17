# AgroNexus Local Development & Setup Guide

This guide covers local environment configuration, mobile device testing setup, Flutter dependency management, and Gradle build troubleshooting for the **AgroNexus** platform.

---

## 📱 1. Flutter Hardware & Biometric Setup

To enable physical device GPS positioning and biometric verification (live face scan / fingerprint authentication), the Flutter app requires two core hardware packages:

- **`geolocator`**: Provides access to the device's physical GPS hardware for radial produce search.
- **`local_auth`**: Triggers native device biometric authentication for security verification.

### Installation

Run the following command inside the `frontend/` directory:

```bash
flutter pub add geolocator local_auth
```

---

## 📦 2. State Management Dependencies

AgroNexus uses the **Provider** package for app-wide reactive state management (managing authentication tokens, active orders, telemetry updates, and cart items).

### Installation

Add `provider` to `frontend/pubspec.yaml` under `dependencies`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  http: ^1.2.0
  provider: ^6.1.2
```

Then run:

```bash
flutter pub get
```

---

## 🌐 3. Mobile Device Network & IP Configuration

When testing the mobile client on a physical phone (e.g., Android/iOS over local Wi-Fi):

1. **Connect Devices**: Ensure both your development computer and mobile device are connected to the **same Wi-Fi network**.
2. **Find Host IP Address**:
   - Open Command Prompt or PowerShell on Windows and run:
     ```cmd
     ipconfig
     ```
   - Note down your computer's local **IPv4 Address** (e.g., `192.168.1.50`).
3. **Update API Endpoint**:
   - Open [`frontend/lib/services/api_service.dart`](file:///c:/Users/lenovo%20p14s/Music/AGRONEXUS/frontend/lib/services/api_service.dart).
   - Update the base URL pointing to your local Spring Boot backend:
     ```dart
     static const String baseUrl = 'http://192.168.X.X:8080/api/v1';
     ```

> [!NOTE]
> Whenever you switch Wi-Fi networks (e.g., moving between home and university), your router assigns a new local IP address. Re-check `ipconfig` and update `baseUrl` accordingly.

---

## 🛠️ 4. Gradle Build & Offline Dependency Fixes

If `flutter run` or `./gradlew assembleDebug` fails due to socket timeouts or dropped connections during Gradle dependency downloads, manually cache the required Kotlin plugin `.jar` files.

### Step 1: Download Required Libraries

1. **`kotlin-gradle-plugin-2.0.20-gradle85.jar`** (~14.2 MB):
   - Link: [Maven Repository](https://repo.maven.apache.org/maven2/org/jetbrains/kotlin/kotlin-gradle-plugin/2.0.20/kotlin-gradle-plugin-2.0.20-gradle85.jar)
2. **`kotlin-compiler-embeddable-2.0.20.jar`** (~55.5 MB):
   - Link: [Maven Repository](https://repo.maven.apache.org/maven2/org/jetbrains/kotlin/kotlin-compiler-embeddable/2.0.20/kotlin-compiler-embeddable-2.0.20.jar)

### Step 2: Place in Gradle Cache

Move the downloaded `.jar` files to Gradle's local module cache:

```
C:\Users\<YOUR_USERNAME>\.gradle\caches\modules-2\files-2.1\org.jetbrains.kotlin\
```

After copying, rebuild the project:

```bash
cd android
./gradlew assembleDebug --offline
```
