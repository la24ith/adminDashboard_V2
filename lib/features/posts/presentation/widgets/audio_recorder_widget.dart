// lib/features/posts/presentation/widgets/audio_recorder_widget.dart
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:just_audio/just_audio.dart' as just_audio;
import 'package:path_provider/path_provider.dart';
import 'package:audio_waveforms/audio_waveforms.dart';
import '../../../../core/constants/app_colors.dart';

class AudioRecorderWidget extends StatefulWidget {
  final File? existingFile;
  final String? existingUrl;
  final Function(File?, String?) onAudioChanged;
  final bool isUploading;
  final double uploadProgress;

  const AudioRecorderWidget({
    super.key,
    this.existingFile,
    this.existingUrl,
    required this.onAudioChanged,
    this.isUploading = false,
    this.uploadProgress = 0,
  });

  @override
  State<AudioRecorderWidget> createState() => _AudioRecorderWidgetState();
}

class _AudioRecorderWidgetState extends State<AudioRecorderWidget>
    with TickerProviderStateMixin {
  final AudioRecorder _recorder = AudioRecorder();
  final just_audio.AudioPlayer _player = just_audio.AudioPlayer();
  late RecorderController _recorderController;
  late PlayerController _playerController;

  String? _currentPath;
  bool _isRecording = false;
  int _recordDuration = 0;
  Timer? _durationTimer;
  AudioMode _mode = AudioMode.idle;

  @override
  void initState() {
    super.initState();
    _recorderController = RecorderController();
    _playerController = PlayerController();

    if (widget.existingFile != null || widget.existingUrl != null) {
      _mode = AudioMode.playback;
      _currentPath = widget.existingFile?.path;
      if (_currentPath != null) {
        _loadAudioFile(_currentPath!);
      }
    }
  }

  Future<void> _startRecording() async {
    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('الرجاء السماح بالوصول إلى الميكروفون')),
        );
      }
      return;
    }

    final dir = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    // ✅ تأكد من الامتداد الصحيح
    _currentPath = '${dir.path}/audio_$timestamp.m4a';

    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        sampleRate: 44100,
        bitRate: 128000,
      ),
      path: _currentPath!,
    );

    setState(() {
      _isRecording = true;
      _mode = AudioMode.recording;
      _recordDuration = 0;
    });

    _startTimer();
    await _recorderController.record();
  }

  void _startTimer() {
    _durationTimer?.cancel();
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isRecording && mounted) {
        setState(() => _recordDuration++);
      }
    });
  }

  Future<void> _stopRecording() async {
    final path = await _recorder.stop();
    await _recorderController.stop();
    _durationTimer?.cancel();

    setState(() {
      _isRecording = false;
      _mode = AudioMode.playback;
    });

    if (path != null) {
      _currentPath = path;
      await _loadAudioFile(path);
      // ✅ تمرير الملف مع الامتداد الصحيح
      final audioFile = File(path);
      widget.onAudioChanged(audioFile, null);
    }
  }

  Future<void> _loadAudioFile(String path) async {
    try {
      await _player.setFilePath(path);
      await _playerController.preparePlayer(
        path: path,
        shouldExtractWaveform: true,
      );
      setState(() {});
    } catch (e) {
      debugPrint('Error loading audio: $e');
    }
  }

  Future<void> _deleteAudio() async {
    await _player.stop();
    if (_currentPath != null) {
      final file = File(_currentPath!);
      if (await file.exists()) {
        await file.delete();
      }
    }
    setState(() {
      _currentPath = null;
      _mode = AudioMode.idle;
      _recordDuration = 0;
    });
    widget.onAudioChanged(null, null);
  }

  Future<void> _reRecord() async {
    await _deleteAudio();
    await _startRecording();
  }

  Future<void> _seekTo(double position) async {
    final duration = _player.duration;
    if (duration != null) {
      final seekPosition = duration * position;
      await _player.seek(seekPosition);
    }
  }

  String _formatDuration(int seconds) {
    final min = (seconds ~/ 60).toString().padLeft(2, '0');
    final sec = (seconds % 60).toString().padLeft(2, '0');
    return '$min:$sec';
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final waveformWidth = screenWidth - 120; // ✅ تجنب overflow

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12)
        ],
      ),
      child: Column(
        children: [
          _buildHeader(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: _buildContent(waveformWidth),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.mic, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'تسجيل صوتي',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
            ),
          ),
          if (widget.isUploading)
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                value: widget.uploadProgress / 100,
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(AppColors.primary),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildContent(double waveformWidth) {
    if (_mode == AudioMode.recording) return _buildRecordingUI(waveformWidth);
    if (_mode == AudioMode.playback) return _buildPlaybackUI(waveformWidth);
    return _buildIdleUI();
  }

  Widget _buildRecordingUI(double waveformWidth) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                    color: Colors.red, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Text(
                _formatDuration(_recordDuration),
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.red),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 60,
          child: AudioWaveforms(
            size: Size(waveformWidth, 60),
            recorderController: _recorderController,
            waveStyle: const WaveStyle(
              waveColor: AppColors.primary,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildControlButton(
                icon: Icons.close, onTap: _deleteAudio, color: Colors.grey),
            const SizedBox(width: 40),
            _buildControlButton(
              icon: Icons.stop,
              onTap: _stopRecording,
              color: Colors.red,
              isMain: true,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPlaybackUI(double waveformWidth) {
    return Column(
      children: [
        GestureDetector(
          onTapDown: (details) {
            final box = context.findRenderObject() as RenderBox?;
            if (box == null) return;
            final position = details.localPosition;
            final seekPercent = (position.dx / waveformWidth).clamp(0.0, 1.0);
            _seekTo(seekPercent);
          },
          child: Column(
            children: [
              SizedBox(
                height: 60,
                child: AudioWaveforms(
                  size: Size(waveformWidth, 60),
                  recorderController: _recorderController,
                  waveStyle: const WaveStyle(
                    waveColor: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              StreamBuilder<Duration>(
                stream: _player.positionStream,
                builder: (context, snapshot) {
                  final position = snapshot.data ?? Duration.zero;
                  final total = _player.duration ?? Duration.zero;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Row(
                      children: [
                        Text(_formatDuration(position.inSeconds)),
                        const Expanded(child: SizedBox()),
                        Text(_formatDuration(total.inSeconds)),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 20,
          runSpacing: 12,
          alignment: WrapAlignment.center,
          children: [
            _buildSpeedButton(),
            _buildControlButton(
                icon: Icons.refresh, onTap: _reRecord, color: Colors.orange),
            StreamBuilder<just_audio.PlayerState>(
              stream: _player.playerStateStream,
              builder: (context, snapshot) {
                final isPlaying = snapshot.data?.playing ?? false;
                return _buildControlButton(
                  icon: isPlaying ? Icons.pause : Icons.play_arrow,
                  onTap: () async {
                    if (isPlaying) {
                      await _player.pause();
                      await _playerController.pausePlayer();
                    } else {
                      await _player.play();
                      await _playerController.startPlayer();
                    }
                    setState(() {});
                  },
                  color: AppColors.primary,
                  isMain: true,
                );
              },
            ),
            _buildControlButton(
                icon: Icons.delete_outline,
                onTap: _deleteAudio,
                color: Colors.red),
          ],
        ),
      ],
    );
  }

  Widget _buildIdleUI() {
    return Center(
      child: ElevatedButton.icon(
        onPressed: _startRecording,
        icon: const Icon(Icons.mic),
        label: const Text('اضغط للتسجيل'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        ),
      ),
    );
  }

  Widget _buildSpeedButton() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.speed, size: 16),
          const SizedBox(width: 4),
          DropdownButton<double>(
            value: _player.speed,
            underline: const SizedBox(),
            icon: const Icon(Icons.arrow_drop_down, size: 16),
            items: const [
              DropdownMenuItem(value: 0.5, child: Text('0.5x')),
              DropdownMenuItem(value: 0.75, child: Text('0.75x')),
              DropdownMenuItem(value: 1.0, child: Text('1x')),
              DropdownMenuItem(value: 1.25, child: Text('1.25x')),
              DropdownMenuItem(value: 1.5, child: Text('1.5x')),
              DropdownMenuItem(value: 2.0, child: Text('2x')),
            ],
            onChanged: (value) async {
              if (value != null) await _player.setSpeed(value);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onTap,
    required Color color,
    bool isMain = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.all(isMain ? 14 : 10),
        decoration: BoxDecoration(
          color: isMain ? color : color.withOpacity(0.1),
          shape: BoxShape.circle,
          boxShadow: isMain
              ? [BoxShadow(color: color.withOpacity(0.3), blurRadius: 12)]
              : null,
        ),
        child: Icon(icon,
            size: isMain ? 28 : 20, color: isMain ? Colors.white : color),
      ),
    );
  }

  @override
  void dispose() {
    _durationTimer?.cancel();
    _recorder.dispose();
    _player.dispose();
    _recorderController.dispose();
    _playerController.dispose();
    super.dispose();
  }
}

enum AudioMode { idle, recording, playback }
