# Connecting SubCheck to real Firebase (optional)

SubCheck works fully without this. Do it only if you want the cloud backup to use a real Firebase project
(Part I of the proposal: Firebase for authentication, cloud storage and synchronization).

> Note: this guide and `RealFirebaseClient` were written against the `FirebaseClient` interface in
> `lib/cloud_sync/firebase_client.dart`, but they have **not been run against a live Firebase project**.
> Firebase setup differs a little between versions, so if a step looks different on your screen, the
> official FlutterFire guide (https://firebase.flutter.dev/docs/overview) is the reference.
> Test on an **Android emulator or phone**.

## 1. Create the Firebase project

1. Go to https://console.firebase.google.com and sign in with your Google account.
2. **Add project**, name it `subcheck`, and continue (Google Analytics can be turned off).
3. In the left menu open **Build > Authentication > Get started > Sign-in method**, enable
   **Email/Password**, and save.
4. Open **Build > Firestore Database > Create database**. Choose a location near you and start in
   **production mode**.
5. In Firestore open the **Rules** tab and replace everything with the text below, then **Publish**.
   It lets each signed-in user read and write **only their own** backup.

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

## 2. Link the project to the app

In the VS Code terminal, in `C:\subcheck`:

```
flutter pub add firebase_core firebase_auth cloud_firestore
dart pub global activate flutterfire_cli
flutterfire configure
```

* `flutterfire configure` needs the Firebase CLI. If it asks, install it from
  https://firebase.google.com/docs/cli#windows (or `npm install -g firebase-tools`), run `firebase login`,
  then run `flutterfire configure` again.
* Choose your `subcheck` project and tick **android** (and ios if you have a Mac).
* It creates `lib/firebase_options.dart`.
* If Android says the minimum SDK is too low, open `android\app\build.gradle.kts` and set `minSdk = 23`
  (Groovy: `minSdkVersion 23`).

## 3. Add the real client

Create `lib/cloud_sync/real_firebase_client.dart` and paste:

```dart
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'backup_data.dart';
import 'firebase_client.dart';
import 'user_account.dart';

/// LLD class: FirebaseClient, implemented with the real Firebase cloud.
/// Each user's backup is ONE document: users/{uid}  ->  { backup: "<json text>" }
class RealFirebaseClient implements FirebaseClient {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? _lastError;
  UserAccount? _account;

  @override
  String? get lastError => _lastError;

  @override
  UserAccount? get account => _account;

  @override
  Future<bool> signUp(String name, String email, String password) async {
    _lastError = null;
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
          email: email.trim(), password: password);
      final user = cred.user!;
      await user.updateDisplayName(name.trim());
      _account = UserAccount(
          uid: user.uid, fullName: name.trim(), email: user.email ?? email.trim());
      return true;
    } on FirebaseAuthException catch (e) {
      _lastError = _friendly(e);
      return false;
    } catch (_) {
      _lastError = 'Could not reach the cloud. Check your internet connection.';
      return false;
    }
  }

  @override
  Future<bool> signIn(String email, String password) async {
    _lastError = null;
    try {
      final cred = await _auth.signInWithEmailAndPassword(
          email: email.trim(), password: password);
      final user = cred.user!;
      _account = UserAccount(
          uid: user.uid,
          fullName: user.displayName ?? email.trim().split('@').first,
          email: user.email ?? email.trim());
      return true;
    } on FirebaseAuthException catch (e) {
      _lastError = _friendly(e);
      return false;
    } catch (_) {
      _lastError = 'Could not reach the cloud. Check your internet connection.';
      return false;
    }
  }

  @override
  Future<void> signOut() async {
    await _auth.signOut();
    _account = null;
  }

  @override
  Future<bool> uploadData(String userId, BackupData data) async {
    _lastError = null;
    try {
      await _firestore.collection('users').doc(userId).set({
        'backup': jsonEncode(data.toJson()),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (_) {
      _lastError = 'Backup failed. Check your internet connection and try again.';
      return false;
    }
  }

  @override
  Future<BackupData?> downloadData(String userId) async {
    _lastError = null;
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) return null; // no backup yet
      final text = doc.data()?['backup'] as String?;
      if (text == null) return null;
      return BackupData.fromJson(jsonDecode(text) as Map<String, dynamic>);
    } catch (_) {
      _lastError = 'Restore failed. Check your internet connection and try again.';
      return null;
    }
  }

  String _friendly(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'An account with this email already exists.';
      case 'invalid-email':
        return 'That email address is not valid.';
      case 'weak-password':
        return 'Choose a stronger password (at least 6 characters).';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'network-request-failed':
        return 'No internet connection.';
      default:
        return e.message ?? 'Something went wrong. Please try again.';
    }
  }
}
```

## 4. Switch the app over (two small edits)

**`lib/main.dart`**: start Firebase before the container is built.

```dart
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
// ... keep the other imports ...

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform); // <-- add
  final container = await AppContainer.create();
  runApp(SubCheckApp(container: container));
}
```

**`lib/app_container.dart`**: replace the one `MockFirebaseClient` line (and add the import at the top).

```dart
import 'cloud_sync/real_firebase_client.dart';          // <-- add at the top

// ...
final FirebaseClient firebaseClient = RealFirebaseClient();   // <-- was MockFirebaseClient(database)
```

You can delete the `mock_firebase_client.dart` import if the editor marks it as unused.

## 5. Try it

Run on an Android emulator or phone with internet. In **Settings > Create Account**, register, add a
subscription, go to **Data & Sync > Back up now**, then check the **Firestore Database** tab in the Firebase
console: you should see `users/<uid>` with a `backup` field. Delete the app's data (or reinstall), log in,
and use **Restore from backup** to bring everything back.

## Notes

* Only the user's own data is stored, and no card or bank details are ever collected.
* Backup and restore need internet. If it is missing, the app shows an error message and every offline
  feature keeps working.
* Firebase Authentication already hashes passwords; unlike the demo client, the app never stores them.
