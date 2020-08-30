import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as IMG;

void main() => runApp(
      MaterialApp(
        title: 'Flutter Demo',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: FacePage(),
      ),
    );

class FacePage extends StatefulWidget {
  @override
  _FacePageState createState() => _FacePageState();
}

class _FacePageState extends State<FacePage> {
  File _imageFile;
  List<Face> _faces;
  bool isLoading = false;
  ui.Image _image1;
  ui.Image _image2;

  _getImageAndDetectFaces() async {
    var imageFile1 = await ImagePicker().getImage(source: ImageSource.gallery);
    var imageFile2 = await ImagePicker().getImage(source: ImageSource.gallery);
    setState(() {
      isLoading = true;
    });
    final image = FirebaseVisionImage.fromFile(File(imageFile1.path));
    print(image);
    final faceDetector = FirebaseVision.instance.faceDetector();
    List<Face> faces = await faceDetector.processImage(image);
    if (mounted) {
      setState(() {
        _imageFile = File(imageFile1.path);
        _faces = faces;
        _loadImage1(File(imageFile1.path));
        _loadImage2(File(imageFile2.path));
      });
    }
  }

  _loadImage1(File file) async {
    final data = await file.readAsBytes();
    await decodeImageFromList(data).then(
      (value) => setState(() {
        _image1 = value;
        isLoading = false;
      }),
    );
  }

  _loadImage2(File file) async {
    final data = await file.readAsBytes();
    await decodeImageFromList(data).then(
      (value) => setState(() {
        _image2 = value;
        isLoading = false;
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : (_imageFile == null)
              ? Center(child: Text('No image selected'))
              : Center(
                  child: FittedBox(
                    child: SizedBox(
                      width: _image1.width.toDouble(),
                      height: _image1.height.toDouble(),
                      child: CustomPaint(
                        painter: FacePainter(_image1, _image2, _faces),
                      ),
                    ),
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _getImageAndDetectFaces,
        tooltip: 'Choose a picture of you then choose a PNG of a hat',
        child: Icon(Icons.add_a_photo),
      ),
    );
  }
}

class FacePainter extends CustomPainter {
  final ui.Image image1;
  final ui.Image image2;
  final List<Face> faces;
  final List<Rect> rects = [];
  var bkImage;

  FacePainter(this.image1, this.image2, this.faces) {
    for (var i = 0; i < faces.length; i++) {
      rects.add(faces[i].boundingBox);
    }
  }

  @override
  void paint(ui.Canvas canvas, ui.Size size) async {
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 15.0
      ..color = Colors.yellow;

    canvas.drawImage(image1, Offset.zero, Paint());
//    canvas.drawImage(image, Offset(200, 200), Paint());
    for (var i = 0; i < faces.length; i++) {
      var x = rects[i].topCenter.dx;
      var y = rects[i].topCenter.dy;
      Rect a = Rect.fromCenter(
          center: Offset(x, 7*y/8),
          width: rects[i].width,
          height: rects[i].height);
      paintImage(canvas: canvas, rect: a, image: image2);
//      canvas.drawRect(a, paint);
    }
  }

  @override
  bool shouldRepaint(FacePainter oldDelegate) {
//    return image != oldDelegate.image || faces != oldDelegate.faces;
  }
}
