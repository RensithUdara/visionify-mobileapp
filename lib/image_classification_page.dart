import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_image_classification/image_classification_helper.dart';
import 'package:image_picker/image_picker.dart';

class ImageClassificationScreen extends StatefulWidget {
  const ImageClassificationScreen({super.key});

  @override
  State<ImageClassificationScreen> createState() =>
      _ImageClassificationScreenState();
}

class _ImageClassificationScreenState
    extends State<ImageClassificationScreen> {
  File? _image;
  String command = 'Pick an Image';
  bool isLoading = false;
  List<Map<String, dynamic>>? _output;

  final ImagePicker _picker = ImagePicker();
  final ImageClassificationHelper _helper = ImageClassificationHelper();

  Future<void> pickImage() async {
    var image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    setState(() {
      _image = File(image.path);
      isLoading = true;
      command = 'Processing the image...';
    });

    var result = await _helper.classifyImage(_image!);
    setState(() {
      _output = result;
      command = _output == null ? 'Error during classification' : 'Done';
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.camera, color: Colors.indigo, size: 28),
            SizedBox(width: 8),
            Text(
              'Visionify Image Classification',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 22,
                color: Colors.indigo,
              ),
            ),
          ],
        ),
        backgroundColor: const Color.fromARGB(255, 186, 196, 255),
        elevation: 4,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(16),
          ),
        ),
        toolbarHeight: 70,
        centerTitle: true,
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
                          leading:
                              const Icon(Icons.label, color: Colors.indigo),
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
                label: const Text('Pick an Image'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
