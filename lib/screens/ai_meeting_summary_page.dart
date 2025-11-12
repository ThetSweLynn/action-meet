import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;

/// Singleton Store
class AIMeetingSummaryStore {
  static String? summary;
  static String? transcript;
  static String? fileName;
}

class AIMeetingSummaryPage extends StatefulWidget {
  const AIMeetingSummaryPage({super.key});

  @override
  State<AIMeetingSummaryPage> createState() => _AIMeetingSummaryPageState();
}

class _AIMeetingSummaryPageState extends State<AIMeetingSummaryPage>
    with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  String? _summary;
  String? _transcript;
  String? _currentFileName;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    _summary = AIMeetingSummaryStore.summary;
    _transcript = AIMeetingSummaryStore.transcript;
    _currentFileName = AIMeetingSummaryStore.fileName;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> uploadAudio() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp3', 'wav', 'm4a'],
    );

    if (result == null) return;

    final file = File(result.files.single.path!);
    final fileName = result.files.single.name;

    setState(() {
      _isLoading = true;
      _summary = null;
      _transcript = null;
      _currentFileName = fileName;
    });

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

        AIMeetingSummaryStore.summary = _summary;
        AIMeetingSummaryStore.transcript = _transcript;
        AIMeetingSummaryStore.fileName = _currentFileName;

        _tabController.animateTo(1);
      });
    } else {
      setState(() {
        _summary = "Failed to summarize audio. Please try again.";
        _transcript = null;
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
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
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
        leading: BackButton(),
        title: Row(
          children: [
            Text(
              "AI Meeting Summary",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 5),
            Icon(Icons.auto_awesome),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 30),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                labelColor: Colors.black87,
                unselectedLabelColor: Colors.grey.shade600,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 15,
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                tabs: const [
                  Tab(icon: Icon(Icons.upload_file), text: 'Upload'),
                  Tab(icon: Icon(Icons.article), text: 'Summary Result'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Upload Tab
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          icon: const Icon(Icons.upload),
                          label: const Text('Upload Audio'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2D2D2D),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              vertical: 16,
                              horizontal: 25,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          onPressed: _isLoading ? null : uploadAudio,
                        ),
                        const SizedBox(height: 16),

                        // Show current file name
                        if (_currentFileName != null)
                          Text(
                            'Current file: $_currentFileName',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),

                        const SizedBox(height: 24),
                        if (_isLoading)
                          const Center(child: CircularProgressIndicator())
                        else
                          const Text(
                            'Upload an audio file to get the AI-generated summary.',
                            textAlign: TextAlign.center,
                          ),
                      ],
                    ),
                  ),

                  // Summary Result Tab
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: _summary == null
                        ? const Center(child: Text('No summary available yet.'))
                        : ListView(
                            children: [
                              buildSectionCard("🧠 Summary", _summary),
                              buildSectionCard("🗒 Transcript", _transcript),
                            ],
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
