import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import '../../data/media_service.dart';
import '../../../explorer/models/file_item.dart';

class VideoViewer extends ConsumerStatefulWidget {
  final FileItem item;

  const VideoViewer({super.key, required this.item});

  @override
  ConsumerState<VideoViewer> createState() => _VideoViewerState();
}

class _VideoViewerState extends ConsumerState<VideoViewer> {
  VideoPlayerController? _controller;
  bool _isError = false;
  double _playbackSpeed = 1.0;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    final mediaService = ref.read(mediaServiceProvider);
    try {
      final url = await mediaService.getMediaUrl(widget.item.relativePath, 'video');
      final headers = await mediaService.getAuthHeaders();
      
      _controller = VideoPlayerController.networkUrl(
        Uri.parse(url),
        httpHeaders: headers,
      );
      
      await _controller!.initialize();
      setState(() {});
      _controller!.play();
    } catch (e) {
      setState(() => _isError = true);
    }
  }

  void _handleDoubleTap(TapDownDetails details, BoxConstraints constraints) {
    if (_controller == null) return;
    
    final width = constraints.maxWidth;
    final position = details.localPosition.dx;
    final currentPos = _controller!.value.position;
    
    if (position < width / 2) {
      // Rewind 10s
      final newPos = currentPos - const Duration(seconds: 10);
      _controller!.seekTo(newPos < Duration.zero ? Duration.zero : newPos);
    } else {
      // Forward 10s
      final newPos = currentPos + const Duration(seconds: 10);
      _controller!.seekTo(newPos);
    }
  }

  void _cyclePlaybackSpeed() {
    if (_controller == null) return;
    
    setState(() {
      if (_playbackSpeed == 1.0) {
        _playbackSpeed = 1.5;
      } else if (_playbackSpeed == 1.5) {
        _playbackSpeed = 2.0;
      } else {
        _playbackSpeed = 1.0;
      }
    });
    _controller!.setPlaybackSpeed(_playbackSpeed);
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isError) {
      return const Center(
        child: Text('Không thể phát video này', style: TextStyle(color: Colors.red)),
      );
    }
    
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }
    
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          alignment: Alignment.center,
          children: [
            GestureDetector(
              onDoubleTapDown: (details) => _handleDoubleTap(details, constraints),
              onTap: () {
                setState(() {
                  _controller!.value.isPlaying ? _controller!.pause() : _controller!.play();
                });
              },
              child: Container(
                color: Colors.transparent,
                alignment: Alignment.center,
                child: AspectRatio(
                  aspectRatio: _controller!.value.aspectRatio,
                  child: VideoPlayer(_controller!),
                ),
              ),
            ),
            // Play/Pause icon indicator
            if (!_controller!.value.isPlaying)
              IgnorePointer(
                child: const Icon(Icons.play_arrow, size: 64, color: Colors.white70),
              ),
            // Playback speed button
            Positioned(
              top: 16,
              right: 16,
              child: Material(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(20),
                child: InkWell(
                  onTap: _cyclePlaybackSpeed,
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: Text(
                      '${_playbackSpeed}x',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ),
            // Simple progress bar
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: VideoProgressIndicator(
                _controller!,
                allowScrubbing: true,
                colors: const VideoProgressColors(
                  playedColor: Colors.blue,
                  bufferedColor: Colors.white24,
                  backgroundColor: Colors.white12,
                ),
              ),
            ),
          ],
        );
      }
    );
  }
}
