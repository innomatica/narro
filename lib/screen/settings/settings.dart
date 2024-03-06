import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../logic/auth.dart';
import '../../logic/player.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

// TODO: getLanguages, setLanguage, getEngines, setEngine
class _SettingsPageState extends State<SettingsPage> {
  late final AuthLogic _auth;
  late final PlayerLogic _player;
  late String _speechRate;
  late String _pitch;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  void _initialize() {
    _auth = context.read<AuthLogic>();
    _player = context.read<PlayerLogic>();
    _speechRate = _player.speechRate.toString();
    _pitch = _player.pitch.toString();
  }

  //
  // Cancel Account Dialog
  //
  void _accountCancelDialog(AuthLogic auth) {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            title: Text(
              'Sign in again to proceed',
              style: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.error,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                //
                // Cancel through Google Sign In Authentication
                //
                SizedBox(
                  // width: 200,
                  child: ElevatedButton.icon(
                    icon: FaIcon(FontAwesomeIcons.google,
                        size: 20,
                        color: Theme.of(context).colorScheme.tertiary),
                    onPressed: () async {
                      final credential = await auth.signInWithGoogle();
                      if (credential != null) {
                        credential.user
                            ?.delete()
                            .then((_) => Navigator.of(context).pop(true));
                      } else {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(
                              'Failed to delete account (${auth.lastError})',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ));
                        }
                      }
                    },
                    label: const Text('Sign In with Google'),
                  ),
                ),
              ],
            ),
          );
        });
      },
    ).then((value) {
      // needs to pop
      if (value == true) {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ListView(
          children: [
            //
            // Email
            ///
            ListTile(
              title: const Text('My Email'),
              subtitle: Text(
                _auth.user?.email ?? '',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.tertiary,
                ),
              ),
            ),
            // Cancel Account
            ListTile(
              title: const Text('Cancel Account'),
              subtitle: Text(
                'Delete data and close account',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.tertiary,
                ),
              ),
              onTap: () => _accountCancelDialog(_auth),
            ),
            // Speech Rate
            ListTile(
              title: Row(
                children: [
                  const Expanded(child: Text('Speech Rate')),
                  const SizedBox(width: 20),
                  DropdownButton<String>(
                    // value: player.speechRate.toString(),
                    value: _speechRate,
                    items: ['0.2', '0.3', '0.4', '0.5', '0.6', '0.7', '0.8']
                        .map((e) =>
                            DropdownMenuItem<String>(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        _speechRate = value;
                        _player.setSpeechRate(double.parse(value));
                        setState(() {});
                      }
                    },
                  ),
                ],
              ),
            ),
            // Pitch
            ListTile(
              title: Row(
                children: [
                  const Expanded(child: Text('Voice Pitch')),
                  const SizedBox(width: 20),
                  DropdownButton<String>(
                    // value: player.pitch.toString(),
                    value: _pitch,
                    items: ['0.7', '0.8', '0.9', '1.0', '1.1', '1.2', '1.3']
                        .map((e) =>
                            DropdownMenuItem<String>(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        _pitch = value;
                        _player.setPitch(double.parse(value));
                        setState(() {});
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
