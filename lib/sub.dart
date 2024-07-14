import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_vision/flutter_vision.dart';

Future<void> main() async {
  // Ensure that plugin services are initialized so that `availableCameras()`
  // can be called before `runApp()`
  WidgetsFlutterBinding.ensureInitialized();

  final cameras = await availableCameras();

  // Get a specific camera from the list of available cameras.
  final firstCamera = cameras.first;

  runApp(
    MaterialApp(
      theme: ThemeData.dark(),
      home: TakePictureScreen(
        camera: firstCamera,
      ),
    ),
  );
}

// A screen that allows users to take a picture using a given camera.
class TakePictureScreen extends StatefulWidget {
  const TakePictureScreen({
    super.key,
    required this.camera,
  });

  final CameraDescription camera;

  @override
  TakePictureScreenState createState() => TakePictureScreenState();
}

class TakePictureScreenState extends State<TakePictureScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  late List<Map<String, dynamic>> yoloResults;
  late FlutterVision vision;

  CameraImage? cameraImage;
  bool isDetecting = false;
  bool isLoaded = false;

  List<Widget> displayBoxes(Size screen) {
    if (yoloResults.isEmpty) return [];
    double factorX = screen.width / (cameraImage?.height ?? 1);
    double factorY = screen.height / (cameraImage?.width ?? 1);

    Color colorPick = const Color.fromARGB(255, 50, 233, 30);

    return yoloResults.map((result) {
      double objectX = result["box"][0] * factorX;
      double objectY = result["box"][1] * factorY;
      double objectWidth = (result["box"][2] - result["box"][0]) * factorX;
      double objectHeight = (result["box"][3] - result["box"][1]) * factorY;

      return Positioned(
        left: objectX,
        top: objectY,
        width: objectWidth,
        height: objectHeight,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.all(Radius.circular(10.0)),
            border: Border.all(color: Colors.pink, width: 2.0),
          ),
          child: Text(
            "${result['tag']} ${(result['box'][4] * 100)}",
            style: TextStyle(
              background: Paint()..color = colorPick,
              color: const Color.fromARGB(255, 115, 0, 255),
              fontSize: 18.0,
            ),
          ),
        ),
      );
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    init();
    // To display the current output from the Camera,
    // create a CameraController.
  }

  init() async {
    vision = FlutterVision();
    _controller = CameraController(
      // Get a specific camera from the list of available cameras.
      widget.camera,
      // Define the resolution to use.
      ResolutionPreset.high,
    );

    // Next, initialize the controller. This returns a Future.
    _initializeControllerFuture = _controller.initialize().then((value) async {
      await vision
          .loadYoloModel(
              labels: 'assets/labels.txt',
              modelPath: 'assets/model.tflite',
              modelVersion: "yolov8",
              useGpu: false)
          .then((value) async {
        setState(() {
          isLoaded = true;
          yoloResults = [];
        });
      });
    });
  }

  @override
  void dispose() async {
    // Dispose of the controller when the widget is disposed.
    await vision.closeYoloModel();
    _controller.dispose();
    super.dispose();
  }

  void startDetection() async {
    isDetecting = true;
    await _controller.startImageStream((image) async {
      final result = await vision.yoloOnFrame(
        bytesList: image.planes.map((plane) => plane.bytes).toList(),
        imageHeight: image.height,
        imageWidth: image.width,
      );

      if (result.isNotEmpty) {
        setState(() {
          yoloResults = result;
        });
      }

      print(result);
    });
  }

  void stopDetection() async {
    isDetecting = false;
    await _controller.stopImageStream();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text('Take a picture')),
        // You must wait until the controller is initialized before displaying the
        // camera preview. Use a FutureBuilder to display a loading spinner until the
        // controller has finished initializing.
        body: Stack(
          fit: StackFit.expand,
          children: [
            AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: CameraPreview(_controller)),
            ...displayBoxes(MediaQuery.of(context).size),
            Positioned(
              bottom: 75,
              width: MediaQuery.of(context).size.width,
              child: Container(
                height: 80,
                width: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: Colors.white, width: 5, style: BorderStyle.solid),
                ),
                child: isDetecting
                    ? IconButton(
                        onPressed: () async {
                          stopDetection();
                        },
                        icon:
                            const Icon(Icons.stop, size: 40, color: Colors.red))
                    : IconButton(
                        onPressed: () async {
                          startDetection();
                        },
                        icon: const Icon(Icons.play_arrow,
                            size: 40, color: Colors.green),
                      ),
              ),
            )
          ],
        ));
  }
}
