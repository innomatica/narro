import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../logic/auth.dart';
import 'auth/signin.dart';
import 'home/home.dart';

class Wrapper extends StatelessWidget {
  const Wrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthLogic>().user;
    if (user != null) {
      return const HomePage();
    }
    return const SignInPage();

    // return StreamBuilder<User?>(
    //   stream: FirebaseAuth.instance.authStateChanges(),
    //   builder: (context, snapshot) {
    //     if (snapshot.hasData) {
    //       debugPrint('${snapshot.data?.displayName}');
    //       return const HomePage();
    //     }
    //     return const AuthGate();
    //   },
    // );
  }
}
