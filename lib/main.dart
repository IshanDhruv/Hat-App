import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

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
  var imageNumber = 0;

  _getImageAndDetectFaces() async {
    var imageFile1 = await ImagePicker().getImage(source: ImageSource.gallery);
    setState(() {
      isLoading = true;
    });
    final image = FirebaseVisionImage.fromFile(File(imageFile1.path));
    final faceDetector = FirebaseVision.instance.faceDetector();
    List<Face> faces = await faceDetector.processImage(image);

    ByteData byteData;
    if(imageNumber == 1)
       byteData = await rootBundle.load('assets/images/top_hat.png');
    if(imageNumber == 2)
       byteData = await rootBundle.load('assets/images/cowboy_hat.png');
    if(imageNumber == 3)
      byteData = await rootBundle.load('assets/images/beanie.png');
    final buffer = byteData.buffer;
    Directory tempDir = await getTemporaryDirectory();
    String tempPath = tempDir.path;
    var filePath = tempPath + '/file_01.tmp';
    File file = await File(filePath).writeAsBytes(buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));
    if (mounted) {
      setState(() {
        _imageFile = File(imageFile1.path);
        _faces = faces;
        _loadImage1(File(imageFile1.path));
        _loadImage2(file);
        isLoading = false;
      });
    }
  }

  _loadImage1(File file) async {
    final data = await file.readAsBytes();
    await decodeImageFromList(data).then(
      (value) => setState(() {
        _image1 = value;
      }),
    );
  }

  _loadImage2(File file) async {
    final data = await file.readAsBytes();
    await decodeImageFromList(data).then(
      (value) => setState(() {
        _image2 = value;
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.all(20),
        child: isLoading
            ? Center(child: CircularProgressIndicator())
            : (_imageFile == null)
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Center(child: Text('Choose a hat then choose an image (with a face)')),
                      SizedBox(height: 20),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: <Widget>[
                            MaterialButton(
                              color: imageNumber == 1 ? Colors.blue : null,
                              child: Image(
                                image: AssetImage('assets/images/top_hat.png'),
                                height: 100,
                                width: 100,
                              ),
                              onPressed: () {
                                setState(() {
                                  imageNumber = 1;
                                });
                              },
                            ),
                            MaterialButton(
                              color: imageNumber == 2 ? Colors.blue : null,
                              child: Image(
                                image: AssetImage('assets/images/cowboy_hat.png'),
                                height: 100,
                                width: 100,
                              ),
                              onPressed: () {
                                setState(() {
                                  imageNumber = 2;
                                });
                              },
                            ),
                            MaterialButton(
                              color: imageNumber == 3 ? Colors.blue : null,
                              child: Image(
                                image: AssetImage('assets/images/beanie.png'),
                                height: 100,
                                width: 100,
                              ),
                              onPressed: () {
                                setState(() {
                                  imageNumber = 3;
                                });
                              },
                            )
                          ],
                        ),
                      )
                    ],
                  )
                : Center(
                    child: FittedBox(
                      child: SizedBox(
                        width: _image1.width.toDouble() != null ? _image1.width.toDouble() : 1000,
                        height: _image1.height.toDouble() != null ? _image1.height.toDouble() : 1000,
                        child: CustomPaint(
                          painter: FacePainter(_image1, _image2, _faces),
                        ),
                      ),
                    ),
                  ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if(imageNumber!=0)
          _getImageAndDetectFaces();
          else {
            Fluttertoast.showToast(
                msg: "Please select an image.",
                toastLength: Toast.LENGTH_SHORT,
                timeInSecForIosWeb: 1,
                backgroundColor: Colors.grey,
                fontSize: 16.0
            );
          }
        },
        tooltip: 'Choose a picture',
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
    for (var i = 0; i < faces.length; i++) {
      var x = rects[i].topCenter.dx;
      var y = rects[i].topCenter.dy;
      Rect a = Rect.fromCenter(
          center: Offset(x, rects[i].topCenter.dy - (rects[i].height) / 4),
          width: rects[i].width * 1.33,
          height: rects[i].height);
      paintImage(canvas: canvas, rect: a, image: image2);
//      canvas.drawRect(a, paint);
    }
  }

  @override
  bool shouldRepaint(FacePainter oldDelegate) {
//    return image1 != oldDelegate.image1 || faces != oldDelegate.faces;
  }
}
