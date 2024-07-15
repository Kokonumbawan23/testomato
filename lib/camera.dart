import 'package:flutter_vision/flutter_vision.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

late List<CameraDescription> camerass;

class YoloCamera extends StatefulWidget {
  const YoloCamera({super.key, required this.controller, required this.vision});
  final CameraController controller;
  final FlutterVision vision;

  @override
  State<YoloCamera> createState() => _YoloVideoState();
}

class _YoloVideoState extends State<YoloCamera> {
// Here we start writing our code.
  late CameraController controller;
  late FlutterVision vision;
  late List<Map<String, dynamic>> yoloResults;

  CameraImage? cameraImage;
  bool isLoaded = false;
  bool isDetecting = false;
  double confidenceThreshold = 0.5;
  Map<String, Color> colorPick = {
    "Early Blight": Colors.red,
    "Late Blight": Colors.green,
    "Healthy": Colors.blue,
    "Leaf Miner": Colors.yellow,
    "Leaf Mold": Colors.purple,
    "Mosaic Virus": Colors.orange,
    "Septoria": Colors.pink,
    "Spider Mites": Colors.teal,
    "Yellow Leaf Curl Virus": Colors.brown,
  };

  @override
  void initState() {
    super.initState();
    setState(() {
      controller = widget.controller;
      vision = widget.vision;
      yoloResults = [];
      isDetecting = false;
    });
    // init();
  }

  // init() async {
  //   camerass = await availableCameras();
  //   vision = FlutterVision();
  //   controller = CameraController(camerass[0], ResolutionPreset.high);
  //   controller.initialize().then((value) {
  //     loadYoloModel().then((value) {
  //       setState(() {
  //         isLoaded = true;
  //         isDetecting = false;
  //         yoloResults = [];
  //       });
  //     });
  //   });
  // }

  @override
  void dispose() async {
    super.dispose();
    // controller.dispose();
    // await vision.closeYoloModel();
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          AspectRatio(
            aspectRatio: controller.value.aspectRatio,
            child: CameraPreview(
              controller,
            ),
          ),
          ...displayBoxesAroundRecognizedObjects(size),
          Positioned(
            bottom: 75,
            width: MediaQuery.of(context).size.width,
            child: Container(
              height: 80,
              width: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    width: 5, color: Colors.white, style: BorderStyle.solid),
              ),
              child: isDetecting
                  ? IconButton(
                      onPressed: () async {
                        stopDetection();
                      },
                      icon: const Icon(
                        Icons.stop,
                        color: Colors.red,
                      ),
                      iconSize: 50,
                    )
                  : IconButton(
                      onPressed: () async {
                        await startDetection();
                      },
                      icon: const Icon(
                        Icons.play_arrow,
                        color: Colors.white,
                      ),
                      iconSize: 50,
                    ),
            ),
          ),
        ],
      ),
    );
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

// Real-time object detection function by yoloOnFrame
  Future<void> yoloOnFrame(CameraImage cameraImage) async {
    final result = await vision.yoloOnFrame(
        bytesList: cameraImage.planes.map((plane) => plane.bytes).toList(),
        imageHeight: cameraImage.height,
        imageWidth: cameraImage.width,
        iouThreshold: 0.4,
        confThreshold: 0.4,
        classThreshold: 0.5);
    if (result.isNotEmpty) {
      setState(() {
        yoloResults = result;
      });
    } else {
      yoloResults = [];
    }
  }

  Future<void> startDetection() async {
    setState(() {
      isDetecting = true;
    });
    if (controller.value.isStreamingImages) {
      return;
    }
    await controller.startImageStream((image) async {
      if (isDetecting) {
        cameraImage = image;
        yoloOnFrame(image);
      }
    });
  }

  Future<void> stopDetection() async {
    setState(() {
      isDetecting = false;
      yoloResults.clear();
      yoloResults = [];
    });
  }

  List<Widget> displayBoxesAroundRecognizedObjects(Size screen) {
    if (yoloResults.isEmpty) return [];
    double factorX = screen.width / (cameraImage?.height ?? 1);
    double factorY = screen.height / (cameraImage?.width ?? 1);

    return yoloResults.map((result) {
      Color colorPick = this.colorPick[result["tag"]] ?? Colors.white;
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
            border: Border.all(color: colorPick, width: 2.0),
          ),
          child: Text(
            "${result['tag']} ${(result['box'][4] * 100)}",
            style: TextStyle(
              background: Paint()..color = colorPick,
              color: const Color.fromARGB(255, 255, 255, 255),
              fontSize: 12.0,
            ),
          ),
        ),
      );
    }).toList();
  }
}
