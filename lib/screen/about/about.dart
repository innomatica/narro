import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../shared/constants.dart';
import '../../shared/settings.dart';

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  String? _getStoreUrl() {
    if (Platform.isAndroid) {
      return urlGooglePlay;
    } else if (Platform.isIOS) {
      return urlAppStore;
    }
    return urlHomePage;
  }

  Widget _buildBody() {
    return ListView(
      children: [
        ListTile(
          title: Text(
            'Version',
            style: TextStyle(color: Theme.of(context).colorScheme.primary),
          ),
          subtitle: const Text(appVersion),
        ),
        ListTile(
          title: Text(
            'Instructions',
            style: TextStyle(color: Theme.of(context).colorScheme.primary),
          ),
          subtitle: const Text('How to Use This App'),
          onTap: () {
            launchUrl(Uri.parse(urlInstruction),
                mode: LaunchMode.externalApplication);
          },
        ),
        ListTile(
          title: Text(
            'Visit App Store',
            style: TextStyle(color: Theme.of(context).colorScheme.primary),
          ),
          subtitle: const Text('Rate Our App and Report Bugs'),
          onTap: () {
            final url = _getStoreUrl();
            if (url != null) {
              launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
            }
          },
        ),
        ListTile(
          title: Text(
            'Recommend to Others',
            style: TextStyle(color: Theme.of(context).colorScheme.primary),
          ),
          subtitle: const Text('Show QR Code'),
          onTap: () {
            final url = _getStoreUrl();
            if (url != null) {
              showDialog(
                context: context,
                builder: (context) {
                  return SimpleDialog(
                    title: Center(
                      child: Text(
                        'Visit Our Store',
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.primary),
                      ),
                    ),
                    // backgroundColor: Colors.white,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10.0),
                        child: Image.asset(playStoreUrlQrCode),
                      )
                    ],
                  );
                },
              );
            }
          },
        ),

        // ListTile(
        //   title: Text(
        //     'App Icons',
        //     style: TextStyle(color: Theme.of(context).colorScheme.primary),
        //   ),
        //   subtitle: const Text("Book icons created by Freepik - Flaticon"),
        //   onTap: () {
        //     launchUrl(Uri.parse(urlAppIconSource));
        //   },
        // ),
        // ListTile(
        //   title: Text(
        //     'Store Background Image',
        //     style: TextStyle(color: Theme.of(context).colorScheme.primary),
        //   ),
        //   subtitle: const Text("Photo by Fabiola Peñalba at unsplash.com"),
        //   onTap: () {
        //     launchUrl(Uri.parse(urlStoreImageSource));
        //   },
        // ),
        ListTile(
          title: Text(
            'Disclaimer',
            style: TextStyle(color: Theme.of(context).colorScheme.primary),
          ),
          subtitle:
              const Text('We assumes no responsibility for errors or omissions '
                  'in the contents of the Service. (tap for the full text).'),
          onTap: () {
            launchUrl(Uri.parse(urlDisclaimer));
          },
        ),
        ListTile(
          title: Text(
            'Privacy Policy',
            style: TextStyle(color: Theme.of(context).colorScheme.primary),
          ),
          subtitle: const Text('We only collect essential data for the '
              'service and do not share it with any third parties '
              '(tap for the full text).'),
          onTap: () {
            launchUrl(Uri.parse(urlPrivacyPolicy));
          },
        ),
        ListTile(
          title: Text(
            'About Us',
            style: TextStyle(color: Theme.of(context).colorScheme.primary),
          ),
          subtitle: const Text(urlHomePage),
          onTap: () {
            launchUrl(Uri.parse(urlHomePage),
                mode: LaunchMode.externalApplication);
          },
        ),
        ListTile(
          title: Text(
            'Attributions',
            style: TextStyle(color: Theme.of(context).colorScheme.primary),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextButton(
                onPressed: () => launchUrl(Uri.parse(urlAppIconSource)),
                child: Text('Book icons created by Freepik - Flaticon',
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant)),
              ),
              TextButton(
                onPressed: () => launchUrl(Uri.parse(urlStoreImageSource)),
                child: Text('Store Photo by Fabiola Peñalba - unsplash.com',
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () => Navigator.pop(context, true),
        ),
        title: const Text('About'),
      ),
      body: _buildBody(),
    );
  }
}
