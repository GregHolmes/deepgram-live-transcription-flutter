import 'package:flutter/material.dart';
import 'dart:async';
import 'package:record/record.dart';
import 'package:deepgram_speech_to_text/deepgram_speech_to_text.dart';

// You should not commit your Deepgram API key.
// We're using apiKey here for simplicity and tutorial purposes.
// This should be received from a secure backend in production applications.
const apiKey = '<Your Deepgram API key>';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Deepgram Live Transcription',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Deepgram Live Transcription'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String myText = "To start transcribing your voice, press start.";
  bool _isRecording = false;

  final AudioRecorder _recorder = AudioRecorder();
  final Deepgram _deepgram = Deepgram(apiKey);

  StreamSubscription? _transcriptionSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(onLayoutDone);
  }

  @override
  void dispose() {
    _transcriptionSub?.cancel();
    _recorder.stop();
    _recorder.dispose();
    super.dispose();
  }

  void _startRecord() async {
    if (_isRecording) return;

    resetText();

    final audioStream = await _recorder.startStream(
      const RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: 16000,
        numChannels: 1,
      ),
    );

    final resultStream = _deepgram.listen.live(
      audioStream,
      queryParams: {
        'language': 'en',
        'encoding': 'linear16',
        'sample_rate': 16000,
      },
    );

    _transcriptionSub = resultStream.listen((result) {
      final transcript = result.transcript ?? '';
      if (transcript.isNotEmpty) {
        updateText(transcript);
      }
    });

    setState(() {
      _isRecording = true;
    });
  }

  void _stopRecord() async {
    await _recorder.stop();
    await _transcriptionSub?.cancel();
    _transcriptionSub = null;

    setState(() {
      _isRecording = false;
    });
  }

  void onLayoutDone(Duration timeStamp) async {
    await _recorder.hasPermission();
    setState(() {});
  }

  void updateText(String newText) {
    setState(() {
      myText = '$myText $newText';
    });
  }

  void resetText() {
    setState(() {
      myText = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Transcription with Deepgram'),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Row(
            children: <Widget>[
              Expanded(
                flex: 3,
                child: SizedBox(
                  width: 150,
                  child: Text(
                    myText,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 50,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                OutlinedButton(
                  style: ButtonStyle(
                    backgroundColor:
                        WidgetStateProperty.all<Color>(Colors.blue),
                    foregroundColor:
                        WidgetStateProperty.all<Color>(Colors.white),
                  ),
                  onPressed: _isRecording ? null : () => _startRecord(),
                  child: const Text('Start', style: TextStyle(fontSize: 30)),
                ),
                const SizedBox(width: 5),
                OutlinedButton(
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.all<Color>(Colors.red),
                    foregroundColor:
                        WidgetStateProperty.all<Color>(Colors.white),
                  ),
                  onPressed: _isRecording ? () => _stopRecord() : null,
                  child: const Text('Stop', style: TextStyle(fontSize: 30)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
