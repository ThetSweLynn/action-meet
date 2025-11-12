// import 'package:flutter/material.dart';

// class AIMeetingSummaryPage extends StatelessWidget {
//   const AIMeetingSummaryPage({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('AI Meeting Summary'),
//         backgroundColor: Colors.transparent,
//         elevation: 0,
//         foregroundColor: const Color(0xFF2D2D2D),
//       ),
//       body: const Center(
//         child: Text('AI Meeting Summary Coming Soon'),
//       ),
//     );
//   }
// }


import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';

class AIMeetingSummaryPage extends StatefulWidget {
  const AIMeetingSummaryPage({super.key});

  @override
  State<AIMeetingSummaryPage> createState() => _AIMeetingSummaryPageState();
}

class _AIMeetingSummaryPageState extends State<AIMeetingSummaryPage> {
  bool _isLoading = false;
  String? _summary;
  String? _transcript;

  Future<void> uploadAudio() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp3', 'wav', 'm4a'],
    );

    if (result == null) return;

    setState(() {
      _isLoading = true;
      _summary = null;
      _transcript = null;
    });

    final file = File(result.files.single.path!);
    final uri = Uri.parse('http://10.0.2.2:8000/summarize-audio');

    final request = http.MultipartRequest('POST', uri)
      ..files.add(await http.MultipartFile.fromPath('file', file.path));

    final response = await request.send();

    if (response.statusCode == 200) {
      final body = await response.stream.bytesToString();
      final data = json.decode(body);
      setState(() {
        _summary = data['summary'];
        _transcript = data['transcript'];
      });
    } else {
      setState(() {
        _summary = "Failed to summarize audio. Please try again.";
      });
    }

    setState(() => _isLoading = false);
  }

  Widget buildSectionCard(String title, String? content) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(content ?? '-', style: const TextStyle(fontSize: 15)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Meeting Summary'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: const Color(0xFF2D2D2D),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.upload),
              label: const Text('Upload Audio'),
              onPressed: _isLoading ? null : uploadAudio,
            ),
            const SizedBox(height: 24),

            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_summary != null)
              Expanded(
                child: ListView(
                  children: [
                    buildSectionCard("🧠 Summary", _summary),
                    buildSectionCard("🗒 Transcript", _transcript),
                  ],
                ),
              )
            else
              const Text('Upload an audio file to get the AI-generated summary.'),
          ],
        ),
      ),
    );
  }
}
