# Aura VoIP — Enterprise SIP Softphone for Android & iOS

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.47%2B-blue?logo=flutter" alt="Flutter Version" />
  <img src="https://img.shields.io/badge/Dart-3.13%2B-0175C2?logo=dart" alt="Dart Version" />
  <img src="https://img.shields.io/badge/Android-SDK%2024%20to%2034%2B-green?logo=android" alt="Android SDK" />
  <img src="https://img.shields.io/badge/iOS-14.0%2B-black?logo=apple" alt="iOS Support" />
  <img src="https://img.shields.io/badge/License-MIT-purple" alt="License" />
</p>

**Aura VoIP** is a high-performance SIP softphone application designed with an **Apple-grade minimalist aesthetic** and built on top of Flutter, WebRTC, and native VoIP telephony protocols. It supports both **Modern WebRTC (WSS/DTLS-SRTP)** and **Standard SIP (UDP/TCP)** backends, with seamless integration for Asterisk, FreePBX, Kamailio, OpenSIPS, and FreeSWITCH.

---

## 🌟 Key Features

### 1. Frictionless Zoiper & PortSIP-Style Login
* **Simple Mode:** Enter Extension/Username, Password, and Domain (e.g., `1001`, `secret`, `pbx.company.com`). The app auto-resolves URIs and transport endpoints.
* **Dual Protocol Toggle:** Switch between **WebRTC Mode** (WSS/WS on port 8089) and **Standard SIP** (UDP/TCP on port 5060).
* **Advanced Settings:** Custom ports, transport selection, STUN/TURN ICE configuration, and keep-alive intervals.
* **Encrypted Credential Storage:** Secured via hardware AES-256 (`flutter_secure_storage`).

### 2. Apple-Grade Minimalist UI & Tactile Dialpad
* **SF Pro Inspired Typography & Layout:** Clean whites, OLED deep graphite dark mode, and frosted glass overlays.
* **Tactile Keypad:** iOS-style circular dialpad with alphanumeric sub-letters (`2 ABC`, `3 DEF`...), instant number formatting, and touch haptics.
* **DTMF Audio Generation:** Authentic touch-tone sound feedback on dialer button presses.
* **Clipboard Integration:** 1-tap paste for international numbers and long-press backspace to clear.

### 3. Apple CallKit In-Call Experience
* Full-screen immersive calling interface with caller avatars, contact names, and live duration counter.
* **6-Button Control Grid:**
  * 🎙️ **Mute / Unmute:** Instant microphone suppression.
  * 🔢 **Keypad Sheet:** Slide-up tactile DTMF dialpad for IVR systems ("Press 1 for Sales...").
  * 🔊 **Speakerphone:** Audio route toggling (Earpiece, Loudspeaker, Bluetooth).
  * ⏸️ **Hold / Resume:** Sends SIP re-INVITE (`sendonly` / `sendrecv`) with PBX Music-on-Hold.
  * ➕ **Add Call / Transfer**
  * 💎 **HD Voice Indicator:** Real-time Opus 48kHz audio indicator.

### 4. Background Incoming Calls & Push Notifications
* **Native Lockscreen Calling:** Integrated with `flutter_callkit_incoming` (Android ConnectionService & iOS CallKit) allowing incoming calls to ring natively when the phone is locked.
* **Android 14+ Telephony Compliance:** Configured with `FOREGROUND_SERVICE_PHONE_CALL`, `USE_FULL_SCREEN_INTENT`, and `POST_NOTIFICATIONS`.

### 5. Persistent SQLite Call History
* Auto-records all calls with timestamps, duration, direction (incoming, outgoing, missed), and caller identity.
* Segmented control (`All` / `Missed`).
* One-tap callback and swipe-left to delete.

### 6. Integrated Wallet & Balance Top-Up
* Apple Card-inspired virtual VoIP credit card showing balance and call rate.
* Quick top-up packages ($10, $25, $50, $100).
* Modal sheet supporting credit/debit card (Stripe) and In-App Purchases.
* Transaction history logs.

---

## 🏗️ Architecture & Project Structure

```
source_code/
├── lib/
│   ├── main.dart                      # App entry point, MultiProvider & theme
│   ├── core/
│   │   ├── theme/
│   │   │   ├── app_colors.dart        # Apple Cupertino Light & Dark palette
│   │   │   ├── app_typography.dart    # Typographic hierarchy
│   │   │   └── app_theme.dart         # Material 3 + Cupertino theme
│   │   └── utils/
│   │       ├── dtmf_tones.dart        # Touch-tone sound generator
│   │       └── haptics.dart           # iOS tactile feedback
│   ├── models/
│   │   ├── sip_account.dart           # Account configuration & URI builder
│   │   ├── call_session_model.dart    # Active session state & duration
│   │   └── call_log_item.dart         # SQLite call history item
│   ├── services/
│   │   ├── sip_service.dart           # Unified SIP stack & WebRTC signaling
│   │   ├── callkit_service.dart       # Lockscreen incoming call manager
│   │   ├── audio_routing_service.dart # Speaker & Earpiece routing
│   │   ├── call_history_service.dart  # SQLite database CRUD operations
│   │   └── secure_storage_service.dart# Hardware keystore encrypted storage
│   ├── providers/
│   │   ├── sip_provider.dart          # Connection, registration, and active call state
│   │   ├── history_provider.dart      # Recents list and filtering
│   │   └── wallet_provider.dart       # Credit balance and top-up transactions
│   └── views/
│       ├── auth/
│       │   └── sip_login_screen.dart  # Zoiper/PortSIP-style login
│       ├── dialpad/
│       │   └── dialpad_screen.dart    # Apple-style dialpad
│       ├── call/
│       │   ├── active_call_screen.dart# Apple CallKit in-call screen
│       │   └── dtmf_sheet.dart        # In-call IVR keypad
│       ├── history/
│       │   └── call_history_screen.dart# Recents logs with swipe actions
│       ├── wallet/
│       │   └── wallet_screen.dart     # Balance card & top-up
│       ├── settings/
│       │   └── settings_screen.dart   # Audio codecs & SIP preferences
│       └── main_navigation_screen.dart# Bottom navigation bar
├── android/                           # Configured permissions & Proguard
└── ios/                               # CallKit & PushKit configurations
```

---

## ⚡ Quick Start

### 1. Clone & Install Dependencies
```bash
git clone https://github.com/tanvirnabil/Flutter-Sip-App.git
cd Flutter-Sip-App/source_code
flutter pub get
```

### 2. Run on Connected Device / Emulator
```bash
flutter run
```

### 3. Build Production APK
```bash
flutter build apk --release
```
The compiled production APK will be placed in `D:\Projects\sip_app\apk\AuraVoIP_v1.0.0.apk`.

---

## 📞 Asterisk & FreePBX Connection Setup

### FreePBX (WebRTC Mode)
1. Go to **Admin** → **User Management** → **UCP** → **WebRTC** → Set **Enable WebRTC Phone** to **Yes**.
2. Go to **Settings** → **Advanced Settings** → Enable **mini-HTTP Server** and **TLS** on port `8089`.
3. In Aura VoIP, enter your Extension, Password, and Domain. Keep **WebRTC Mode** enabled (Port `8089`, Transport `WSS`).

### Asterisk `pjsip.conf` (Standard SIP Mode)
```ini
[1001]
type=endpoint
transport=transport-udp
context=from-internal
disallow=all
allow=opus,ulaw,alaw
aors=1001
auth=1001

[1001]
type=auth
auth_type=userpass
username=1001
password=YourSecretPassword

[1001]
type=aor
max_contacts=5
```
In Aura VoIP, under **Advanced Settings**, disable WebRTC and set Port to `5060`, Transport to `UDP`.

---

## 📄 License
This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.

