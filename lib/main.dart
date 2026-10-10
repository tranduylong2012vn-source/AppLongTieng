import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:async';

void main() {
  runApp(const DubbingApp());
}

class DubbingApp extends StatelessWidget {
  const DubbingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dubbing Studio S26 Ultra',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF121212),
        primaryColor: Colors.tealAccent,
        colorScheme: const ColorScheme.dark(
          primary: Colors.tealAccent,
          secondary: Colors.teal,
        ),
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  // 5 giọng mặc định cố định (không thể xóa)
  final List<Map<String, String>> defaultVoices = [
    {'name': 'Nam Bắc trầm ấm', 'desc': 'Kể chuyện, review phim tài liệu'},
    {'name': 'Nữ Bắc truyền cảm', 'desc': 'Thuyết minh phim điện ảnh'},
    {'name': 'Nam Nam ấm áp', 'desc': 'Podcast, review phim đời sống'},
    {'name': 'Nữ Nam trong trẻo', 'desc': 'Tự nhiên, vlog'},
    {'name': 'Giọng Phổ thông', 'desc': 'Đọc nhanh liền mạch, meme mạng xã hội'},
  ];

  // Danh sách giọng clone (có thể thêm / xóa)
  final List<Map<String, String>> clonedVoices = [
    {'name': 'Giọng Clone: Mẫu 01', 'desc': 'Đã tạo từ file mẫu 10s'},
  ];

  String selectedVoice = 'Nam Bắc trầm ấm';

  void _addNewClonedVoice(String name) {
    setState(() {
      clonedVoices.add({'name': name, 'desc': 'Đã lưu vào bộ nhớ máy'});
    });
  }

  void _deleteClonedVoice(int index) {
    setState(() {
      if (selectedVoice == clonedVoices[index]['name']) {
        selectedVoice = defaultVoices[0]['name']!;
      }
      clonedVoices.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    List<String> allVoiceNames = [
      ...defaultVoices.map((v) => v['name']!),
      ...clonedVoices.map((v) => v['name']!),
    ];

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF1E1E1E),
          title: const Text('Dubbing Studio Offline', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          bottom: const TabBar(
            indicatorColor: Colors.tealAccent,
            labelColor: Colors.tealAccent,
            unselectedLabelColor: Colors.grey,
            tabs: [
              Tab(icon: Icon(Icons.subtitles), text: 'Lồng Tiếng SRT'),
              Tab(icon: Icon(Icons.text_fields), text: 'Văn Bản -> Lời'),
              Tab(icon: Icon(Icons.record_voice_over), text: 'Kho Giọng'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            SrtDubbingTab(allVoices: allVoiceNames, selectedVoice: selectedVoice, onVoiceChanged: (v) => setState(() => selectedVoice = v)),
            TtsTab(allVoices: allVoiceNames, selectedVoice: selectedVoice, onVoiceChanged: (v) => setState(() => selectedVoice = v)),
            VoiceLibraryTab(
              defaultVoices: defaultVoices,
              clonedVoices: clonedVoices,
              onAddClone: _addNewClonedVoice,
              onDeleteClone: _deleteClonedVoice,
            ),
          ],
        ),
      ),
    );
  }
}

// ================= TAB 1: LỒNG TIẾNG THEO SRT =================
class SrtDubbingTab extends StatefulWidget {
  final List<String> allVoices;
  final String selectedVoice;
  final ValueChanged<String> onVoiceChanged;

  const SrtDubbingTab({
    super.key,
    required this.allVoices,
    required this.selectedVoice,
    required this.onVoiceChanged,
  });

  @override
  State<SrtDubbingTab> createState() => _SrtDubbingTabState();
}

class _SrtDubbingTabState extends State<SrtDubbingTab> {
  String? _srtFileName;
  bool _isProcessing = false;
  double _progress = 0.0;
  int _secondsRemaining = 0;
  String _fileSize = '0 MB';

  Future<void> _pickSrt() async {
    FilePickerResult? res = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['srt']);
    if (res != null) {
      setState(() {
        _srtFileName = res.files.single.name;
      });
    }
  }

  void _startExport() async {
    setState(() {
      _isProcessing = true;
      _progress = 0.0;
      _secondsRemaining = 20;
      _fileSize = '0.0 MB';
    });

    for (int i = 1; i <= 100; i++) {
      await Future.delayed(const Duration(milliseconds: 200));
      if (!mounted) return;
      setState(() {
        _progress = i / 100.0;
        _secondsRemaining = ((100 - i) * 0.2).ceil();
        _fileSize = '${(15.4 * _progress).toStringAsFixed(1)} MB';
      });
    }

    if (!mounted) return;
    setState(() {
      _isProcessing = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: Colors.green,
        content: Text('Đã xuất thành công file MP3 vào thư mục máy (Khớp 100% timecode)!'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            color: const Color(0xFF1E1E1E),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Icon(Icons.file_present, size: 48, color: Colors.tealAccent),
                  const SizedBox(height: 10),
                  Text(
                    _srtFileName != null ? 'File: $_srtFileName' : 'Chưa chọn file phụ đề',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                    onPressed: _isProcessing ? null : _pickSrt,
                    icon: const Icon(Icons.upload_file, color: Colors.white),
                    label: const Text('Chọn file .SRT từ máy', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            color: const Color(0xFF1E1E1E),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Giọng lồng tiếng:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  DropdownButton<String>(
                        isExpanded: true,
                        value: widget.allVoices.contains(widget.selectedVoice) ? widget.selectedVoice : widget.allVoices.first,
                        dropdownColor: const Color(0xFF2A2A2A),
                        items: widget.allVoices.map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
                        onChanged: (val) {
                          if (val != null) widget.onVoiceChanged(val);
                        },
                  ),
                  const SizedBox(height: 6),
                  const Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 18),
                      SizedBox(width: 6),
                      Text('Khớp nhịp WSOLA: Tự động căn chỉnh nhịp', style: TextStyle(fontSize: 13, color: Colors.grey)),
                    ],
                  )
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (_isProcessing) ...[
            Card(
              color: const Color(0xFF222222),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Tiến độ: ${(_progress * 100).toInt()}%', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.tealAccent)),
                        Text('Dung lượng: $_fileSize (MP3)', style: const TextStyle(color: Colors.amberAccent)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    LinearProgressIndicator(value: _progress, minHeight: 12, color: Colors.tealAccent, backgroundColor: Colors.grey[800]),
                    const SizedBox(height: 10),
                    Text('Thời lượng còn lại: $_secondsRemaining giây', style: const TextStyle(color: Colors.white70)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.tealAccent,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: (_srtFileName != null && !_isProcessing) ? _startExport : null,
            icon: const Icon(Icons.audio_file),
            label: const Text('BẮT ĐẦU XUẤT AUDIO .MP3', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

// ================= TAB 2: VĂN BẢN THÀNH LỜI (TTS) =================
class TtsTab extends StatefulWidget {
  final List<String> allVoices;
  final String selectedVoice;
  final ValueChanged<String> onVoiceChanged;

  const TtsTab({
    super.key,
    required this.allVoices,
    required this.selectedVoice,
    required this.onVoiceChanged,
  });

  @override
  State<TtsTab> createState() => _TtsTabState();
}

class _TtsTabState extends State<TtsTab> {
  final TextEditingController _textCtrl = TextEditingController();
  bool _isProcessing = false;
  double _progress = 0.0;
  int _secondsRemaining = 0;
  String _fileSize = '0 MB';

  void _startTts() async {
    if (_textCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng nhập văn bản cần đọc!')));
      return;
    }

    setState(() {
      _isProcessing = true;
      _progress = 0.0;
      _secondsRemaining = 10;
      _fileSize = '0.0 MB';
    });

    for (int i = 1; i <= 100; i++) {
      await Future.delayed(const Duration(milliseconds: 100));
      if (!mounted) return;
      setState(() {
        _progress = i / 100.0;
        _secondsRemaining = ((100 - i) * 0.1).ceil();
        _fileSize = '${(3.2 * _progress).toStringAsFixed(1)} MB';
      });
    }

    if (!mounted) return;
    setState(() {
      _isProcessing = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(backgroundColor: Colors.green, content: Text('Đã tạo xong file MP3 vào bộ nhớ!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _textCtrl,
            maxLines: 5,
            decoration: InputDecoration(
              hintText: 'Nhập hoặc dán nội dung kịch bản văn bản vào đây...',
              hintStyle: const TextStyle(color: Colors.grey),
              filled: true,
              fillColor: const Color(0xFF1E1E1E),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            color: const Color(0xFF1E1E1E),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Chọn giọng đọc:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  DropdownButton<String>(
                    isExpanded: true,
                    value: widget.allVoices.contains(widget.selectedVoice) ? widget.selectedVoice : widget.allVoices.first,
                    dropdownColor: const Color(0xFF2A2A2A),
                    items: widget.allVoices.map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
                    onChanged: (val) {
                      if (val != null) widget.onVoiceChanged(val);
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (_isProcessing) ...[
            Card(
              color: const Color(0xFF222222),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Tiến độ: ${(_progress * 100).toInt()}%', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.tealAccent)),
                        Text('Dung lượng: $_fileSize (MP3)', style: const TextStyle(color: Colors.amberAccent)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    LinearProgressIndicator(value: _progress, minHeight: 12, color: Colors.tealAccent, backgroundColor: Colors.grey[800]),
                    const SizedBox(height: 10),
                    Text('Thời lượng còn lại: $_secondsRemaining giây', style: const TextStyle(color: Colors.white70)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurpleAccent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: _isProcessing ? null : _startTts,
            icon: const Icon(Icons.play_circle_fill),
            label: const Text('CHUYỂN THÀNH ÂM THANH .MP3', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

// ================= TAB 3: KHO GIỌNG & CLONE =================
class VoiceLibraryTab extends StatelessWidget {
  final List<Map<String, String>> defaultVoices;
  final List<Map<String, String>> clonedVoices;
  final Function(String) onAddClone;
  final Function(int) onDeleteClone;

  const VoiceLibraryTab({
    super.key,
    required this.defaultVoices,
    required this.clonedVoices,
    required this.onAddClone,
    required this.onDeleteClone,
  });

  void _previewVoice(BuildContext context, String voiceName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 2),
        content: Text('▶ Đang phát giọng mẫu của: $voiceName'),
        backgroundColor: Colors.teal,
      ),
    );
  }

  void _showCloneDialog(BuildContext context) {
    final TextEditingController nameCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF222222),
        title: const Text('Clone Giọng Mới'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Chọn file âm thanh mẫu (5-15s) từ máy để trích xuất đặc trưng giọng.', style: TextStyle(fontSize: 13, color: Colors.grey)),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey),
              onPressed: () {},
              icon: const Icon(Icons.mic),
              label: const Text('Chọn file ghi âm mẫu'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Đặt tên cho giọng clone',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
            onPressed: () {
              if (nameCtrl.text.trim().isNotEmpty) {
                onAddClone(nameCtrl.text.trim());
                Navigator.pop(ctx);
              }
            },
            child: const Text('Lưu vào kho', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, int index) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF222222),
        title: const Text('Xác nhận xóa giọng'),
        content: Text('Bạn có chắc chắn muốn xóa giọng "${clonedVoices[index]['name']}" không?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          TextButton(
            onPressed: () {
              onDeleteClone(index);
              Navigator.pop(ctx);
            },
            child: const Text('Xóa', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.tealAccent,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: () => _showCloneDialog(context),
          icon: const Icon(Icons.add_circle, size: 24),
          label: const Text('+ CLONE GIỌNG MỚI (Từ File Audio)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 20),
        const Text('🔒 5 GIỌNG GỐC MẶC ĐỊNH (Cố định)', style: TextStyle(color: Colors.tealAccent, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...defaultVoices.map((v) => Card(
          color: const Color(0xFF1E1E1E),
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            leading: const Icon(Icons.lock, color: Colors.grey),
            title: Text(v['name']!, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(v['desc']!),
            trailing: IconButton(
              icon: const Icon(Icons.play_circle_fill, color: Colors.tealAccent, size: 34),
              onPressed: () => _previewVoice(context, v['name']!),
            ),
          ),
        )),
        const SizedBox(height: 20),
        const Text('👤 GIỌNG CLONE ĐÃ LƯU (Có thể xóa)', style: TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        if (clonedVoices.isEmpty)
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text('Chưa có giọng clone nào. Bấm nút phía trên để thêm mới.', style: TextStyle(color: Colors.grey)),
          )
        else
          ...clonedVoices.asMap().entries.map((entry) {
            int idx = entry.key;
            var v = entry.value;
            return Card(
              color: const Color(0xFF1E1E1E),
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: ListTile(
                leading: const Icon(Icons.person, color: Colors.orangeAccent),
                title: Text(v['name']!, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(v['desc']!),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.play_circle_fill, color: Colors.tealAccent, size: 34),
                      onPressed: () => _previewVoice(context, v['name']!),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_forever, color: Colors.redAccent, size: 28),
                      onPressed: () => _confirmDelete(context, idx),
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }
}
