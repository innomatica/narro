import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:path_provider/path_provider.dart';

Widget getIconByMimeType(String? mimeType) {
  switch (mimeType) {
    case 'text/plain':
      return const FaIcon(FontAwesomeIcons.fileLines, color: Colors.green);
    case 'text/csv':
      return const FaIcon(FontAwesomeIcons.fileCsv, color: Colors.green);
    case 'image/png':
    case 'image/jpeg':
      return const FaIcon(FontAwesomeIcons.fileImage, color: Colors.red);
    case 'application/pdf':
      return const FaIcon(FontAwesomeIcons.filePdf, color: Colors.red);
    case 'application/vnd.google-apps.document':
      return const FaIcon(FontAwesomeIcons.fileLines, color: Colors.blue);
    case 'application/msword':
    case 'application/vnd.openxmlformats-officedocument.wordprocessingml.document':
      return const FaIcon(FontAwesomeIcons.fileWord, color: Colors.blue);
    case 'application/vnd.ms-powerpoint':
    case 'application/vnd.google-apps.presentation':
    case 'application/vnd.openxmlformats-officedocument.presentationml.presentation':
      return const FaIcon(FontAwesomeIcons.filePowerpoint, color: Colors.blue);
    case 'application/vnd.ms-excel':
    case 'application/vnd.google-apps.spreadsheet':
    case 'application/vnd.oasis.opendocument.spreadsheet':
    case 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet':
      return const FaIcon(FontAwesomeIcons.fileExcel, color: Colors.blue);
    case 'application/vnd.google-apps.folder':
      return const FaIcon(FontAwesomeIcons.folder, color: Colors.black54);
    default:
      debugPrint('unknown mimeType: $mimeType');
      return const FaIcon(FontAwesomeIcons.file);
  }
}

// application directory path
String? appDir;
// default art uri
String? artUri;

Future initializeGlobals() async {
  appDir = (await getApplicationDocumentsDirectory()).path;
  final bytes = await rootBundle.load('assets/images/reader.png');
  final file = File('$appDir/reader.png');
  file.writeAsBytes(bytes.buffer.asUint8List());
  artUri = 'file://${file.path}';
}
