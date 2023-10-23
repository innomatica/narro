import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../logic/player.dart';
import '../../service/audiohandler.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerLogic>();
    // debugPrint('player.currentScript: ${player.currenScript}');
    double sliderValue =
        player.currentScript?.extras['currentLine']?.toDouble() ?? 0.0;
    return Row(
      children: [
        const SizedBox(width: 8, height: 0),
        Expanded(
            child: Text(
          player.currentScript?.title ?? '',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        )),
        const SizedBox(width: 8, height: 0),
        //
        // Current Line Number / Total Lines
        //
        TextButton(
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    StatefulBuilder(builder: (context, setState) {
                      return Slider(
                        onChanged: (value) {
                          sliderValue = value;
                          setState(() {});
                        },
                        onChangeEnd: (value) {
                          player.seek(Duration(seconds: sliderValue.round()));
                        },
                        label: sliderValue.round().toString(),
                        value: sliderValue,
                        min: 0.0,
                        max:
                            player.currentScript?.totalLines?.toDouble() ?? 0.0,
                        divisions: player.currentScript?.totalLines,
                      );
                    }),
                  ],
                ),
                // content: SizedBox(
                //   width: double.maxFinite,
                //   child: ListView.builder(
                //     shrinkWrap: true,
                //     itemCount: player.currenScript?.totalLines,
                //     itemBuilder: (context, index) => TextButton(
                //       onPressed: () {},
                //       child: Text(index.toString()),
                //     ),
                //   ),
                // ),
              ),
            );
          },
          child: Text(
            '(${player.currentScript?.extras["currentLine"]}'
            '/${player.currentScript?.totalLines})',
            style: TextStyle(
              color: Theme.of(context).colorScheme.secondary,
            ),
          ),
        ),
        //
        // Play Button
        //
        IconButton(
          icon: player.state == PlayerState.playing
              ? const Icon(Icons.pause)
              : player.state == PlayerState.idle
                  ? const Icon(Icons.play_arrow)
                  : const Icon(Icons.pending_outlined),
          // icon: player.isPlaying
          //     ? player.isStopping
          //         ? const Icon(Icons.pending_outlined)
          //         : const Icon(Icons.pause)
          //     : const Icon(Icons.play_arrow),
          onPressed: () {
            if (player.state == PlayerState.playing) {
              player.stop();
            } else if (player.state == PlayerState.idle) {
              player.play();
            }
            // if (player.isPlaying) {
            //   if (!player.isStopping) {
            //     player.stop();
            //   }
            // } else {
            //   player.resume();
            // }
          },
        ),
      ],
    );
  }
}
