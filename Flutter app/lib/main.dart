import 'package:flutter/material.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:tflite/tflite.dart';
import 'package:image_picker/image_picker.dart';
import 'package:vertical_card_pager/vertical_card_pager.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'dart:async';
import 'package:face_mask/face_detector_view.dart';
import 'package:camera/camera.dart';
import 'package:face_mask/FacePainter.dart';

List<CameraDescription> cameras = [];
String? tempPath;
FaceDetector faceDetector = GoogleMlKit.vision.faceDetector();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  cameras = await availableCameras();
  tempPath = (await getTemporaryDirectory()).path + 't.png';
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        theme: ThemeData.dark(),
        title: 'Face_Mask_Detection',
        home: const ImageScn());
  }
}

class ImageScn extends StatefulWidget {
  const ImageScn({Key? key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<ImageScn> {
  bool isLoading = false;
  ui.Image? _image;
  img.Image? faceCrop, originalImage;
  final List<bool>? _isBlue = [];
  final List<Rect>? _rects = [];
  int _t = 0, _tnm = 0;
  List? recognitions;

  _MyAppState();
  final List<String> titles = [
    'Project about',
    'Jay Prakash Pandey',
    'Abhishek Anand'
  ];

  final List<Widget> images = [
    Container(
        color: Colors.blueGrey,
        child: const Text(
          'In this ongoing era of pandemic, wearing a “Face Mask” is the need of the hour as it is a proven medical equipment to resist the spread of SARS-CoV-2 Virus, also known as Coronavirus, through human interaction. But despite of the COVID norms, many people are still loitering around without wearing a face mask properly. It is an absolute necessity to track those people as they are the most potential super-spreaders of COVID-19.\nTo resolve this issue, we have come up with an innovative yet cost-effective module for "Mass Face Mask Detection" using the principles of Computer Vision. Using that model, we use a live-streaming camera and ffmpeg module, in order to run the module on a larger number of people in a certain area and to successfully detect the number of mask-less people & track them accordingly. Our application will also upload that real-time data constantly into the server to track and monitor the real-time data of a particular area. This project would not only benefit the masses as it will successfully detect the mask-less people in a large locality and thus significantly control the spread of the pandemic in that certain area, but also it would also help the administration to ease the hectic process of tracking each and every mask-less person manually. Thus, our project is focused on both the domains of efficiency and cost-effectiveness to ensure maximum safety of an area by curbing the spread of SARS-CoV-2 (COVID-19) Virus.\n\nKeywords: Tensorflow, ffmpeg, Computer Vision, COVID-19, Face Mask',
        )),
    Container(
      color: Colors.red,
      child: Column(
        children: const [
          Expanded(
            flex: 2,
            child: Image(
              image: AssetImage("assets/j.jpeg"),
            ),
          ),
          Expanded(
              flex: 1,
              child: Text(
                'Jay Pakash Pandey\njayprakashpandey47b@gmail.com\nB.tech IT 3rd year \nInstitute of engineering and management',
                textScaleFactor: 1.3,
                textAlign: TextAlign.center,
              ))
        ],
      ),
    ),
    Container(
      color: Colors.cyanAccent,
      child: Column(
        children: const [
          Expanded(
            flex: 2,
            child: Image(
              image: AssetImage("assets/abhi.jpeg"),
            ),
          ),
          Expanded(
              flex: 1,
              child: Text(
                'Abhishek Anand\nabhianand2308@gmail.com\nB.tech IT 3rd year \nInstitute of engineering and management',
                textScaleFactor: 1.3,
                textAlign: TextAlign.center,
              ))
        ],
      ),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadModel();
  }

  @override
  void dispose() {
    faceDetector.close();
    imageCache!.clear();
    Tflite.close();
    cameras.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Face Mask Detection'),
          centerTitle: true,
          actions: <Widget>[
            IconButton(
              icon: const Icon(Icons.add_chart),
              tooltip: 'Report',
              onPressed: () {
                final SnackBar _snackBar = SnackBar(
                  content: Text(
                      '|Total Persons : $_t|  |With mask : ${_t - _tnm}|   |Without mask: $_tnm|'),
                  duration: const Duration(seconds: 15),
                );
                ScaffoldMessenger.of(context).showSnackBar(_snackBar);
              },
            ),
            IconButton(
                icon: const Icon(Icons.account_circle),
                tooltip: 'About',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute<void>(builder: (BuildContext context) {
                      return Scaffold(
                        backgroundColor: Colors.amber,
                        appBar: AppBar(
                          leading: IconButton(
                            icon: const Icon(Icons.arrow_back_ios_sharp),
                            onPressed: () {
                              Navigator.pop(context);
                            },
                          ),
                          title: const Text('About'),
                          centerTitle: true,
                        ),
                        body: SafeArea(
                          child: Column(
                            children: <Widget>[
                              Expanded(
                                child: VerticalCardPager(
                                  textStyle: TextStyle(
                                      color: Colors.white.withOpacity(0.4)),
                                  titles: titles,
                                  images: images,
                                  onPageChanged: (page) {},
                                  align: ALIGN.CENTER,
                                  onSelectedItem: (index) {},
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  );
                }),
          ],
        ),
        floatingActionButton: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FloatingActionButton(
              onPressed: _getFromCamera,
              tooltip: 'Open Camera',
              child: const Icon(Icons.add_a_photo_sharp),
            ),
            const SizedBox(width: 20),
            FloatingActionButton(
              onPressed: _getImage,
              tooltip: 'Open Gallary',
              child: const Icon(Icons.add_photo_alternate),
            ),
            const SizedBox(width: 20),
            FloatingActionButton(
              tooltip: 'Live Camera',
              child: const Icon(Icons.camera),
              onPressed: _getlivecamera,
            )
          ],
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : (_image == null)
                ? const Center(
                    child: Text(
                        'In this ongoing era of pandemic, wearing a “Face Mask” is the need of the hour as it is a proven medical equipment to resist the spread of SARS-CoV-2 Virus, also known as Coronavirus, through human interaction. But despite of the COVID norms, many people are still loitering around without wearing a face mask properly. It is an absolute necessity to track those people as they are the most potential super-spreaders of COVID-19.\n\nTo resolve this issue, we have come up with an innovative yet cost-effective module for "Mass Face Mask Detection" using the principles of Computer Vision. First, we have created a trained model based on AI using Tensorflow, Keras & Mobilenet in order to distinguish between a masked and a mask-less person.\n\nWe have trained our built model more and more efficiently to successfully detect faces with precision. Then, using that model, we use a live-streaming camera and ffmpeg module, in order to run the module on a larger number of people in a certain area and to successfully detect the number of mask-less people & track them accordingly. Our application will also upload that real-time data constantly into the server to track and monitor the real-time data of a particular area. This project would not only benefit the masses as it will successfully detect the mask-less people in a large locality and thus significantly control the spread of the pandemic in that certain area, but also it would also help the administration to ease the hectic process of tracking each and every mask-less person manually. Thus, our project is focused on both the domains of efficiency and cost-effectiveness to ensure maximum safety of an area by curbing the spread of SARS-CoV-2 (COVID-19) Virus.\n\n\nKeywords: Tensorflow, ffmpeg, Computer Vision, COVID-19, Face Mask'))
                : Center(
                    child: FittedBox(
                    child: SizedBox(
                      width: _image!.width.toDouble(),
                      height: _image!.height.toDouble(),
                      child: CustomPaint(
                        painter: FacePainter(_isBlue!, _rects!, image: _image),
                      ),
                    ),
                  )));
  }

  _getlivecamera() {
    Navigator.push(
        context, MaterialPageRoute(builder: (context) => const FaceDetectorView()));
  }

  Future _loadModel() async {
    try {
      (await Tflite.loadModel(
          model: 'assets/mask_detector.tflite',
          labels: 'assets/mask_labelmap.txt',
          useGpuDelegate: true,
          numThreads: 2))!;
    } on Exception catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('unable to load model : $e')));
    }
  }

  _getFromCamera() async {
    XFile? pickedFile = await ImagePicker().pickImage(
      source: ImageSource.camera,
      maxWidth: 1800,
      maxHeight: 1800,
    );
    if (pickedFile == null) {
      isLoading = true;
    } else {
      _loadImage(pickedFile);
      _predictImage(pickedFile.path);
    }
  }

  _getImage() async {
    XFile? pickedFile = (await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1800,
      maxHeight: 1800,
    ));
    if (pickedFile == null) {
      isLoading = true;
    } else {
      _loadImage(pickedFile);
      _predictImage(pickedFile.path);
    }
  }

  _loadImage(XFile file) async {
    final data = await file.readAsBytes();
    await decodeImageFromList(data).then((value) => setState(() {
          _image = value;
          isLoading = false;
        }));
    _image = _image;
  }

  _predictImage(String imagePath) async {
    _rects!.clear();
    _isBlue!.clear();
    int x = 0, y = 0, w = 0, h = 0, _noMask = 0;
    List<Face>? _faces =
        await (faceDetector.processImage(InputImage.fromFilePath(imagePath)));
    if (mounted && _faces.isNotEmpty) {
      originalImage = img.decodeJpg(await XFile(imagePath).readAsBytes());
      for (int i = 0; i < _faces.length; i++) {
        _rects!.add(_faces[i].boundingBox);
        x = _faces[i].boundingBox.left.toInt();
        y = _faces[i].boundingBox.top.toInt();
        w = _faces[i].boundingBox.width.toInt();
        h = _faces[i].boundingBox.height.toInt();
        faceCrop = img.copyCrop(originalImage!, x, y, w, h);
        faceCrop = img.copyResizeCropSquare(faceCrop!, 60);
        File(tempPath!)
            .writeAsBytesSync(img.encodePng(faceCrop!), flush: false);
        recognitions = await Tflite.runModelOnImage(
          path: tempPath!,
          numResults: 1,
          threshold: 0.05,
          imageMean: 127.5,
          imageStd: 127.5,
        );
        if (recognitions![0]["label"] == "mask") {
          _isBlue!.add(true);
        } else {
          _isBlue!.add(false);
          _noMask++;
        }
        File(tempPath!).delete(recursive: true);
        faceCrop!.disposeMethod;
        originalImage!.disposeMethod;
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              'Found Without mask $_noMask Out of ${_faces.length} faces')));
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('faces not found')));
    }
    setState(() {
      _t += _faces.length;
      _tnm += _noMask;
    });
  }
}
