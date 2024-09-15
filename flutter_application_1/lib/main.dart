import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Celebrity Impersonation Ad Classifier',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: InitialScreen(),
    );
  }
}

class InitialScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              '연예인 사칭 광고 분류 AI 프로그램',
              style: TextStyle(fontSize: 24),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => MyHomePage()),
                );
              },
              child: Text('Start'),
            ),
          ],
        ),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final ImagePicker _picker = ImagePicker();
  List<Map<String, dynamic>> _uploadedImages = [];

  Future<void> _getImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      final base64Image = base64Encode(bytes);
      final result = await _uploadImage(File(pickedFile.path));
      _showConfirmationDialog(base64Image, result);
    }
  }

  Future<String> _uploadImage(File imageFile) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('http://192.168.219.113:5000/predict'),
    );
    request.files.add(await http.MultipartFile.fromPath('file', imageFile.path));

    final response = await request.send();
    if (response.statusCode == 200) {
      final responseData = await response.stream.bytesToString();
      final decodedData = json.decode(responseData);
      return decodedData['predicted_class'];
    } else {
      return 'Error';
    }
  }

  void _showConfirmationDialog(String base64Image, String initialResult) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String selectedResult = initialResult;
        return AlertDialog(
          title: Text('이미지 분류 결과'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.memory(base64Decode(base64Image), height: 200, width: 200),
              SizedBox(height: 20),
              Text('AI 분류 결과 $initialResult 입니다.'),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Ai가 잘못 분류했나요?'),
                  DropdownButton<String>(
                    value: selectedResult,
                    items: ['실제 광고', '사칭 광고'].map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          selectedResult = newValue;
                        });
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: Text('취소'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('확인'),
              onPressed: () {
                setState(() {
                  _uploadedImages.add({
                    'image': base64Image,
                    'result': selectedResult,
                  });
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home'),
      ),
      body: Stack(
        children: <Widget>[
          PageView(
            scrollDirection: Axis.vertical,
            children: <Widget>[
              _buildRepresentativeAdImagesPage(),
              _buildClassifiedAdsPage(),
            ],
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: () => _getImage(ImageSource.camera),
                        child: Text('카메라'),
                      ),
                      SizedBox(width: 20),
                      ElevatedButton(
                        onPressed: () => _getImage(ImageSource.gallery),
                        child: Text('갤러리'),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    '업로드한 내역은 아래로 스와이프',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRepresentativeAdImagesPage() {
    return Column(
      children: <Widget>[
        SizedBox(height: 20),
        Text('대표적인 사칭 광고 이미지', style: TextStyle(fontSize: 18)),
        SizedBox(
          height: 500,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Image.asset('assets/img.png', height: 200, width: 200),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Image.asset('assets/img_1.png', height: 200, width: 200),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Image.asset('assets/img_2.png', height: 200, width: 200),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Image.asset('assets/img_3.png', height: 200, width: 200),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Image.asset('assets/img_4.png', height: 200, width: 200),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildClassifiedAdsPage() {
    return Column(
      children: <Widget>[
        Text('실제 광고', style: TextStyle(fontSize: 18)),
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _uploadedImages.length,
            itemBuilder: (context, index) {
              final image = _uploadedImages[index];
              if (image['result'] == '실제 광고') {
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Image.memory(base64Decode(image['image']), height: 200, width: 200),
                );
              }
              return Container();
            },
          ),
        ),
        Divider(),
        Text('사칭 광고', style: TextStyle(fontSize: 18)),
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _uploadedImages.length,
            itemBuilder: (context, index) {
              final image = _uploadedImages[index];
              if (image['result'] == '사칭 광고') {
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Image.memory(base64Decode(image['image']), height: 200, width: 200),
                );
              }
              return Container();
            },
          ),
        ),
        Spacer(),
      ],
    );
  }
}
