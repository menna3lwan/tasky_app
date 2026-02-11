# Firebase Setup Guide for Tasky App

## Prerequisites
- Flutter SDK installed
- Firebase account
- Node.js installed (for Firebase CLI)

---

## Step 1: Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click **"Create a project"**
3. Enter project name: `tasky-app`
4. Enable/Disable Google Analytics (optional)
5. Click **"Create project"**

---

## Step 2: Install Firebase CLI

```bash
# Install Firebase CLI globally
npm install -g firebase-tools

# Login to Firebase
firebase login
```

---

## Step 3: Install FlutterFire CLI

```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli
```

---

## Step 4: Configure Firebase in Flutter Project

```bash
# Navigate to your project directory
cd tasky_app

# Run FlutterFire configure
flutterfire configure
```

This will:
- Create `firebase_options.dart` file
- Register your app with Firebase
- Download configuration files

---

## Step 5: Add Firebase Dependencies

Add these to `pubspec.yaml`:

```yaml
dependencies:
  firebase_core: ^3.8.1
  firebase_auth: ^5.7.0
  cloud_firestore: ^5.6.5
```

Then run:
```bash
flutter pub get
```

---

## Step 6: Initialize Firebase in main.dart

```dart
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const TaskyApp());
}
```

---

## Step 7: Enable Firebase Authentication

1. Go to Firebase Console → Your Project
2. Click **"Authentication"** in the left menu
3. Click **"Get started"**
4. Go to **"Sign-in method"** tab
5. Enable **"Email/Password"**
6. Click **"Save"**

---

## Step 8: Create Firestore Database

1. Go to Firebase Console → Your Project
2. Click **"Firestore Database"** in the left menu
3. Click **"Create database"**
4. Choose **"Start in test mode"** (for development)
5. Select a location closest to you
6. Click **"Enable"**

---

## Step 9: Set Firestore Security Rules

Go to Firestore → Rules tab and add:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can only access their own data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;

      // Tasks subcollection
      match /tasks/{taskId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
    }
  }
}
```

Click **"Publish"**

---

## Step 10: Android Configuration

### Update `android/build.gradle`:

```gradle
buildscript {
    dependencies {
        classpath 'com.google.gms:google-services:4.4.0'
    }
}
```

### Update `android/app/build.gradle`:

```gradle
plugins {
    id 'com.google.gms.google-services'
}

android {
    defaultConfig {
        minSdkVersion 21
    }
}
```

### Ensure `google-services.json` is in `android/app/`

---

## Firestore Data Structure

```
users/
  └── {userId}/
        └── tasks/
              └── {taskId}/
                    ├── title: string
                    ├── description: string (optional)
                    ├── dateTime: timestamp
                    ├── priority: number (1-10)
                    └── isCompleted: boolean
```

---

## Features Implemented

### Authentication
- ✅ Email/Password Login
- ✅ Email/Password Registration
- ✅ Logout
- ✅ Auto-login (session persistence)
- ✅ Error handling with user-friendly messages

### Firestore CRUD Operations
- ✅ **Create**: Add new task
- ✅ **Read**: Real-time task updates with StreamBuilder
- ✅ **Update**: Edit task fields, toggle completion
- ✅ **Delete**: Remove task with confirmation

### Task Features
- ✅ Title & Description
- ✅ Date Picker (showDatePicker)
- ✅ Time Picker (showTimePicker)
- ✅ Priority (1-10)
- ✅ Mark as completed/uncompleted

### Home Screen Filters
- ✅ All tasks
- ✅ Today's tasks
- ✅ Upcoming tasks
- ✅ Completed tasks

---

## Troubleshooting

### Error: "No Firebase App"
Make sure `Firebase.initializeApp()` is called before `runApp()`

### Error: "Permission Denied"
Check Firestore security rules and ensure user is authenticated

### Error: "google-services.json not found"
Run `flutterfire configure` again or manually download from Firebase Console

### Build Errors on Android
- Ensure `minSdkVersion` is at least 21
- Run `flutter clean && flutter pub get`

---

## Useful Commands

```bash
# Clean and rebuild
flutter clean
flutter pub get
flutter run

# Analyze code
flutter analyze

# Build APK
flutter build apk --release
```

---

## Resources

- [Firebase Documentation](https://firebase.google.com/docs)
- [FlutterFire Documentation](https://firebase.flutter.dev/)
- [Firestore Data Modeling](https://firebase.google.com/docs/firestore/data-model)
