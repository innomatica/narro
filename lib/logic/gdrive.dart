import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:googleapis/drive/v3.dart' as drive;

import '../service/sqlite.dart';
import '../shared/constants.dart';
import '../shared/helpers.dart';
import 'auth.dart';

// https://developers.google.com/drive/api/guides/about-files

class GoogleDriveLogic extends ChangeNotifier {
  final _db = SqliteService();
  final _files = <drive.File>[];
  bool _busy = true;
  // drive.DriveApi? _drive;
  AuthLogic? _auth;
  drive.File? _appRoot;

  GoogleDriveLogic();

  bool get busy => _busy;
  drive.File? get appRoot => _appRoot;
  List<drive.File> get files => _files;

  Future _refreshFiles() async {
    // get auth client
    final authClient = await _auth?.getAuthClient();

    if (authClient != null) {
      // get drive api
      final api = drive.DriveApi(authClient);

      _busy = true;
      notifyListeners();
      // get file list
      try {
        //
        // https://developers.google.com/drive/api/guides/fields-parameter
        //
        _files.clear();
        final flist = await api.files.list(
            q: 'trashed=false', $fields: "files(id,name,mimeType,createdTime)");

        if (flist.files != null) {
          _files.addAll(flist.files!
              .where((e) =>
                  e.name != appName ||
                  e.mimeType != 'application/vnd.google-apps.folder')
              .toList());
          notifyListeners();
          _purgeLocalData();
        }
      } catch (e) {
        debugPrint(e.toString());
      }
      _busy = false;
      notifyListeners();
    }
  }

  //
  // Purge Local Data: delete local txt files and db entries if the original
  // files do not show up in the files
  //
  Future _purgeLocalData() async {
    final scripts = await _db.getScripts();
    final ids = List.generate(files.length, (index) => files[index].id);
    for (final script in scripts) {
      if (!ids.contains(script.id)) {
        final file = File('$appDir/${script.id}.txt');
        await file.delete();
        await _db.deleteScript(script);
      }
    }
  }

  void setAuth(AuthLogic auth) async {
    // final authClient = await auth.getAuthClient();

    // if (authClient != null) {
    //   _drive = drive.DriveApi(authClient);
    //   _initializeApi();
    // } else {
    //   _drive = null;
    // }
    _auth = auth;
    _initializeApi();
  }

  void _initializeApi() async {
    // get auth client
    final authClient = await _auth?.getAuthClient();

    if (authClient != null) {
      // get drive api
      final api = drive.DriveApi(authClient);

      // get filelist excluding trashed
      final flist = await api.files.list(
        q: 'trashed=false',
        $fields: "files(id,name,mimeType,createdTime)",
      );

      // get files
      final files = flist.files;

      if (files == null || files.isEmpty) {
        // no files found including appRoot
        await createRootDirectory();
      } else {
        // get app root
        _appRoot = flist.files!.firstWhere((e) =>
            e.name == appName &&
            e.mimeType == 'application/vnd.google-apps.folder');
        // debugPrint('initApi.appRoot: $_appRoot');
      }
      _refreshFiles();
    }
  }

  //
  // https://developers.google.com/drive/api/guides/create-file?
  //
  Future createRootDirectory() async {
    // get auth client
    final authClient = await _auth?.getAuthClient();

    if (authClient != null) {
      // get drive api
      final api = drive.DriveApi(authClient);

      try {
        final req = drive.File.fromJson({
          'name': appName,
          'mimeType': 'application/vnd.google-apps.folder',
        });
        _appRoot = await api.files.create(req);
        debugPrint('createRootDirectory: ${_appRoot?.id}');
      } catch (e) {
        debugPrint(e.toString());
      }
    }
  }

  //
  // Conversion of PDF to TXT
  //  1. upload pdf file as google doc (application/vnd.google-apps.document)
  //  2. export it as a text ('text/plain')
  //
  // https://stackoverflow.com/questions/43713924/how-to-extract-pdf-content-into-txt-file-with-google-docs
  //
  //
  // https://pub.dev/documentation/googleapis/latest/drive.v3/FilesResource/create.html
  // https://developers.google.com/drive/api/guides/create-file?
  //
  Future uploadFile({
    required String name,
    required String mimeType,
    drive.Media? media,
  }) async {
    // get auth client
    final authClient = await _auth?.getAuthClient();

    if (_appRoot != null && authClient != null) {
      // get drive api
      final api = drive.DriveApi(authClient);
      debugPrint('uploadFile.mimeType: $mimeType');

      try {
        final req = drive.File.fromJson({
          'name': name,
          'mimeType': mimeType,
          'parents': [_appRoot!.id],
        });
        _busy = true;
        notifyListeners();
        final ret = await api.files.create(
          req,
          uploadMedia: media,
        );
        debugPrint('create file: $ret');
        _busy = false;
        await _refreshFiles();
      } catch (e) {
        debugPrint(e.toString());
      }
    }
  }

  //
  // This function only works for Google Workspace files (Docs, Sheets, Slides, ...)
  //
  // https://pub.dev/documentation/googleapis/latest/drive.v3/FilesResource/export.html
  // https://developers.google.com/drive/api/v3/reference/files/export
  // https://developers.google.com/drive/api/guides/manage-downloads
  //
  //
  // However, you can do the conversion of PDF to TXT using following trick
  //
  //  1. upload pdf file as google doc (application/vnd.google-apps.document)
  //  2. export it as a text ('text/plain')
  //
  // https://stackoverflow.com/questions/43713924/how-to-extract-pdf-content-into-txt-file-with-google-docs
  //
  Future<String?> exportFile({String? id, String? mimeType}) async {
    // get auth client
    final authClient = await _auth?.getAuthClient();

    if (id != null && authClient != null) {
      // get drive api
      final api = drive.DriveApi(authClient);

      try {
        final res = await api.files.export(
          id,
          mimeType ?? 'text/plain',
          downloadOptions: drive.DownloadOptions.fullMedia,
        );
        if (res is drive.Media) {
          return await utf8.decodeStream(res.stream);
        } else {
          debugPrint('getFileContent: invalid response');
        }
      } catch (e) {
        debugPrint(e.toString());
      }
    }
    return null;
  }

  //
  // * To get contents, provide URL parameter alt=media, in flutter use
  //    DownloadOptions.fullMedia
  //
  // * To download Google Docs, Sheets, and Slides use files.export
  //
  // https://pub.dev/documentation/googleapis/latest/drive.v3/FilesResource/get.html
  // https://developers.google.com/drive/api/v3/reference/files/get
  // https://developers.google.com/drive/api/guides/manage-downloads
  // https://stackoverflow.com/questions/49643460/dart-flutter-download-or-read-the-contents-of-a-google-drive-file
  //
  //
  Future<String?> getFileContent({String? fileId}) async {
    // get auth client
    final authClient = await _auth?.getAuthClient();

    if (fileId != null && authClient != null) {
      // get drive api
      final api = drive.DriveApi(authClient);

      try {
        final res = await api.files.get(
          fileId,
          downloadOptions: drive.DownloadOptions.fullMedia,
        );
        if (res is drive.Media) {
          return await utf8.decodeStream(res.stream);
        } else {
          debugPrint('getFileContent: invalid response');
        }
      } catch (e) {
        debugPrint(e.toString());
      }
    }
    return null;
  }

  Future deleteFileById(String id) async {
    // get auth client
    final authClient = await _auth?.getAuthClient();

    if (authClient != null) {
      // get drive api
      final api = drive.DriveApi(authClient);

      try {
        _busy = true;
        notifyListeners();
        await api.files.delete(id);
        _busy = false;
        await _refreshFiles();
      } catch (e) {
        debugPrint(e.toString());
      }
    }
  }

  Future refresh() async {
    await _refreshFiles();
  }
}
