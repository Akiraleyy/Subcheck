import '../data_access/payment_repository.dart';
import '../data_access/review_repository.dart';
import '../data_access/settings_repository.dart';
import '../data_access/subscription_repository.dart';
import 'backup_data.dart';
import 'firebase_client.dart';
import 'user_account.dart';

/// LLD class: SyncService. Handles the OPTIONAL account and cloud backup.
/// The core app never needs it; it is only used from the Settings screen.
class SyncService {
  SyncService({
    required this.firebaseClient,
    required this.subscriptionRepository,
    required this.reviewRepository,
    required this.paymentRepository,
    required this.settingsRepository,
  }) : currentUser = settingsRepository.currentUser;

  final FirebaseClient firebaseClient;
  final SubscriptionRepository subscriptionRepository;

  // Added: the backup also includes review decisions and payment history.
  final ReviewRepository reviewRepository;
  final PaymentRepository paymentRepository;
  final SettingsRepository settingsRepository;

  /// The signed-in user, or null if the user is using SubCheck offline only.
  UserAccount? currentUser;

  /// Why the last action returned false (shown to the user).
  String? lastError;

  Future<bool> createAccount(String name, String email, String password) async {
    lastError = null;
    final ok = await firebaseClient.signUp(name, email, password);
    if (!ok) {
      lastError = firebaseClient.lastError ?? 'Could not create the account.';
      return false;
    }
    currentUser = firebaseClient.account;
    await settingsRepository.saveCurrentUser(currentUser);
    return true;
  }

  Future<bool> logIn(String email, String password) async {
    lastError = null;
    final ok = await firebaseClient.signIn(email, password);
    if (!ok) {
      lastError = firebaseClient.lastError ?? 'Could not log in.';
      return false;
    }
    currentUser = firebaseClient.account;
    await settingsRepository.saveCurrentUser(currentUser);
    return true;
  }

  /// Logging out keeps all subscriptions on the phone.
  Future<void> logOut() async {
    await firebaseClient.signOut();
    currentUser = null;
    await settingsRepository.saveCurrentUser(null);
  }

  /// Uploads the phone's data to the cloud (needs internet and an account).
  Future<bool> backupData() async {
    lastError = null;
    final user = currentUser;
    if (user == null) {
      lastError = 'Log in first to back up your data.';
      return false;
    }
    final data = BackupData(
      subscriptions: subscriptionRepository.findAll(),
      reviewRecords: reviewRepository.findAll(),
      paymentRecords: paymentRepository.findAll(),
      createdAt: DateTime.now(),
    );
    final ok = await firebaseClient.uploadData(user.uid, data);
    if (!ok) {
      lastError = firebaseClient.lastError ??
          'Backup failed. Check your internet connection.';
      return false;
    }
    await settingsRepository.saveLastBackup(DateTime.now());
    return true;
  }

  /// Replaces the data on the phone with the cloud backup.
  Future<bool> restoreData() async {
    lastError = null;
    final user = currentUser;
    if (user == null) {
      lastError = 'Log in first to restore your data.';
      return false;
    }
    final data = await firebaseClient.downloadData(user.uid);
    if (data == null) {
      lastError = firebaseClient.lastError ?? 'No backup was found for this account.';
      return false;
    }
    await subscriptionRepository.replaceAll(data.subscriptions);
    await reviewRepository.replaceAll(data.reviewRecords);
    await paymentRepository.replaceAll(data.paymentRecords);
    return true;
  }
}
