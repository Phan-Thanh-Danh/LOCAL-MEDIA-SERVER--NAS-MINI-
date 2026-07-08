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
    
    return Stack(
      alignment: Alignment.center,
      children: [
        AspectRatio(
          aspectRatio: _controller!.value.aspectRatio,
          child: VideoPlayer(_controller!),
        ),
        // Simple play/pause overlay
        GestureDetector(
          onTap: () {
            setState(() {
              _controller!.value.isPlaying ? _controller!.pause() : _controller!.play();
            });
          },
          child: Container(
            color: Colors.transparent,
            alignment: Alignment.center,
            child: !_controller!.value.isPlaying
                ? const Icon(Icons.play_arrow, size: 64, color: Colors.white70)
                : const SizedBox.shrink(),
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
}
