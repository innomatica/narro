import 'dart:io';

import 'package:flutter/cupertino.dart';

import '../model/script.dart';
import '../service/audiohandler.dart';
import '../service/sqlite.dart';
import '../shared/helpers.dart';
import 'gdrive.dart';

class PlayerLogic extends ChangeNotifier {
  final _db = SqliteService();
  late final NarroAudioHandler _audio;
  GoogleDriveLogic? _drive;

  // we do typecasting to access custom members
  // final _audio = getIt<AudioHandler>() as NarroAudioHandler;

  PlayerLogic({GoogleDriveLogic? drive}) {
    // open database
    _db.open();
    // set drive logic
    if (drive != null) {
      setDrive(drive);
    }
    // async housekeeping tasks
    initialize();
  }

  Script? _currentScript;
  PlayerState? _playerState;

  Script? get currentScript => _currentScript;
  PlayerState? get state => _playerState;

  double get speechRate => _audio.speechRate;
  double get pitch => _audio.pitch;
  double get volume => _audio.volume;

  Future initialize() async {
    _audio = await initAudioService() as NarroAudioHandler;
    _audio.currentScript.listen((script) {
      _currentScript = script;
      notifyListeners();
    });

    _audio.playerState.listen((state) {
      _playerState = state;
      notifyListeners();
    });
  }

  void setDrive(GoogleDriveLogic drive) {
    _drive = drive;
  }

  void play() => _audio.play();
  void stop() => _audio.stop();
  void pause() => _audio.pause();
  void seek(Duration position) => _audio.seek(position);
  // void playScript(Script script) => _audio.playMediaItem(script.toMediaItem());

  void setSpeechRate(double rate) =>
      _audio.customAction('setSpeechRate', {'speechRate': rate});
  void setPitch(double pitch) =>
      _audio.customAction('setPitch', {'pitch': pitch});
  void setVolume(double volume) =>
      _audio.customAction('setVolume', {'volume': volume});

  Future updateScript(Script script) async {
    await _db.updateScript(script);
  }

  // FIXME: needs more sophisticated logic
  Future<Script?> getScript({required String id, required String title}) async {
    //  _audio is playing the script currently you need to use that
    if (id == _currentScript?.id) {
      return _currentScript;
    } else {
      Script? script = await _db.getScriptById(id);
      // if not exists
      if (script == null) {
        debugPrint('script not found');
        // download file => this will create a new script
        final flag = await _downloadFile(id: id, title: title);
        if (flag) {
          // retry
          script = await _db.getScriptById(id);
          debugPrint('retry reading script file: $script');
        }
      }
      return script;
    }
  }

  Future playFile({required String id, required String title}) async {
    final script = await getScript(id: id, title: title);
    if (script != null) {
      _audio.playMediaItem(script.toMediaItem());
    }
  }

  Future<bool> _downloadFile(
      {required String id, required String title}) async {
    final file = File('$appDir/$id.txt');

    debugPrint('download file');
    final res = await _drive?.exportFile(id: id);

    // successful exporting
    if (res is String) {
      debugPrint('create file');
      // insert newlines to break paragraph into lines
      await file.writeAsString(res.replaceAll('. ', '.\n'));
      // create the script for the file
      debugPrint('create script');
      final script = Script(id: id, title: title, extras: {});
      // set current line and total lines
      script.extras['currentLine'] = 0;
      script.totalLines = file.readAsLinesSync().length;
      // update script
      await _db.addScript(script);
      return true;
    }

    debugPrint('failed to download');
    return false;
  }
}
