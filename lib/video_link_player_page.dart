import 'dart:async';

import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoLinkPlayerPage extends StatefulWidget {
  const VideoLinkPlayerPage({super.key});

  @override
  State<VideoLinkPlayerPage> createState() => _VideoLinkPlayerPageState();
}

class _VideoLinkPlayerPageState extends State<VideoLinkPlayerPage> {
  final TextEditingController _urlController = TextEditingController();

  VideoPlayerController? _videoController;
  ChewieController? _chewieController;

  Timer? _centerIconTimer;

  bool _isLoading = false;
  bool _showCenterIcon = false;
  bool _lastPlayingState = false;

  String? _errorMessage;

  @override
  void dispose() {
    _centerIconTimer?.cancel();
    _chewieController?.dispose();
    _videoController?.dispose();
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _playVideo() async {
    final url = _urlController.text.trim();

    if (url.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a video link.';
      });
      return;
    }

    final uri = Uri.tryParse(url);

    if (uri == null ||
        !uri.hasScheme ||
        (uri.scheme != 'http' && uri.scheme != 'https')) {
      setState(() {
        _errorMessage =
            'Please enter a valid http or https video link.';
      });
      return;
    }

    await _closeCurrentVideo();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final controller = VideoPlayerController.networkUrl(uri);

      _videoController = controller;

      await controller.initialize();

      if (!mounted) {
        await controller.dispose();
        return;
      }

      _lastPlayingState = false;

      controller.addListener(_videoListener);

      final chewieController = ChewieController(
        videoPlayerController: controller,
        autoPlay: true,
        looping: false,
        showControls: true,
        showPlayButton: false,
        allowFullScreen: true,
        allowMuting: true,
        allowPlaybackSpeedChanging: true,
        pauseOnBackgroundTap: true,
        materialProgressColors: ChewieProgressColors(
          playedColor: Colors.red,
          handleColor: Colors.redAccent,
          bufferedColor: Colors.white54,
          backgroundColor: Colors.white24,
        ),
        additionalControls: (BuildContext context) => <Widget>[
          IconButton(
            tooltip: 'Back 10 seconds',
            icon: const Icon(Icons.replay_10),
            color: Colors.white,
            onPressed: () async {
              final position = controller.value.position;

              final target =
                  position - const Duration(seconds: 10);

              await controller.seekTo(
                target < Duration.zero
                    ? Duration.zero
                    : target,
              );
            },
          ),
          IconButton(
            tooltip: 'Forward 10 seconds',
            icon: const Icon(Icons.forward_10),
            color: Colors.white,
            onPressed: () async {
              final position = controller.value.position;
              final duration = controller.value.duration;

              final target =
                  position + const Duration(seconds: 10);

              await controller.seekTo(
                target > duration ? duration : target,
              );
            },
          ),
        ],
      );

      _chewieController = chewieController;

      setState(() {
        _isLoading = false;
        _showCenterIcon = true;
      });

      _showTemporaryCenterIcon();
    } catch (error) {
      await _closeCurrentVideo();

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage =
            'Video could not be loaded.\n\n$error';
      });
    }
  }

  void _videoListener() {
    final controller = _videoController;

    if (controller == null || !mounted) return;

    final isPlaying = controller.value.isPlaying;

    if (isPlaying != _lastPlayingState) {
      _lastPlayingState = isPlaying;

      setState(() {
        _showCenterIcon = true;
      });

      _showTemporaryCenterIcon();
    }

    if (controller.value.hasError &&
        _errorMessage == null &&
        mounted) {
      setState(() {
        _errorMessage =
            controller.value.errorDescription ??
                'Video playback error.';
      });
    }
  }

  void _showTemporaryCenterIcon() {
    _centerIconTimer?.cancel();

    _centerIconTimer = Timer(
      const Duration(seconds: 2),
      () {
        if (!mounted) return;

        setState(() {
          _showCenterIcon = false;
        });
      },
    );
  }

  Future<void> _closeCurrentVideo() async {
    _centerIconTimer?.cancel();

    _chewieController?.dispose();
    _chewieController = null;

    final controller = _videoController;
    _videoController = null;

    if (controller != null) {
      controller.removeListener(_videoListener);
      await controller.dispose();
    }
  }

  Future<void> _stopVideo() async {
    await _closeCurrentVideo();

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      _showCenterIcon = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasPlayer = _chewieController != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Video Link Player'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Play MP4 or HLS video links inside Cloud Guard.',
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey,
                ),
              ),

              const SizedBox(height: 16),

              TextField(
                controller: _urlController,
                keyboardType: TextInputType.url,
                autocorrect: false,
                decoration: InputDecoration(
                  labelText: 'Video URL',
                  hintText:
                      'https://example.com/video.mp4',
                  prefixIcon:
                      const Icon(Icons.link),
                  border:
                      const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    tooltip: 'Clear',
                    icon:
                        const Icon(Icons.clear),
                    onPressed: () {
                      _urlController.clear();
                    },
                  ),
                ),
                onSubmitted: (_) => _playVideo(),
              ),

              const SizedBox(height: 12),

              SizedBox(
                height: 48,
                child: ElevatedButton.icon(
                  onPressed:
                      _isLoading ? null : _playVideo,
                  icon:
                      const Icon(Icons.play_arrow),
                  label: Text(
                    _isLoading
                        ? 'Loading...'
                        : 'Play Video',
                  ),
                ),
              ),

              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(
                      alpha: 0.10,
                    ),
                    borderRadius:
                        BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.red.withValues(
                        alpha: 0.35,
                      ),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style:
                              const TextStyle(
                            color: Colors.red,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              if (hasPlayer) ...[
                const SizedBox(height: 20),

                AspectRatio(
                  aspectRatio: _videoController!
                      .value
                      .aspectRatio,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Chewie(
                        controller:
                            _chewieController!,
                      ),

                      IgnorePointer(
                        child:
                            AnimatedOpacity(
                          opacity:
                              _showCenterIcon
                                  ? 1.0
                                  : 0.0,
                          duration:
                              const Duration(
                            milliseconds: 200,
                          ),
                          child: Container(
                            width: 68,
                            height: 68,
                            decoration:
                                BoxDecoration(
                              color: Colors.black
                                  .withValues(
                                alpha: 0.65,
                              ),
                              shape:
                                  BoxShape.circle,
                            ),
                            child: Icon(
                              _lastPlayingState
                                  ? Icons.play_arrow
                                  : Icons.pause,
                              color: Colors.white,
                              size: 42,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                OutlinedButton.icon(
                  onPressed: _stopVideo,
                  icon:
                      const Icon(Icons.close),
                  label:
                      const Text('Close Video'),
                ),
              ],

              if (!hasPlayer &&
                  !_isLoading &&
                  _errorMessage == null) ...[
                const SizedBox(height: 40),
                const Icon(
                  Icons.video_library_outlined,
                  size: 64,
                  color: Colors.grey,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Paste a direct MP4 or HLS (.m3u8) video link to start playback.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}