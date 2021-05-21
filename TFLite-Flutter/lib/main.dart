import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tflite/tflite.dart';

void main() {
  runApp(MyApp());
}

const String ssd = "SSD MobileNet";
const String yolo = "Tiny YOLOv2";

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: HomePage(),
    );
  }
}

class ImageUtils {
  static Future<File> imageToFile(String imageName) async {
    var bytes = await rootBundle.load('assets/images/$imageName.png');
    String tempPath = (await getTemporaryDirectory()).path;
    File file = File('$tempPath/profile.png');
    await file.writeAsBytes(
        bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes));
    return file;
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _model = ssd;
  double _imageWidth;
  double _imageHeight;
  bool _busy = false;

  List _recognitions;

  @override
  void initState() {
    super.initState();
    _busy = true;

    loadModel().then((val) {
      setState(() {
        _busy = false;
      });
    });
  }

  loadModel() async {
    Tflite.close();
    String res;
    res = await Tflite.loadModel(
      model: "assets/tflite/model.tflite",
      labels: "assets/tflite/labels.txt",
    );
    print(res);
  }

  File _image;
  final imagePicker = ImagePicker();
  Future getImage() async {
    final image = await ImageUtils.imageToFile("lite");
    setState(() {
      _image = File(image.path);
    });
    predictImage(File(image.path));
  }

  predictImage(File image) async {
    if (image == null) return;

    await myModel(image);

    FileImage(image)
        .resolve(ImageConfiguration())
        .addListener((ImageStreamListener((ImageInfo info, bool _) {
      setState(() {
        _imageWidth = info.image.width.toDouble();
        _imageHeight = info.image.height.toDouble();
      });
    })));

    setState(() {
      _image = image;
      _busy = false;
    });
  }

  myModel(File image) async {
    var recognitions = await Tflite.runModelOnImage(
        path: image.path, numResults: 1, threshold: 0.1, imageStd: 0.5, imageMean: 127.5);
    print(recognitions);
  }

  yolov2Tiny(File image) async {
    var recognitions = await Tflite.detectObjectOnImage(
        path: image.path,
        model: "YOLO",
        threshold: 0.3,
        imageMean: 0.0,
        imageStd: 255.0,
        numResultsPerClass: 1);

    setState(() {
      _recognitions = recognitions;
    });
  }

  ssdMobileNet(File image) async {
    var recognitions = await Tflite.detectObjectOnImage(
        path: image.path, numResultsPerClass: 1);

    setState(() {
      _recognitions = recognitions;
    });
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;


    return Scaffold(
      body: Center(
        child: _image == null ? Text("No Image Selected") : Image.file(_image),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: getImage,
        backgroundColor: Colors.blue,
        child: Icon(Icons.camera_alt),
      ),
    );
  }
}