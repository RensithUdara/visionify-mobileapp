import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: ImageClassification(),
    );
  }
}

class ImageClassification extends StatefulWidget {
  const ImageClassification({super.key});

  @override
  State<ImageClassification> createState() => _ImageClassificationState();
}

class _ImageClassificationState extends State<ImageClassification> {
  File? _image;
  List<Map<String, dynamic>>? _output;
  late Interpreter interpreter;
  List<String>? labels;
  int imgHeight = 224;
  int imgWidth = 224;
  String command = 'Pick an Image';
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    loadModel();
  }

  Future<void> loadModel() async {
    try {
      setState(() {
        command = 'Loading model...';
        isLoading = true;
      });
      await Future.delayed(const Duration(seconds: 3));
      interpreter = await Interpreter.fromAsset('assets/model/mobilenet_v1_1.0_224.tflite');
      labels = await _loadLabels('assets/model/labels.txt');
      setState(() {
        command = 'Pick an Image';
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        command = 'Failed to load model';
        isLoading = false;
      });
    }
  }

  Future<List<String>> _loadLabels(String path) async {
    final labelFile = await rootBundle.loadString(path);
    return labelFile.split('\n');
  }

  Future<void> pickImage() async {
    var image = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (image == null) return;

    setState(() {
      _image = File(image.path);
    });

    await classifyImage(_image!);
  }

  Future<void> classifyImage(File image) async {
    setState(() {
      command = 'Processing the image...';
      isLoading = true;
    });

    try {
      img.Image? inputImage = img.decodeImage(image.readAsBytesSync());
      if (inputImage == null) {
        throw Exception("Failed to decode image");
      }

      var input = imageToArray(inputImage);

      var output = List.filled(1 * 1001, 0.0).reshape([1, 1001]);

      interpreter.run(input, output);

      var probabilities = output[0];
      var prediction = List<Map<String, dynamic>>.generate(
        probabilities.length,
        (i) => {
          'index': i,
          'label': labels![i],
          'confidence': probabilities[i]
        },
      );

      prediction.sort((a, b) => b['confidence'].compareTo(a['confidence']));

      setState(() {
        _output = prediction.sublist(0, 3);
        command = 'Classification Done';
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        command = 'Error during classification';
        isLoading = false;
      });
    }
  }

  List<dynamic> imageToArray(img.Image inputImage) {
    img.Image resizedImage = img.copyResize(inputImage, width: imgWidth, height: imgHeight);
    List<double> flattenedList = resizedImage.data!
        .expand((channel) => [channel.r, channel.g, channel.b])
        .map((value) => value.toDouble())
        .toList();
    Float32List float32Array = Float32List.fromList(flattenedList);
    int channels = 3;
    int height = imgHeight;
    int width = imgWidth;
    Float32List reshapedArray = Float32List(1 * height * width * channels);
    for (int c = 0; c < channels; c++) {
      for (int h = 0; h < height; h++) {
        for (int w = 0; w < width; w++) {
          int index = c * height * width + h * width + w;
          reshapedArray[index] =
              (float32Array[c * height * width + h * width + w] - 127.5) / 127.5;
        }
      }
    }
    return reshapedArray.reshape([1, imgWidth, imgHeight, 3]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Image Classification'),
        backgroundColor: Colors.indigo,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.indigo.shade50, Colors.indigo.shade300],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              Center(
                child: _image != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.file(
                          _image!,
                          height: 250,
                          fit: BoxFit.contain,
                        ),
                      )
                    : const Icon(
                        Icons.image,
                        size: 150,
                        color: Colors.grey,
                      ),
              ),
              const SizedBox(height: 16),
              if (isLoading)
                const Center(child: CircularProgressIndicator())
              else
                Center(
                  child: Text(
                    command,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black54,
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              if (!isLoading && _output != null) ...[
                Expanded(
                  child: ListView.builder(
                    itemCount: _output!.length,
                    itemBuilder: (context, index) {
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8.0),
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          leading: const Icon(Icons.label, color: Colors.indigo),
                          title: Text(
                            _output![index]['label'],
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            "Confidence: ${(100 * _output![index]['confidence']).toStringAsFixed(2)}%",
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: isLoading ? null : pickImage,
                icon: const Icon(Icons.image),
            