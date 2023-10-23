import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../logic/gdrive.dart';

class Instruction extends StatefulWidget {
  const Instruction({super.key});

  @override
  State<Instruction> createState() => _InstructionState();
}

class _InstructionState extends State<Instruction> {
  @override
  Widget build(BuildContext context) {
    final gdrive = context.read<GoogleDriveLogic>();
    const textStyle = TextStyle(fontSize: 16.0, fontWeight: FontWeight.w400);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('On your desktop visit', style: textStyle),
          const SizedBox(height: 12.0),
          Text(
            'https://narro.innomatic.ca',
            style: TextStyle(color: Theme.of(context).colorScheme.tertiary),
          ),
          const SizedBox(height: 12.0),
          const Text('to upload documents', style: textStyle),
          const SizedBox(height: 36.0),
          OutlinedButton(
            child: const Text('Then tap here to refresh'),
            onPressed: () => gdrive.refresh(),
          ),
        ],
      ),
    );
  }
}
