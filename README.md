# SubCheck: A Subscription Tracking and Review Mobile Application

Flutter / Dart source code for the SubCheck midterm project (BSCS 3A). The code follows the
**High-Level Design** (Figure 1) and **Low-Level Design** (Figure 2): every box and class in those
figures has a folder or a file here with the same name.

This zip contains only the code: `lib/`, `test/`, `pubspec.yaml` and these guides.
It does **not** contain the `android/` and `ios/` folders, because Flutter creates those for you
(you already have them in `C:\subcheck`).

---

## PART 1. Run it in VS Code (Windows)

### Step 0. Check that Flutter works in the terminal

Open VS Code, then **Terminal > New Terminal**, and type:

```
flutter --version
```

* If it prints a version, go to Step 1.
* If it says `flutter is not recognized`, Flutter is not on your PATH:
  1. Find the folder where you extracted Flutter (for example `C:\src\flutter`). It contains a `bin` folder.
  2. Press the Windows key, search **Edit the system environment variables**, click **Environment Variables**.
  3. Under *User variables*, select **Path**, click **Edit > New**, and add `C:\src\flutter\bin` (use your own folder).
  4. Click OK on every window. **Close VS Code completely and open it again.**
  5. Run `flutter --version` again.
* If Flutter is not installed at all, follow https://docs.flutter.dev/get-started/install/windows
  and install **Android Studio** too (it provides the Android emulator).

Then run `flutter doctor` and fix anything marked with a red X for **Android toolchain**.
(Visual Studio, Chrome and Xcode warnings can be ignored for phone testing.)

### Step 1. Put the code into your project (`C:\subcheck`)

Your project already has `android/`, `ios/` and a default `lib/main.dart`. Do this **in this order**:

1. **Delete the whole old `lib` folder** in `C:\subcheck`. This matters: an older version of SubCheck
   used a different folder layout, and leftover old files will show red errors.
2. **Delete the old `test` folder** (it holds the default `widget_test.dart`, which refers to the
   demo app and will fail).
3. If you see a second `subcheck` folder *inside* `lib` or inside the project, delete it.
4. Unzip this download and copy these three things into `C:\subcheck`:
   * the `lib` folder
   * the `test` folder
   * `pubspec.yaml` (replace the existing one)
5. (Optional) copy `README.md` and `FIREBASE_SETUP.md` too.

Your folder should now look like this:

```
C:\subcheck
├── android\            (already there)
├── ios\                (already there)
├── lib\
│   ├── main.dart
│   ├── app.dart
│   ├── app_container.dart
│   ├── theme.dart
│   ├── presentation\ ...
│   └── ... (see the code map below)
├── test\logic_test.dart
└── pubspec.yaml
```

### Step 2. Download the packages

In the VS Code terminal (make sure the path shown is `C:\subcheck`):

```
flutter pub get
```

If it complains about the Dart/Flutter version, run `flutter upgrade` and try again.

### Step 3. Android setup (needed for reminders / notifications)

Skip this step only if you will test on Windows or Chrome (reminders do nothing there).

**3a. Permissions and receivers.** Open `android\app\src\main\AndroidManifest.xml`.

Inside `<manifest ...>` and **above** the `<application` line add:

```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
<uses-permission android:name="android.permission.VIBRATE"/>
```

Inside `<application ...>` (anywhere between its opening and closing tags, e.g. just before
`</application>`) add:

```xml
<receiver android:exported="false"
    android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver" />
<receiver android:exported="false"
    android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver">
    <intent-filter>
        <action android:name="android.intent.action.BOOT_COMPLETED"/>
        <action android:name="android.intent.action.MY_PACKAGE_REPLACED"/>
        <action android:name="android.intent.action.QUICKBOOT_POWERON" />
        <action android:name="com.htc.intent.action.QUICKBOOT_POWERON"/>
    </intent-filter>
</receiver>
```

**3b. Desugaring.** The notification package needs this. Open `android\app\build.gradle.kts`
(or `build.gradle` on older projects).

If the file is `build.gradle.kts` (Kotlin):

```kotlin
android {
    // ... keep what is already there ...
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true      // <-- add this line
    }
}

// Add this block at the very bottom of the file (create it if there is none):
dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
```

If the file is `build.gradle` (Groovy):

```groovy
android {
    compileOptions {
        sourceCompatibility JavaVersion.VERSION_11
        targetCompatibility JavaVersion.VERSION_11
        coreLibraryDesugaringEnabled true          // <-- add this line
    }
}

dependencies {
    coreLibraryDesugaring 'com.android.tools:desugar_jdk_libs:2.1.4'
}
```

If you already have `sourceCompatibility` lines with another Java version, keep yours and only add
the desugaring line.

**3c. iOS only (needs a Mac).** In `ios/Runner/Info.plist` add:

```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>SubCheck uses your photos so you can choose a logo for a subscription.</string>
```

### Step 4. Choose where to run it

Look at the bottom-right corner of VS Code. It says **No Device**; click it and pick one:

| Option | How | Notes |
|---|---|---|
| **Android emulator** (recommended) | Install Android Studio, then in VS Code press `Ctrl+Shift+P`, type **Flutter: Launch Emulator** | Everything works, including reminders. |
| **Real Android phone** | Turn on *Developer options* and *USB debugging*, plug it in, accept the prompt on the phone | Everything works. |
| Windows (desktop) | Pick **Windows (windows-x64)** | Needs the *Desktop development with C++* workload in Visual Studio and *Developer Mode* (Settings > System > For developers). Reminders do nothing here. |
| Chrome | Pick **Chrome** | Runs, but logos do not show and there are no reminders. Fine for a quick look only. |

Then press **F5** (or run `flutter run` in the terminal). The first build takes several minutes.

### Step 5. Run the automated tests (optional)

```
flutter test
```

`test/logic_test.dart` checks the money rules (your share of a shared subscription, monthly cost per
billing cycle) and the review rule (renewal within 7 days).

### Step 6. A quick tour to check that it all works

1. The app opens straight to **Home** (no login). It shows `₱0` and "No subscriptions yet".
2. Tap the lime **+** button. Fill in: name `Netflix`, category, price `549`, billing cycle `Monthly`,
   next payment date **3 days from today**. Choose **Yes** for shared, `3` people. You should see
   "Your share: ₱183.00". Tap **Save subscription**.
3. The **Confirmation** screen appears. Tap **View Subscription** to see the **Details** screen
   (Edit and Remove are there).
4. Back on **Home**: the purple card now shows ₱183 / month, Netflix is under *Upcoming payments*, and a
   cream banner says **1 subscription needs review**. Tap it.
5. On **Review**, tap Netflix and try **Review later** (only days *before* the payment are selectable),
   then **Keep**, or **Cancel and stop tracking**.
6. Open the **Calendar** tab: the payment day is lime (upcoming). Use the arrows to change month.
7. Open **Settings**: change **Appearance** to Dark; try **Create Account**, then **Data & Sync** >
   **Back up now** / **Restore** (these use the built-in demo cloud; see Part 3).
8. Close the app completely and reopen it. Your data is still there (saved on the phone).

### Troubleshooting

| Message | Fix |
|---|---|
| `flutter is not recognized` | Step 0 (PATH), then restart VS Code. |
| Red errors such as `Target of URI doesn't exist` | Run `flutter pub get`. Make sure you deleted the old `lib` folder first. |
| Errors in `test/widget_test.dart` mentioning `MyApp` | Delete that file (Step 1, point 2). |
| Gradle error about *desugaring* or `isCoreLibraryDesugaringEnabled` | Step 3b. |
| Gradle error about Java or `compileSdk` version | Run `flutter upgrade`, then `flutter clean`, then run again. |
| *Building with plugins requires symlink support* (Windows) | Turn on Developer Mode in Windows settings. |
| Notification never appears | Use the emulator/phone, allow the permission popup, do Step 3a, and remember the reminders fire at **9:00 AM** on the day. |
| `flutter pub get` says version solving failed | Run `flutter upgrade` (the packages need a recent Flutter). |

---

## PART 2. How the code is organized

### The big picture

The folders match the High-Level Design. A tap travels **down** the layers, and the answer comes back **up**:

```
Screen (presentation/screens)
   -> Controller (presentation/controllers)        "Presentation Module"
      -> Service (subscription_management / review_management)
         -> Repository (data_access)               "Data Access Module"
            -> LocalDatabase                       "Local Database" (on the phone)
Notifications (notification/) are triggered by the services.
Cloud sync (cloud_sync/) is optional and only used from Settings.
```

**How the pieces get connected:** `app_container.dart` creates every object once, from the bottom up, and
gives each class the classes it needs through its constructor. That is what the "uses" attributes in
the LLD mean. `main.dart` calls `AppContainer.create()`, then `runApp(...)`.

**How screens refresh:** after every add / edit / review / delete, a controller calls
`refresh.notifyChanged()` (class `DataRefresh`). Screens listen to it and redraw, so the dashboard total,
the review banner and the calendar update immediately.

### Code map (what every file does)

**Start-up**

| File | Purpose |
|---|---|
| `main.dart` | Entry point. Builds the container (loads saved data), then starts the app. |
| `app.dart` | Root widget. Provides the controllers to all screens (Provider), sets light/dark theme, asks for notification permission, and records passed payment dates when the app is reopened. |
| `app_container.dart` | Creates and connects all objects, following the HLD. Also runs start-up tasks. |
| `theme.dart` | The Figma colours (purple, lime, red, green, cream) and light/dark themes. |
| `utils/helpers.dart` | Small helpers: UUID maker, date-only, add days, days between, add one billing cycle, peso formatting. |

**Presentation Module** (`presentation/`)

| File | Purpose |
|---|---|
| `controllers/subscription_controller.dart` | LLD `SubscriptionController`: add / edit / delete / list subscriptions and the dashboard summary. |
| `controllers/review_controller.dart` | LLD `ReviewController`: review list, Keep, Review later, Stop tracking. |
| `controllers/calendar_controller.dart` | LLD `CalendarController`: entries for one month. |
| `controllers/settings_controller.dart` | LLD `SettingsController`: account, backup, restore, plus the notification switch and appearance. |
| `data_refresh.dart` | The "something changed" signal described above. |
| `screens/home_shell.dart` | The frame with the bottom bar (Home, Calendar, **+**, Review, Settings). |
| `screens/home_screen.dart` | Figure 1, Home Dashboard. |
| `screens/add_subscription_screen.dart` | Figure 2, Add Subscription (also used for editing). |
| `screens/confirmation_screen.dart` | Figure 3, Confirmation. |
| `screens/review_screen.dart` | Figure 4, subscriptions waiting for review. |
| `screens/subscription_review_screen.dart` | Figures 5 and 6, Keep / Review later (with the "Remind me again in..." sheet) / Stop tracking. |
| `screens/subscription_details_screen.dart` | Figure 7, Details with Edit and Remove. |
| `screens/calendar_screen.dart` | Figure 8, Calendar (green paid, lime upcoming, red missed review). |
| `screens/settings_screen.dart` | Figure 9, Settings, plus the Notifications and Data & Sync pages. |
| `screens/auth_screens.dart` | Figures 10 and 11, Create Account and Log In. |
| `widgets/common.dart` | Reusable pieces: logo box, list row, dropdown, share display. |

**Subscription Management Module** (`subscription_management/`)

| File | Purpose |
|---|---|
| `subscription_service.dart` | LLD `SubscriptionService`: validate, add, update, delete subscriptions (and schedule reminders). |
| `cost_calculator.dart` | LLD `CostCalculator`: your share (`price / people`), monthly cost per billing cycle, total monthly spending. |

**Review Management Module** (`review_management/`)

| File | Purpose |
|---|---|
| `review_policy.dart` | LLD `ReviewPolicy`: a review is needed when payment is 0 to 7 days away; reminder choices are 1, 3, 5 days. |
| `review_service.dart` | LLD `ReviewService`: Keep, Review later, Stop tracking, the review list, and `processDuePayments`. |
| `calendar_service.dart` | LLD `CalendarService`: builds the calendar dots. |

**Notification Module** (`notification/`)

| File | Purpose |
|---|---|
| `reminder_scheduler.dart` | LLD `ReminderScheduler`: decides when reminders happen (7 days before, 1 day before, and the "Review later" day, all at 9:00 AM). |
| `notification_sender.dart` | LLD `NotificationSender`: the only code that talks to the phone's notification system. |

**Data Access Module** (`data_access/`)

| File | Purpose |
|---|---|
| `local_database.dart` | The HLD "Local Database". Stores lists of rows as JSON text with `shared_preferences`. Only the repositories use it. |
| `subscription_repository.dart`, `review_repository.dart`, `payment_repository.dart`, `reminder_repository.dart` | LLD repositories: insert, update, delete, find. |
| `settings_repository.dart` | Remembers notifications on/off, appearance, and the logged-in account. |
| `logo_store.dart` | Copies the chosen logo into the app's own folder so it is not lost. |
| `models/*.dart` | The LLD data classes (`Subscription`, `ReviewRecord`, `PaymentRecord`, `Reminder`, `CalendarEntry`, `DashboardSummary`, `ValidationResult`, `ValidationError`) and the enumerations in `enums.dart`. |

**Cloud Sync Module, optional** (`cloud_sync/`)

| File | Purpose |
|---|---|
| `sync_service.dart` | LLD `SyncService`: create account, log in, log out, back up, restore. |
| `firebase_client.dart` | LLD `FirebaseClient`, written as an interface so the app never depends on Firebase directly. |
| `mock_firebase_client.dart` | The default stand-in "cloud" that stores everything on the phone, so you can demo the account and backup flow without Firebase. |
| `backup_data.dart`, `user_account.dart` | LLD `BackupData` and `UserAccount`. |

### The key rules, in plain words

* **Your share:** `price / numberOfPeople` if shared, otherwise the full price.
* **Monthly cost:** Weekly = share x 52 / 12, Monthly = share, Yearly = share / 12. The dashboard total adds
  up only **active** subscriptions.
* **Needs review:** active, payment is today or within **7 days**, and you have not chosen **Keep** for that
  payment, and you have not snoozed it with **Review later** past today.
* **Review later:** you can only pick 1, 3 or 5 days, and the reminder day must be **before** the payment.
* **Stop tracking:** marks it Stopped and cancels its reminders. It does **not** cancel the real service
  (the app says so), as the proposal's limitations require.
* **When a payment date passes** (`processDuePayments`): SubCheck cannot see your bank, so it assumes the
  payment happened. It saves a payment (green on the calendar), saves a **missed review** (red) if you never
  chose Keep, then moves the subscription to its next payment date. This runs at start-up and every time you
  reopen the app.
* **Offline first:** nothing needs internet or login. Everything is saved on the phone, and the optional
  backup never blocks the main features.
* **No sensitive financial data** (no card or bank numbers) is asked for or stored.

### Small differences from the LLD

The LLD is the plan; a few small additions were needed to make the screens work. Each is marked with
`Added:` in the code comments.

* Methods that save data return a `Future` in Dart, so you write `await`.
* `ReviewRecord` gained `paymentDate` (which renewal the decision was about); `decision == null` means a
  **missed** review.
* `Reminder` gained `title` and `body`, and a type: renewal, payment or review.
* `NotificationSender` gained `cancel` and `cancelAll`. Its `showNotification` hands the reminder to the phone
  to show at the planned time (instead of showing it instantly).
* `FirebaseClient` gained `signOut`, and `downloadData` returns `null` when there is no backup yet.
* `BackupData` also contains review decisions and payment history, so the calendar survives a restore.
* A `SettingsRepository` was added for the Notifications and Appearance rows of Figure 9.
* `BillingCycle` is Weekly, Monthly or Yearly, exactly as in the LLD.

---

## PART 3. The optional cloud backup

By default `app_container.dart` uses `MockFirebaseClient`. Create account, log in, back up and restore
**really work**, and survive restarting the app, but the "cloud" is a table inside the phone's own storage,
and the demo stores passwords as plain text. So nothing leaves the phone, and it is for demonstration only.

To use the real Firebase Cloud (Authentication + Firestore), follow **`FIREBASE_SETUP.md`**. It contains a
ready-to-paste `RealFirebaseClient` and the one-line change in `app_container.dart`. The rest of the app does
not change.
