import 'backup_data.dart';
import 'user_account.dart';

/// LLD class: FirebaseClient. The ONLY class that talks to the cloud.
///
/// It is written as an interface (a list of what a cloud client must do) so
/// the rest of the app never depends on Firebase directly:
///  * [MockFirebaseClient] (default) pretends to be the cloud using the
///    phone's own storage, so the whole account + backup flow can be run and
///    demonstrated WITHOUT creating a Firebase project.
///  * FIREBASE_SETUP.md contains a ready-made RealFirebaseClient. To go live,
///    add it and change ONE line in app_container.dart.
///
/// The LLD says signUp/signIn return a bool. They do. When the result is
/// false, [lastError] holds a message the screen can show.
abstract class FirebaseClient {
  /// Why the last call failed, e.g. "Incorrect email or password."
  String? get lastError;

  /// The account after a successful signUp / signIn.
  UserAccount? get account;

  Future<bool> signUp(String name, String email, String password);

  Future<bool> signIn(String email, String password);

  /// Added: logging out.
  Future<void> signOut();

  Future<bool> uploadData(String userId, BackupData data);

  /// Returns null when the user has no backup yet (or the download failed).
  Future<BackupData?> downloadData(String userId);
}
