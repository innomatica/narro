import 'package:dynamic_color/dynamic_color.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'logic/auth.dart';
import 'logic/gdrive.dart';
import 'logic/player.dart';
import 'shared/apptheme.dart';
import 'shared/constants.dart';
import 'shared/helpers.dart';
import 'shared/settings.dart';
import 'screen/wrapper.dart';

void main() async {
  // flutter
  WidgetsFlutterBinding.ensureInitialized();

  // firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // emulator
  if (useFirebaseEmulator) {
    await FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
  }

  // app directory
  await initializeGlobals();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthLogic>(create: (_) => AuthLogic()),
        ChangeNotifierProxyProvider<AuthLogic, GoogleDriveLogic>(
          create: (_) => GoogleDriveLogic(),
          update: (_, auth, gdrive) {
            if (gdrive == null) {
              return GoogleDriveLogic();
            } else {
              return gdrive..setAuth(auth);
            }
          },
        ),
        ChangeNotifierProxyProvider<GoogleDriveLogic, PlayerLogic>(
          create: (_) => PlayerLogic(),
          update: (_, drive, player) {
            if (player == null) {
              return PlayerLogic(drive: drive);
            } else {
              return player..setDrive(drive);
            }
          },
        ),
      ],
      child: DynamicColorBuilder(
          builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        return MaterialApp(
          title: appName,
          theme: AppTheme.lightTheme(lightDynamic),
          darkTheme: AppTheme.darkTheme(darkDynamic),
          home: const Wrapper(),
          debugShowCheckedModeBanner: false,
        );
      }),
    );
  }
}
