import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_vision/flutter_vision.dart';
import 'camera.dart';
import 'video.dart';

late List<CameraDescription> camerass;

main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    const MaterialApp(
      home: MainScreen(),
    ),
  );
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State {
  int _selectedScreenIndex = 0;
  late CameraController controller;
  late FlutterVision vision;
  bool isLoaded = false;
  // late final List<Widget> menu;

  void _selectScreen(int index) {
    setState(() {
      _selectedScreenIndex = index;
    });
  }

  @override
  void initState() {
    super.initState();
    init();
  }

  Future<void> init() async {
    camerass = await availableCameras();
    vision = FlutterVision();
    controller = CameraController(camerass[0], ResolutionPreset.high);
    controller.initialize().then((value) {
      loadYoloModel().then((value) {
        setState(() {
          isLoaded = true;
        });
      });
    });
  }

  Future<void> loadYoloModel() async {
    await vision.loadYoloModel(
        labels: 'assets/label2.txt',
        modelPath: 'assets/best_float16.tflite',
        modelVersion: "yolov8",
        quantization: true,
        numThreads: 4,
        useGpu: true);
    setState(() {
      isLoaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoaded == false) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    return Scaffold(
        appBar: AppBar(
          title: Text(
            "TesTomato",
            style: TextStyle(
              color: Colors.green[400],
              fontFamily: "Roboto",
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: Center(
            child: _selectedScreenIndex == 0
                ? YoloCamera(controller: controller, vision: vision)
                : const VideoPlayerScreen()),
        bottomNavigationBar: BottomNavigationBar(
          onTap: _selectScreen,
          currentIndex: _selectedScreenIndex,
          items: [
            BottomNavigationBarItem(
              activeIcon: Icon(
                Icons.camera,
                color: Colors.green[400],
              ),
              icon: const Icon(Icons.camera),
              label: "Camera",
            ),
            BottomNavigationBarItem(
              activeIcon: Icon(
                Icons.video_camera_back,
                color: Colors.green[400],
              ),
              icon: const Icon(Icons.video_camera_back),
              label: "Video",
            ),
          ],
        ));
  }
}
