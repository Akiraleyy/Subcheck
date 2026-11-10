import 'package:flutter/material.dart';

import 'app.dart';
import 'app_container.dart';

/// Where the app starts.
///
/// 1. Build all objects and load the saved data from the phone (no internet
///    and no login needed).
/// 2. Open the app. The first screen is the Home Dashboard.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final container = await AppContainer.create();
  runApp(SubCheckApp(container: container));
}
