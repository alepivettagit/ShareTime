# ShareTime

A collaborative YouTube playlist app built with **Flutter** for both **Android (native APK)** and **Web (PWA)** from a single codebase — designed to run **100% free on the Firebase Spark Plan** (no Cloud Functions, no Cloud Storage, no paid Google Cloud billing required).

> **Note on UI Language:** The application interface is currently written in Italian (`it_IT`).

---

## Features

- **Shared YouTube Playlists:** Create group playlists with friends and share YouTube links directly from the native Android **Share** menu (`Share Intent`) or via the Web app / PWA Share Target.
- **Personal Watch Tracking:** Every member has their own **"To Watch"**, **"Watched"**, and **"Shared / All"** feeds per playlist, with member filter chips. Videos you share yourself are automatically marked as watched for you so your queue only shows friends' recommendations.
- **Zero-Storage Procedural Avatars:** Deterministic 5×5 symmetrical geometric Identicons rendered via `CustomPainter` using an FNV-1a 32-bit hash — instant across Android and Web with zero image uploads.
- **Secure Expiring Invites & Deep Links:** 20-character invite tokens valid for 7 days (`https://<your-project>.web.app/invite/<token>`), supporting Android App Links and Web routing.
- **Spark-Safe Zero-Trust Security:** Client-side `WriteBatch` operations backed by strict [`firestore.rules`](firestore.rules) ensuring users can only write their own profile, username, view status, and authorized playlist actions.
- **Smart Metadata Fetching:** Client-side YouTube Data API v3 integration with automatic oEmbed fallback — metadata is cached once in Firestore when a video is added so friends never consume extra API quota.

---

## Tech Stack

- **Frontend:** Flutter (Dart), Riverpod 3 (`flutter_riverpod`), GoRouter (`go_router`), Material 3 Dark Theme
- **Backend (100% Firebase Spark Free Tier):**
  - Firebase Authentication (Email & Password)
  - Cloud Firestore + [`firestore.rules`](firestore.rules)
  - Firebase Hosting (for Web PWA & `.well-known/assetlinks.json`)

---

## Prerequisites

Make sure you have the following installed on your machine:

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (Dart `>= 3.x`)
- [Git](https://git-scm.com/)
- [Node.js & npm](https://nodejs.org/) (needed for Firebase CLI)
- [Java JDK 17+](https://adoptium.net/) (included with Android Studio, needed for `keytool` and Android builds)
- A free Google account for [Firebase Console](https://console.firebase.google.com/)

Install the CLI tools globally:

```bash
npm install -g firebase-tools
dart pub global activate flutterfire_cli
```

---

## Step-by-Step Self-Hosting & Firebase Setup Guide

Follow these steps to run **ShareTime** with **your own Firebase project**.

### Step 1: Clone the Repository & Install Dependencies

```bash
git clone https://github.com/alepivettagit/ShareTime.git
cd ShareTime
flutter pub get
```

---

### Step 2: Create Your Free Firebase Project (Spark Plan)

1. Go to the [Firebase Console](https://console.firebase.google.com/) and click **Create a project** (or **Add project**).
2. Enter a project name (e.g., `my-sharetime`) and complete creation.
   - Stay on the **Spark (Free)** plan — **do not upgrade to Blaze** and no credit card is needed.
3. **Enable Authentication:**
   - In the left menu, go to **Build → Authentication → Get started**.
   - Under **Sign-in method**, enable **Email/Password** and click **Save**.
4. **Enable Cloud Firestore:**
   - In the left menu, go to **Build → Firestore Database → Create database**.
   - Select **Start in production mode**.
   - Choose your closest Firestore location (e.g., `eur3` for Europe or `nam5` for US) and click **Enable**.

---

### Step 3: Connect Flutter to Your Firebase Project

Authenticate with Firebase and let `flutterfire` generate your personal configuration files (these files are gitignored so your credentials stay private):

```bash
firebase login
flutterfire configure
```

When prompted by `flutterfire configure`:
1. Select the Firebase project you just created.
2. Select platforms: **`android`** and **`web`**.
3. When asked for the Android application ID / package name, keep **`it.sharetime.app`** (or update `applicationId` in [`android/app/build.gradle.kts`](android/app/build.gradle.kts) and `package_name` in `assetlinks.json` if you decide to change it).

This automatically generates:
- `lib/firebase_options.dart`
- `android/app/google-services.json`
- Updates `firebase.json` with your FlutterFire app bindings

Also bind the Firebase CLI in the project folder:

```bash
firebase use --add
```
Select your project and assign the alias `default` (creates `.firebaserc`, also gitignored).

---

### Step 4: Deploy Firestore Security Rules

Deploy the included Zero-Trust [`firestore.rules`](firestore.rules) to your database:

```bash
firebase deploy --only firestore:rules
```

> **What these rules enforce:**
> - Public read on `usernames/{username}` only for uniqueness checks during sign-up; once created, usernames cannot be overwritten or deleted.
> - Playlists and videos are readable/writable only by verified playlist `memberUids`.
> - Personal watch states (`playlists/{id}/videos/{videoId}/views/{userId}`) can only be written by the owner `userId`.
> - Only the playlist creator can delete the playlist or manage invite tokens.

---

### Step 5: Configure YouTube API Keys (Optional, Recommended)

ShareTime fetches video titles, thumbnails, and durations client-side.

1. Copy the template file:
   ```bash
   # macOS / Linux
   cp lib/core/constants/api_keys.dart.example lib/core/constants/api_keys.dart

   # Windows (PowerShell)
   Copy-Item lib\core\constants\api_keys.dart.example lib\core\constants\api_keys.dart
   ```
   *(Creating `lib/core/constants/api_keys.dart` is required for compilation even if you leave the placeholders as-is.)*

2. **Optional — Add YouTube Data API v3 keys (to get exact video durations):**
   - Open [Google Cloud Console](https://console.cloud.google.com/) and select your Firebase project.
   - Go to **APIs & Services → Library**, search for **YouTube Data API v3**, and click **Enable**.
   - Go to **APIs & Services → Credentials → Create Credentials → API key** and create two restricted keys:
     1. **Android key:** Restrict application to *Android apps* (`it.sharetime.app` + your debug/release SHA-1 fingerprints) and restrict API to *YouTube Data API v3*.
     2. **Web key:** Restrict application to *Websites* (`https://<your-project-id>.web.app/*`, `https://<your-project-id>.firebaseapp.com/*`, and `http://localhost/*` for local testing) and restrict API to *YouTube Data API v3*.
   - Paste both keys into `lib/core/constants/api_keys.dart`.
   - *(If you skip adding real keys and leave the `INSERISCI_...` placeholders, ShareTime still fetches titles and thumbnails automatically via YouTube oEmbed without video duration.)*

---

### Step 6: Configure Android Signing, SHA Fingerprints & App Links

1. **Generate a release keystore** (required to build signed release APKs):
   ```bash
   keytool -genkey -v -keystore android/app/upload-keystore.jks -storetype PKCS12 -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```
2. **Create `android/key.properties`** from the template:
   ```bash
   cp android/key.properties.example android/key.properties
   ```
   Fill in your keystore passwords and alias (`android/key.properties` and `*.jks` are gitignored).
3. **Inspect your debug & release SHA-1 / SHA-256 fingerprints:**
   ```bash
   # Release keystore
   keytool -list -v -keystore android/app/upload-keystore.jks -alias upload

   # Debug keystore (default password: android)
   keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
   ```
4. **Register SHA-1 fingerprints in Firebase:**
   - Open **Firebase Console → Project Settings → Your apps → Android app (`it.sharetime.app`)**.
   - Add both your **Debug SHA-1** and **Release SHA-1**.
   - Re-run `flutterfire configure` (or re-download `google-services.json`) if prompted.
5. **Configure Android App Links host:**
   - Open `android/local.properties` (automatically created by Flutter) and append your Firebase Hosting domain:
     ```properties
     sharetime.host=<your-project-id>.web.app
     ```
   - Copy `web/.well-known/assetlinks.json.example` to `web/.well-known/assetlinks.json` and paste your **Release and Debug SHA-256** fingerprints:
     ```bash
     cp web/.well-known/assetlinks.json.example web/.well-known/assetlinks.json
     ```

---

### Step 7: Run Tests, Build & Deploy

#### Run Automated Tests
```bash
flutter analyze
flutter test
```

#### Run Locally
```bash
# Web (Chrome)
flutter run -d chrome

# Android device / emulator
flutter run
```

#### Build & Deploy Web PWA to Firebase Hosting
```bash
flutter build web --wasm
firebase deploy --only hosting
```
Your app will be live at `https://<your-project-id>.web.app` (along with `https://<your-project-id>.web.app/.well-known/assetlinks.json` for Android App Links verification).

#### Build Android Release APK
```bash
flutter build apk --release
```
The signed APK will be generated at:
```text
build/app/outputs/flutter-apk/app-release.apk
```

---

## Project Structure

```text
lib/
├── core/
│   ├── constants/       # API keys template & local constants
│   ├── router/          # GoRouter configuration & auth/invite redirects
│   ├── theme/           # Cyber-Radar dark theme & color palette
│   └── utils/           # FNV-1a 32-bit deterministic hash helper
├── features/
│   ├── auth/            # Email/password login, register, password reset
│   ├── avatar/          # 5x5 procedural Identicon CustomPainter & picker
│   ├── friends/         # Friends list across shared playlists
│   ├── invite/          # Expiring invite link generator & join flow
│   ├── playlists/       # Playlist CRUD, detail tabs & member filter chips
│   ├── profile/         # User profile & avatar customization
│   └── videos/          # YouTube metadata engine, watch state & Share Intent
└── main.dart
```

---

## Troubleshooting

- **Permission denied on username check during sign-up:** Make sure you deployed [`firestore.rules`](firestore.rules) with `firebase deploy --only firestore:rules`.
- **Android invite links open in the browser instead of the app:** Verify that `sharetime.host` in `android/local.properties` matches your Firebase Hosting domain (`<project-id>.web.app`) and that `https://<project-id>.web.app/.well-known/assetlinks.json` is deployed and contains the exact SHA-256 of the keystore used to sign your APK.
- **Blank white page or blocked load on some mobile browsers:** Disable aggressive browser ad-blockers / data-saver compression proxies for your `.web.app` origin, or install the native Android APK for the fastest experience and YouTube Share Intent support.

---

## License

This project is open-source and available under the [MIT License](LICENSE).
