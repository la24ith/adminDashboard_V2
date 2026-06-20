// lib/features/posts/presentation/widgets/audio_recorder_widget.dart
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
//import 'package:record/record.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
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

class _AudioRecorderWidgetState extends State<AudioRecorderWidget> {
  // final AudioRecorder _recorder = AudioRecorder();
  var _recorder; // Assuming you have a recorder instance from a package like 'record'
  final AudioPlayer _player = AudioPlayer();

  String? _currentPath;
  bool _isRecording = false;
  bool _isPlaying = false;
  int _recordDuration = 0;
  Duration _playbackPosition = Duration.zero;
  Duration _playbackDuration = Duration.zero;
  Timer? _recordTimer;
  Timer? _playbackTimer;
  String? _errorMessage;

  // مستويات الصوت للتسجيل
  final List<double> _amplitudes = [];
  Timer? _amplitudeTimer;

  @override
  void initState() {
    super.initState();
    _initRecorder();

    if (widget.existingFile != null) {
      _currentPath = widget.existingFile!.path;
      _loadAudioFile(_currentPath!);
    } else if (widget.existingUrl != null && widget.existingUrl!.isNotEmpty) {
      // إذا كان هناك رابط موجود، نعرضه كملف تم رفعه مسبقاً
      _currentPath = widget.existingUrl;
    }
  }

  Future<void> _initRecorder() async {
    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission && mounted) {
      setState(() {
        _errorMessage = 'الرجاء السماح بالوصول إلى الميكروفون';
      });
    }
  }

  Future<void> _startRecording() async {
    // إعادة التحقق من الإذن
    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('الرجاء السماح بالوصول إلى الميكروفون لتسجيل الصوت'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    // الحصول على مسار مؤقت للملف
    final dir = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    _currentPath = '${dir.path}/audio_$timestamp.m4a';

    try {
      // بدء التسجيل
      /*  await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          sampleRate: 44100,
          bitRate: 128000,
        ),
        path: _currentPath!,
      );*/

      setState(() {
        _isRecording = true;
        _recordDuration = 0;
        _errorMessage = null;
        _amplitudes.clear();
      });

      // بدء مؤقت التسجيل
      _recordTimer?.cancel();
      _recordTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_isRecording && mounted) {
          setState(() => _recordDuration++);
        }
      });

      // بدء قراءة مستويات الصوت
      _amplitudeTimer?.cancel();
      _amplitudeTimer =
          Timer.periodic(const Duration(milliseconds: 100), (timer) async {
        if (_isRecording && mounted) {
          final amplitude = await _recorder.getAmplitude();
          _amplitudes.add(amplitude.current);
          if (_amplitudes.length > 100) {
            _amplitudes.removeAt(0);
          }
          if (mounted) setState(() {});
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'فشل بدء التسجيل: ${e.toString()}';
      });
    }
  }

  Future<void> _stopRecording() async {
    try {
      final path = await _recorder.stop();
      _recordTimer?.cancel();
      _amplitudeTimer?.cancel();

      if (path != null && await File(path).exists()) {
        _currentPath = path;
        await _loadAudioFile(path);

        setState(() {
          _isRecording = false;
          _errorMessage = null;
        });

        // تمرير الملف إلى الوالد
        final audioFile = File(path);
        widget.onAudioChanged(audioFile, null);
      } else {
        setState(() {
          _isRecording = false;
          _errorMessage = 'فشل حفظ التسجيل';
        });
      }
    } catch (e) {
      setState(() {
        _isRecording = false;
        _errorMessage = 'خطأ في إيقاف التسجيل: ${e.toString()}';
      });
    }
  }

  Future<void> _cancelRecording() async {
    try {
      await _recorder.cancel();
      _recordTimer?.cancel();
      _amplitudeTimer?.cancel();

      // حذف الملف المؤقت إذا وجد
      if (_currentPath != null && await File(_currentPath!).exists()) {
        await File(_currentPath!).delete();
      }

      setState(() {
        _isRecording = false;
        _currentPath = null;
        _recordDuration = 0;
        _amplitudes.clear();
      });
    } catch (e) {
      debugPrint('Error cancelling recording: $e');
      setState(() {
        _isRecording = false;
      });
    }
  }

  Future<void> _loadAudioFile(String path) async {
    try {
      await _player.setFilePath(path);
      _playbackDuration = _player.duration ?? Duration.zero;

      // الاستماع لتغيرات حالة التشغيل
      _player.playbackEventStream.listen((event) {
        if (mounted) {
          setState(() {
            _playbackDuration = _player.duration ?? Duration.zero;
          });
        }
      });

      setState(() {});
    } catch (e) {
      setState(() {
        _errorMessage = 'خطأ في تحميل الملف الصوتي';
      });
    }
  }

  void _togglePlayback() {
    if (_isPlaying) {
      _player.pause();
      _playbackTimer?.cancel();
      setState(() => _isPlaying = false);
    } else {
      _player.play();
      setState(() => _isPlaying = true);

      // تحديث موضع التشغيل
      _playbackTimer?.cancel();
      _playbackTimer =
          Timer.periodic(const Duration(milliseconds: 100), (timer) {
        if (mounted && _player.playing) {
          setState(() {
            _playbackPosition = _player.position;
          });

          // إذا انتهى التشغيل
          if (_player.position >= (_player.duration ?? Duration.zero)) {
            timer.cancel();
            setState(() => _isPlaying = false);
          }
        }
      });
    }
  }

  Future<void> _seekTo(double value) async {
    final duration = _playbackDuration;
    if (duration.inMilliseconds > 0) {
      final position =
          Duration(milliseconds: (duration.inMilliseconds * value).round());
      await _player.seek(position);
      setState(() {
        _playbackPosition = position;
      });
    }
  }

  Future<void> _deleteAudio() async {
    // إيقاف التشغيل إذا كان قيد التشغيل
    if (_isPlaying) {
      await _player.stop();
      _playbackTimer?.cancel();
    }

    // حذف الملف المحلي
    if (_currentPath != null && _currentPath!.contains('/')) {
      final file = File(_currentPath!);
      if (await file.exists()) {
        await file.delete();
      }
    }

    setState(() {
      _currentPath = null;
      _isRecording = false;
      _isPlaying = false;
      _recordDuration = 0;
      _playbackPosition = Duration.zero;
      _playbackDuration = Duration.zero;
      _amplitudes.clear();
      _errorMessage = null;
    });

    widget.onAudioChanged(null, null);
  }

  Future<void> _reRecord() async {
    await _deleteAudio();
    await _startRecording();
  }

  String _formatDuration(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final remainingSeconds = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$remainingSeconds';
  }

  String _formatPlaybackDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Widget _buildWaveform() {
    if (_amplitudes.isEmpty) {
      return Container(
        height: 50,
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Text(
            '⌛ جاري التسجيل...',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ),
      );
    }

    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: List.generate(
          _amplitudes.length.clamp(0, 60),
          (index) {
            final amplitude = _amplitudes[_amplitudes.length - 1 - index];
            final height = (amplitude * 40).clamp(5.0, 40.0);
            return Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 1.5),
                height: height,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      AppColors.primary,
                      AppColors.primary.withOpacity(0.6),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasAudio = _currentPath != null && _currentPath!.isNotEmpty;
    final isUploading = widget.isUploading;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(Icons.mic, color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'تسجيل صوتي',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (hasAudio && !isUploading)
                        Text(
                          'ملف صوتي مرفق',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.primary,
                          ),
                        ),
                    ],
                  ),
                ),
                if (isUploading)
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      value: widget.uploadProgress,
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(AppColors.primary),
                    ),
                  ),
                if (hasAudio && !isUploading)
                  GestureDetector(
                    onTap: _deleteAudio,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.delete_outline,
                          size: 18, color: Colors.red.shade400),
                    ),
                  ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (widget.isUploading) {
      return _buildUploadProgress();
    }

    if (_isRecording) {
      return _buildRecordingUI();
    }

    if (_currentPath != null && _currentPath!.isNotEmpty) {
      return _buildPlaybackUI();
    }

    return _buildIdleUI();
  }

  Widget _buildUploadProgress() {
    return Column(
      children: [
        LinearProgressIndicator(
          value: widget.uploadProgress,
          backgroundColor: Colors.grey.shade200,
          valueColor: AlwaysStoppedAnimation(AppColors.primary),
          borderRadius: BorderRadius.circular(10),
          minHeight: 6,
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(AppColors.primary),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'جاري رفع الملف الصوتي ${(widget.uploadProgress * 100).toInt()}%',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRecordingUI() {
    return Column(
      children: [
        // مؤقت التسجيل
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                _formatDuration(_recordDuration),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // شكل الموجة
        _buildWaveform(),

        const SizedBox(height: 16),

        // أزرار التحكم
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildControlButton(
              icon: Icons.close,
              onTap: _cancelRecording,
              color: Colors.grey,
            ),
            const SizedBox(width: 40),
            _buildControlButton(
              icon: Icons.stop,
              onTap: _stopRecording,
              color: Colors.red,
              isMain: true,
            ),
          ],
        ),

        if (_errorMessage != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
      ],
    );
  }

  Widget _buildPlaybackUI() {
    return Column(
      children: [
        // شريط التقدم
        Column(
          children: [
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 4,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
              ),
              child: Slider(
                value: _playbackDuration.inMilliseconds > 0
                    ? (_playbackPosition.inMilliseconds /
                            _playbackDuration.inMilliseconds)
                        .clamp(0.0, 1.0)
                    : 0.0,
                onChanged: (value) => _seekTo(value),
                activeColor: AppColors.primary,
                inactiveColor: Colors.grey.shade300,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  Text(
                    _formatPlaybackDuration(_playbackPosition),
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const Spacer(),
                  Text(
                    _formatPlaybackDuration(_playbackDuration),
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // أزرار التحكم
        Wrap(
          spacing: 24,
          runSpacing: 12,
          alignment: WrapAlignment.center,
          children: [
            // زر إعادة التسجيل
            _buildControlButton(
              icon: Icons.refresh,
              onTap: _reRecord,
              color: Colors.orange,
            ),

            // زر التشغيل/الإيقاف
            _buildControlButton(
              icon: _isPlaying ? Icons.pause : Icons.play_arrow,
              onTap: _togglePlayback,
              color: AppColors.primary,
              isMain: true,
            ),

            // زر الحذف
            _buildControlButton(
              icon: Icons.delete_outline,
              onTap: _deleteAudio,
              color: Colors.red,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildIdleUI() {
    return Center(
      child: Column(
        children: [
          ElevatedButton.icon(
            onPressed: _startRecording,
            icon: const Icon(Icons.mic, size: 20),
            label: const Text('اضغط للتسجيل'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(40),
              ),
              elevation: 0,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'سجل مقطعاً صوتياً لإضافته إلى المنشور',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
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
        duration: const Duration(milliseconds: 150),
        padding: EdgeInsets.all(isMain ? 14 : 10),
        decoration: BoxDecoration(
          color: isMain ? color : color.withOpacity(0.1),
          shape: BoxShape.circle,
          boxShadow: isMain
              ? [BoxShadow(color: color.withOpacity(0.3), blurRadius: 12)]
              : null,
        ),
        child: Icon(
          icon,
          size: isMain ? 28 : 20,
          color: isMain ? Colors.white : color,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _recordTimer?.cancel();
    _playbackTimer?.cancel();
    _amplitudeTimer?.cancel();
    _recorder.dispose();
    _player.dispose();
    super.dispose();
  }
}
