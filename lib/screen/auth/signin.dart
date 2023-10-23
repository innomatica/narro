import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

import '../../logic/auth.dart';
import '../../shared/constants.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  //
  // Google Sign In
  //
  Widget _buildSignInWithGoogle(AuthLogic auth) {
    return SizedBox(
      // width: 200,
      child: ElevatedButton.icon(
        icon: FaIcon(FontAwesomeIcons.google,
            size: 20, color: Theme.of(context).colorScheme.tertiary),
        onPressed: () async {
          final result = await auth.signInWithGoogle();
          if (mounted && result == null) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(
                'Failed to sign in (${auth.lastError})',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ));
          }
        },
        label: const Text('Sign In with Google'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthLogic>();
    return Scaffold(
      body: Center(
        child: SizedBox(
          width: 280,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              //
              // Book image
              //
              SizedBox(
                width: 140,
                height: 140,
                child: Image.asset(imageAssetReader, width: 30.0),
              ),
              const SizedBox(height: 20),
              //
              // App Name
              //
              Column(
                children: [
                  const Text(
                    appName,
                    style: TextStyle(
                      fontSize: 30.0,
                      fontWeight: FontWeight.w600,
                      // color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Document Reader',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.tertiary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              //
              // Sign In
              //
              // Text(
              //   'Sign in to proceed',
              //   style: TextStyle(
              //     // fontSize: 30.0,
              //     fontWeight: FontWeight.w600,
              //     color: Theme.of(context).colorScheme.secondary,
              //   ),
              // ),
              // const SizedBox(height: 18.0),
              //
              // Sign In with Google
              //
              _buildSignInWithGoogle(auth),
            ],
          ),
        ),
      ),
    );
  }
}
