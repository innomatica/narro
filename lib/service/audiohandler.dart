import 'dart:async';
import 'dart:io';

import 'package:audio_service/audio_service.dart';
// import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../model/script.dart';
import '../service/sqlite.dart';
import '../shared/helpers.dart';

Future<AudioHandler> initAudioService() async {
  return await AudioService.init(
    builder: () => NarroAudioHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.innomatic.narroapp.channel.audio',
      androidNotificationChannelName: 'Narro',
      androidNotificationOngoing: true,
      androidNotificationIcon: 'drawable/app_icon',
    ),
  );
}

enum PlayerState { idle, playing, busy }

class NarroAudioHandler extends BaseAudioHandler {
  final _db = SqliteService();
  final _tts = FlutterTts();
  final _playlist = <Script>[];
  // late final String _dirPath;

  final _playerStateController = StreamController<PlayerState>.broadcast();
  final _currentScriptController = StreamController<Script?>.broadcast();

  bool _stopRequest = false;
  double _rate = 0.5; // 0 to 1.0
  double _pitch = 1.0; // 0.5 to 2.0
  double _volume = 1.0; // 0 to 1.0
  PlayerState _playerState = PlayerState.idle;

  NarroAudioHandler() {
    initialize();
  }

  double get pitch => _pitch;
  double get volume => _volume;
  double get speechRate => _rate;
  Stream<PlayerState> get playerState => _playerStateController.stream;
  Stream<Script?> get currentScript => _currentScriptController.stream;

  Future initialize() async {
    await _tts.awaitSpeakCompletion(true);
    await _tts.setVolume(_volume);
    await _tts.setPitch(_pitch);
    await _tts.setSpeechRate(_rate);
    // streams
    _playerStateController.add(_playerState);
  }

  @override
  Future<void> play() async {
    // debugPrint('stop: $_playerState');
    if (_playlist.isNotEmpty && _playerState == PlayerState.idle) {
      // get script
      final script = _playlist.first;
      // get data file
      final file = File('$appDir/${script.id}.txt');

      int lineNo = 0;

      // broadcast current state
      // _playerStateController.add(PlayerState.playing);
      _broadcastPlayerState(state: PlayerState.playing, script: script);
      // broadcast media item
      mediaItem.add(script.toMediaItem());

      for (final line in file.readAsLinesSync()) {
        lineNo = lineNo + 1;
        // skip to the last playing line
        if ((script.extras['currentLine'] ?? 0) > lineNo) {
          // debugPrint('skipping line:$index');
          continue;
        }

        // debugPrint('playing line no: $lineNo');
        script.extras['currentLine'] = lineNo;
        _currentScriptController.add(script);
        _broadcastPlayerState(state: PlayerState.playing, script: script);

        // speak
        await _tts.speak(line);
        // debugPrint('finished line no: $lineNo');

        if (_stopRequest) {
          // debugPrint('stop request detected');
          // clear stop reques flag
          _stopRequest = false;
          break;
        }
      }

      // reach to the end?
      if (script.extras['currentLine'] == script.totalLines) {
        // rewind
        script.extras['currentLine'] = 0;
        // remove the script from the playlist
        _playlist.remove(script);
        // update current script
        _currentScriptController.add(null);
      }
      // save the script
      await _db.updateScript(script);
      // update player state
      // _playerStateController.add(PlayerState.idle);
      _broadcastPlayerState(state: PlayerState.idle, script: script);
    }
  }

  @override
  Future<void> playMediaItem(MediaItem mediaItem) async {
    _playlist.clear();
    _playlist.add(Script.fromMediaItem(mediaItem));
    play();

    // broadcast mediaItem change
    // apparently this does not work
    // actual broadcasting of mediaItem is done in play()
    // mediaItem.add(mediaItem);
  }

  @override
  Future<void> stop() async {
    // debugPrint('stop: $_playerState');
    if (_playerState == PlayerState.playing) {
      _stopRequest = true;
      // _playerStateController.add(PlayerState.busy);
      _broadcastPlayerState(state: PlayerState.busy);
    }
  }

  @override
  Future<void> pause() async {
    // debugPrint('pause: $_playerState');
    if (_playerState == PlayerState.playing) {
      _stopRequest = true;
      // _playerStateController.add(PlayerState.busy);
      _broadcastPlayerState(state: PlayerState.busy);
    }
  }

  @override
  Future<void> seek(Duration position) async {
    // FIXME: if new position is set while playing, it is ignored
    if (_playlist.isNotEmpty) {
      final script = _playlist.first;
      script.extras['currentLine'] = position.inSeconds;
      _currentScriptController.add(script);
    }
  }

  @override
  Future customAction(String name, [Map<String, dynamic>? extras]) async {
    if (name == 'setVolume') {
      final volume = extras?['volume'] ?? 1.0;
      if (volume >= 0.0 && volume <= 1.0) {
        _volume = volume;
        await _tts.setVolume(volume);
      }
    } else if (name == 'setPitch') {
      final pitch = extras?['pitch'] ?? 1.0;
      if (pitch >= 0.5 && pitch <= 2.0) {
        _pitch = pitch;
        await _tts.setPitch(pitch);
      }
    } else if (name == 'setSpeechRate') {
      final rate = extras?['speechRate'] ?? 0.5;
      if (rate >= 0.0 && rate <= 1.0) {
        _rate = rate;
        await _tts.setSpeechRate(rate);
      }
    }
  }

  void _broadcastPlayerState({required PlayerState state, Script? script}) {
    // debugPrint('broadcastPlayerState.script: $script');
    // save internally
    _playerState = state;

    // report to the UI
    _playerStateController.add(state);

    // report to the system
    playbackState.add(PlaybackState(
      // Which buttons should appear in the notification now
      controls: [
        // MediaControl.skipToPrevious,
        MediaControl.play,
        MediaControl.pause,
        // MediaControl.stop,
        // MediaControl.skipToNext,
      ],
      // Which other actions should be enabled in the notification
      // systemActions: const {
      //   MediaAction.seek,
      //   MediaAction.seekForward,
      //   MediaAction.seekBackward,
      // },
      // Which controls to show in Android's compact view.
      androidCompactActionIndices: const [0, 1],
      // Whether audio is ready, buffering, ...
      processingState: AudioProcessingState.ready,
      // Whether audio is playing
      playing: state != PlayerState.idle,

      // The current position as of this update. You should not broadcast
      // position changes continuously because listeners will be able to
      // project the current position after any elapsed time based on the
      // current speed and whether audio is playing and ready. Instead, only
      // broadcast position updates when they are different from expected (e.g.
      // buffering, or seeking).
      updatePosition: Duration(seconds: script?.extras['currentLine'] ?? 0),

      // The current buffered position as of this update
      // bufferedPosition: Duration(milliseconds: 65432),

      // The current speed
      // speed: 1.0,
      speed: 0.1,

      // The current queue position
      // queueIndex: 0,
    ));
  }
}
