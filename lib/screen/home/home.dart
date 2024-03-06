import 'dart:convert' show utf8;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../../logic/gdrive.dart';
import '../../logic/player.dart';
import '../../service/audiohandler.dart';
import '../../shared/constants.dart';
import '../../shared/helpers.dart';
import '../about/about.dart';
import '../home/instruction.dart';
import '../player/miniplayer.dart';
import '../settings/settings.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  //
  // Scaffold Menu Button
  //
  Widget _buildMenuButton() {
    return PopupMenuButton<String>(onSelected: (value) {
      switch (value) {
        case 'settings':
          Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const SettingsPage()));
          break;
        case 'about':
          Navigator.of(context)
              .push(MaterialPageRoute(builder: (context) => const AboutPage()));
          break;
        default:
          break;
      }
    }, itemBuilder: (context) {
      return <PopupMenuItem<String>>[
        PopupMenuItem<String>(
          value: 'settings',
          child: Row(children: [
            Icon(Icons.settings, color: Theme.of(context).colorScheme.primary),
            const Text('  Settings'),
          ]),
        ),
        PopupMenuItem<String>(
          value: 'about',
          child: Row(children: [
            Icon(Icons.info, color: Theme.of(context).colorScheme.primary),
            const Text('  About'),
          ]),
        ),
      ];
    });
  }

  Widget _buildBody() {
    final gdrive = context.watch<GoogleDriveLogic>();
    final player = context.read<PlayerLogic>();
    final files = gdrive.files;
    final formatter = DateFormat('y MMM d - H:m');
    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: () => gdrive.refresh(),
          // child: gdrive.busy
          //     ? Container()
          //     : files.isEmpty
          child: !gdrive.busy && files.isEmpty
              ? const Instruction()
              : ListView.builder(
                  itemCount: files.length,
                  itemBuilder: (context, index) {
                    final file = files[index];
                    return Card(
                      // elevation:
                      //     player.currentScript?.id == file.id ? 4 : 0,
                      // shadowColor:
                      //     Theme.of(context).colorScheme.surfaceTint,
                      color: player.currentScript?.id == file.id
                          ? Theme.of(context).colorScheme.secondaryContainer
                          : null,
                      child: ListTile(
                        // dense: true,
                        // contentPadding: EdgeInsets.all(0),
                        leading: getIconByMimeType(file.mimeType),
                        minLeadingWidth: 0,
                        title: Text(
                          file.name ?? '',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: player.currentScript?.id == file.id
                                ? Theme.of(context)
                                    .colorScheme
                                    .onSecondaryContainer
                                : null,
                          ),
                        ),
                        subtitle: Text(
                          formatter.format(file.createdTime ?? DateTime.now()),
                          style: TextStyle(
                            fontSize: 13,
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                        ),
                        onTap: () async {
                          if (player.state != PlayerState.idle) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Row(
                                  children: [
                                    Text('Player is busy... '
                                        'Stop the current speech first'),
                                  ],
                                ),
                              ),
                            );
                          } else {
                            if (file.id != null && file.name != null) {
                              player.playFile(id: file.id!, title: file.name!);
                            }
                          }
                        },
                        onLongPress: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text(
                                'Delete this document?',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context).colorScheme.error,
                                ),
                              ),
                              content: Text(
                                file.name ?? '',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              actions: [
                                OutlinedButton(
                                  onPressed: () async {
                                    if (file.id != null) {
                                      gdrive.deleteFileById(file.id!);
                                      Navigator.of(context).pop();
                                    }
                                  },
                                  child: const Text('YES'),
                                )
                              ],
                            ),
                          );
                        },
                        trailing: InkWell(
                          onTap: () async {
                            if (file.id != null) {
                              final script = await player.getScript(
                                  id: file.id!, title: file.name!);
                              if (script != null && context.mounted) {
                                debugPrint('inkwell.script:$script');
                                String? note;
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: Text(
                                      file.name ?? '',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w500,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .tertiary,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    content: TextFormField(
                                      initialValue: script.extras['note'],
                                      onChanged: (value) => note = value,
                                      maxLines: null,
                                      keyboardType: TextInputType.multiline,
                                      decoration:
                                          const InputDecoration.collapsed(
                                              hintText: 'enter note here'),
                                    ),
                                    actions: [
                                      OutlinedButton(
                                        child: const Text('save note'),
                                        onPressed: () {
                                          script.extras['note'] = note;
                                          player.updateScript(script);
                                          Navigator.of(context).pop();
                                        },
                                      ),
                                    ],
                                  ),
                                );
                              }
                            }
                          },
                          child: Icon(
                            Icons.edit_note,
                            size: 26,
                            color: Theme.of(context).colorScheme.tertiary,
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
        Center(
            child: gdrive.busy
                ? const SizedBox(
                    width: 30,
                    height: 30,
                    child: CircularProgressIndicator(),
                  )
                : null),
      ],
    );
  }

  Widget _buildFab() {
    final bloc = context.read<GoogleDriveLogic>();
    // const link = 'https://www.canada.ca/en/health-canada.html';
    return FloatingActionButton(
      onPressed: () async {
        String? url;
        showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: Text(
                  'Add New Document',
                  style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(context).colorScheme.primary),
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: double.maxFinite,
                      child: FilledButton(
                          onPressed: () {
                            Navigator.of(context).pop(urlCompanionSite);
                            // launchUrl(Uri.parse(urlCompanionSite));
                          },
                          child: const Text('Upload From Device')),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      onChanged: (value) => url = value,
                      decoration: InputDecoration(
                        labelText: 'Scrap Web Page',
                        hintText: 'https://www.cbc.ca/news',
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.check),
                          onPressed: () {
                            Navigator.of(context).pop(url);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).then((url) async {
          if (url != null && url is String && url.isNotEmpty) {
            debugPrint('url');
            if (url == urlCompanionSite) {
              launchUrl(Uri.parse(url));
            } else {
              String error = '';
              try {
                final uri = Uri.parse(url);
                //
                // This seems to be a weird bug: Uri.parse does not report error
                // you need to check the scheme to validate the url
                //
                if (uri.scheme == 'http' || uri.scheme == 'https') {
                  final res = await http.get(uri);
                  // debugPrint('res.body:${res.body}');
                  if (res.statusCode == 200) {
                    final htmlBody = res.body;
                    int length = 0;
                    final content =
                        htmlBody.split('\n').map((e) => utf8.encode('$e\n'));
                    // content length: differ from htmlBody.length
                    for (final line in content) {
                      length = length + line.length;
                    }
                    debugPrint('length: $length');
                    debugPrint('body size: ${htmlBody.length}');
                    bloc.uploadFile(
                      name: url,
                      mimeType: 'application/vnd.google-apps.document',
                      media: drive.Media(Stream.fromIterable(content), length),
                    );
                  } else {
                    error = 'Status code ${res.statusCode} returned';
                  }
                } else {
                  error = 'Invalid URL entered';
                }
              } catch (e) {
                error = e.toString();
              }
              if (error.isNotEmpty && mounted) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text(error)));
              }
            }
          }
        });
      },
      backgroundColor:
          Theme.of(context).colorScheme.tertiaryContainer.withOpacity(0.8),
      child: const Icon(Icons.add),
    );
  }

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerLogic>();
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(
              'assets/images/reader.png',
              width: 38,
            ),
            const SizedBox(width: 10),
            Text(
              appName,
              style: TextStyle(color: Theme.of(context).colorScheme.secondary),
            ),
          ],
        ),
        actions: [
          _buildMenuButton(),
        ],
      ),
      body: _buildBody(),
      bottomSheet: player.currentScript != null ? const MiniPlayer() : null,
      floatingActionButton: _buildFab(),
      floatingActionButtonLocation:
          FloatingActionButtonLocation.miniCenterFloat,
    );
  }
}
