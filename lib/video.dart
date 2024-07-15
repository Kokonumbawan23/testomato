import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:image_picker/image_picker.dart';

class VideoPlayerScreen extends StatefulWidget {
  const VideoPlayerScreen({super.key});

  @override
  _VideoPlayerScreenState createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  VideoPlayerController? _controller;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> getVideo() async {
    final ImagePicker picker = ImagePicker();
    final XFile? video = await picker.pickVideo(source: ImageSource.gallery);
    if (video != null) {
      _controller = VideoPlayerController.file(File(video.path))
        ..initialize().then((_) {
          setState(() {});
          // _controller!.play();
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomCenter,
      fit: StackFit.loose,
      children: <Widget>[
        Center(
          child: _controller != null && _controller!.value.isInitialized
              ? SizedBox(
                  height: MediaQuery.of(context).size.height,
                  width: MediaQuery.of(context).size.width,
                  child: AspectRatio(
                    aspectRatio: 9 / 16,
                    child: VideoPlayer(_controller!),
                  ),
                )
              : const Text("No video is selected"),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: getVideo,
              child: const Text("Select Video"),
            ),
            ElevatedButton(
                onPressed: () {
                  if (_controller != null) {
                    if (_controller!.value.isPlaying) {
                      _controller!.pause();
                    } else {
                      _controller!.play();
                    }
                  }
                },
                child: const Text("Play/Pause")),
          ],
        )
      ],
    );
  }
}
