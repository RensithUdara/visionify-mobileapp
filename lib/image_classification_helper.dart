import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class ImageClassificationHelper {
  late Interpreter _interpreter;
  List<String>? _labels;
  final int _imgHeight = 224;
  final int _imgWidth = 224;

  ImageClassificationHelper() {
    _loadModel();
  }

  Future<void> _loadModel() async {
    _interpreter = await Interpreter.fromAsset(
        'assets/model/mobilenet_v1_1.0_224.tflite');
    _labels = await _loadLabels('assets/model/labels.txt');
  }

  Future<List<String>> _loadLabels(String path) async {
    final labelFile = await rootBundle.loadString(path);
    return labelFile.split('\n');
  }

  Future<List<Map<String, dynamic>>?> classifyImage(File image) async {
    try {
      img.Image? inputImage = img.decodeImage(image.readAsBytesSync());
      if (inputImage == null) throw Exception("Failed to decode image");

      var input = _imageToArray(inputImage);
      var output = List.filled(1 * 1001, 0.0).reshape([1, 1001]);

      _interpreter.run(input, output);

      var probabilities = output[0];
      var prediction = List<Map<String, dynamic>>.generate(
        probabilities.length,
        (i) =>
            {'index': i, 'label': _labels![i], 'confidence': probabilities[i]},
      );

      prediction.sort((a, b) => b['confidence'].compareTo(a['confidence']));
      return prediction.sublist(0, 3);
    } catch (e) {
      print('Error during classification: $e');
      return null;
    }
  }

  List<dynamic> _imageToArray(img.Image inputImage) {
    img.Image resizedImage =
        img.copyResize(inputImage, width: _imgWidth, height: _imgHeight);
    List<double> flattenedList = resizedImage.data!
        .expand((channel) => [channel.r, channel.g, channel.b])
        .map((value) => value.toDouble())
        .toList();
    Float32List float32Array = Float32List.fromList(flattenedList);
    return float32Array.reshape([1, _imgWidth, _imgHeight, 3]);
  }
}
