import 'package:flutter/material.dart';

class AIMeetingSummaryPage extends StatelessWidget {
  const AIMeetingSummaryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Meeting Summary'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: const Color(0xFF2D2D2D),
      ),
      body: const Center(
        child: Text('AI Meeting Summary Coming Soon'),
      ),
    );
  }
}
