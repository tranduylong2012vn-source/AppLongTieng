import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:ffmpeg_kit_flutter_full/ffmpeg_kit.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa;
import 'dart:io';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const DubbingApp());
}

class DubbingApp extends StatelessWidget {
  const DubbingApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dubbing Studio Thực Tế',
      theme: ThemeData.dark().copyWith(
        primaryColor: Colors.tealAccent,
        scaffoldBackgroundColor: const Color(0xFF121212),
      ),
      home: const RealDubbingScreen(),
    );
  }
}

class RealDubbingScreen extends StatefulWidget {
  const RealDubbingScreen({super.key});
  @override
  State<RealDubbingScreen> createState() => _RealDubbingScreenState();
}

class _RealDubbingScreenState extends State<RealDubbingScreen> {
  String _status = "Đang chờ...";
  bool _isReady = false;
  sherpa.OfflineTts? _ttsEngine;
  
  // Nơi chứa não AI trên điện thoại của bạn
  final String modelDirectory = "/storage/emulated/0/Download/DubbingAppModels";

  @override
  void initState() {
    super.initState();
    _requestPermissionsAndInit();
  }

  Future<void> _requestPermissionsAndInit() async {
    setState(() => _status = "Đang xin quyền bộ nhớ...");
    
    // Quyền cấp cao cho S26 Ultra (Android 14)
    if (await Permission.manageExternalStorage.request().isGranted || 
        await Permission.storage.request().isGranted) {
      
      setState(() => _status = "Đã có quyền. Đang tìm thư mục Mô Hình...");
      _initAIEngine();
    } else {
      setState(() => _status = "LỖI: Bạn chưa cấp quyền truy cập bộ nhớ!");
    }
  }

  void _initAIEngine() {
    final dir = Directory(modelDirectory);
    if (!dir.existsSync()) {
      setState(() {
        _status = "LỖI: Không tìm thấy thư mục $modelDirectory.\n\nHãy tạo thư mục này trong Download và chép các file .onnx vào đó!";
      });
      return;
    }

    try {
      // Cấu hình nhúng Sherpa-ONNX thực tế (VITS)
      sherpa.OfflineTtsConfig config = sherpa.OfflineTtsConfig(
        model: sherpa.OfflineTtsModelConfig(
          vits: sherpa.OfflineTtsVitsModelConfig(
            model: "$modelDirectory/vits-piper-vi.onnx",
            lexicon: "$modelDirectory/lexicon.txt",
            tokens: "$modelDirectory/tokens.txt",
            dataDir: "$modelDirectory/espeak-ng-data",
          ),
          numThreads: 4, // Tận dụng chip Snapdragon của S26
          debug: 1,
        ),
      );

      _ttsEngine = sherpa.OfflineTts(config: config);
      setState(() {
        _isReady = true;
        _status = "AI ĐÃ SẴN SÀNG CHẠY OFFLINE!";
      });
    } catch (e) {
      setState(() => _status = "Lỗi nạp mô hình: Chắc chắn bạn đã tải đúng file .onnx chưa?\nChi tiết: $e");
    }
  }

  Future<void> _testTTS() async {
    if (_ttsEngine == null) return;
    setState(() => _status = "Đang tạo âm thanh từ văn bản...");
    
    try {
      // Sinh âm thanh
      final audio = _ttsEngine!.generate(text: "Xin chào, đây là phần mềm lồng tiếng chạy nội bộ trên máy S 26 un tra.", sid: 0, speed: 1.0);
      
      final outputPath = "/storage/emulated/0/Download/test_voice.wav";
      bool success = sherpa.OfflineTts.write(audio: audio, filename: outputPath);
      
      if (success) {
        setState(() => _status = "THÀNH CÔNG: Đã lưu file tại $outputPath");
        // Dùng FFmpeg để convert sang MP3
        final mp3Path = "/storage/emulated/0/Download/test_voice.mp3";
        await FFmpegKit.execute('-y -i $outputPath -codec:a libmp3lame -qscale:a 2 $mp3Path');
        setState(() => _status = "THÀNH CÔNG: Đã xuất MP3 tại $mp3Path");
      }
    } catch (e) {
      setState(() => _status = "Lỗi tạo giọng: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Dubbing Engine (Bản thực tế)")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(15),
              color: _isReady ? Colors.green[900] : Colors.red[900],
              child: Text(
                _status, 
                style: const TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(20), backgroundColor: Colors.teal),
              onPressed: _isReady ? _testTTS : null,
              child: const Text("TẠO FILE ÂM THANH THỬ NGHIỆM", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 20),
            const Text(
              "HƯỚNG DẪN:\n"
              "1. Mở trình quản lý file trên S26 Ultra.\n"
              "2. Vào thư mục Download, tạo thư mục mới tên là 'DubbingAppModels'.\n"
              "3. Chép các file mô hình VITS tiếng Việt (đuôi .onnx, .txt) vào thư mục đó.\n"
              "4. Mở lại app này, app sẽ tự nạp mô hình vào RAM và sẵn sàng làm việc.",
              style: TextStyle(color: Colors.grey, fontSize: 14, height: 1.5),
            )
          ],
        ),
      ),
    );
  }
}
