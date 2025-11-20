// import 'package:flutter/material.dart';

// void main() {
//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   // This widget is the root of your application.
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Flutter Demo',
//       theme: ThemeData(
//         // This is the theme of your application.
//         //
//         // TRY THIS: Try running your application with "flutter run". You'll see
//         // the application has a purple toolbar. Then, without quitting the app,
//         // try changing the seedColor in the colorScheme below to Colors.green
//         // and then invoke "hot reload" (save your changes or press the "hot
//         // reload" button in a Flutter-supported IDE, or press "r" if you used
//         // the command line to start the app).
//         //
//         // Notice that the counter didn't reset back to zero; the application
//         // state is not lost during the reload. To reset the state, use hot
//         // restart instead.
//         //
//         // This works for code too, not just values: Most code changes can be
//         // tested with just a hot reload.
//         colorScheme: .fromSeed(seedColor: Colors.deepPurple),
//       ),
//       home: const MyHomePage(title: 'Flutter Demo Home Page'),
//     );
//   }
// }

// class MyHomePage extends StatefulWidget {
//   const MyHomePage({super.key, required this.title});

//   // This widget is the home page of your application. It is stateful, meaning
//   // that it has a State object (defined below) that contains fields that affect
//   // how it looks.

//   // This class is the configuration for the state. It holds the values (in this
//   // case the title) provided by the parent (in this case the App widget) and
//   // used by the build method of the State. Fields in a Widget subclass are
//   // always marked "final".

//   final String title;

//   @override
//   State<MyHomePage> createState() => _MyHomePageState();
// }

// class _MyHomePageState extends State<MyHomePage> {
//   int _counter = 0;

//   void _incrementCounter() {
//     setState(() {
//       // This call to setState tells the Flutter framework that something has
//       // changed in this State, which causes it to rerun the build method below
//       // so that the display can reflect the updated values. If we changed
//       // _counter without calling setState(), then the build method would not be
//       // called again, and so nothing would appear to happen.
//       _counter++;
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     // This method is rerun every time setState is called, for instance as done
//     // by the _incrementCounter method above.
//     //
//     // The Flutter framework has been optimized to make rerunning build methods
//     // fast, so that you can just rebuild anything that needs updating rather
//     // than having to individually change instances of widgets.
//     return Scaffold(
//       appBar: AppBar(
//         // TRY THIS: Try changing the color here to a specific color (to
//         // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
//         // change color while the other colors stay the same.
//         backgroundColor: Theme.of(context).colorScheme.inversePrimary,
//         // Here we take the value from the MyHomePage object that was created by
//         // the App.build method, and use it to set our appbar title.
//         title: Text(widget.title),
//       ),
//       body: Center(
//         // Center is a layout widget. It takes a single child and positions it
//         // in the middle of the parent.
//         child: Column(
//           // Column is also a layout widget. It takes a list of children and
//           // arranges them vertically. By default, it sizes itself to fit its
//           // children horizontally, and tries to be as tall as its parent.
//           //
//           // Column has various properties to control how it sizes itself and
//           // how it positions its children. Here we use mainAxisAlignment to
//           // center the children vertically; the main axis here is the vertical
//           // axis because Columns are vertical (the cross axis would be
//           // horizontal).
//           //
//           // TRY THIS: Invoke "debug painting" (choose the "Toggle Debug Paint"
//           // action in the IDE, or press "p" in the console), to see the
//           // wireframe for each widget.
//           mainAxisAlignment: .center,
//           children: [
//             const Text('You have pushed the button this many times:'),
//             Text(
//               '$_counter',
//               style: Theme.of(context).textTheme.headlineMedium,
//             ),
//           ],
//         ),
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: _incrementCounter,
//         tooltip: 'Increment',
//         child: const Icon(Icons.add),
//       ),
//     );
//   }
// }

import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

// 1. GLOBAL VARIABLE: This will hold the list of available cameras.
late List<CameraDescription> cameras;

// 2. MAIN FUNCTION: Ensures Flutter is ready and finds the available cameras
// before running the app. This is crucial for hardware access.
Future<void> main() async {
  // You need to call WidgetsFlutterBinding.ensureInitialized() before calling
  // any Flutter-specific methods (like availableCameras()) in main().
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Await the list of available cameras (front, back, etc.).
    cameras = await availableCameras();
  } on CameraException catch (e) {
    // Print any errors if the cameras couldn't be fetched.
    print('Error fetching cameras: $e');
    cameras = [];
  }

  // Run the main application widget.
  runApp(const CameraApp());
}

class CameraApp extends StatelessWidget {
  const CameraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Camera Demo',
      theme: ThemeData(primarySwatch: Colors.blueGrey, useMaterial3: true),
      // Check if we found any cameras. If not, show an error screen.
      home: cameras.isEmpty
          ? const NoCameraScreen()
          : TakePictureScreen(camera: cameras.first),
    );
  }
}

class NoCameraScreen extends StatelessWidget {
  const NoCameraScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Camera App')),
      body: const Center(
        child: Text(
          'No camera available on this device or emulator.',
          style: TextStyle(fontSize: 18, color: Colors.red),
        ),
      ),
    );
  }
}

// 3. MAIN WIDGET: Displays the live camera feed and capture button.
class TakePictureScreen extends StatefulWidget {
  final CameraDescription camera;

  const TakePictureScreen({super.key, required this.camera});

  @override
  TakePictureScreenState createState() => TakePictureScreenState();
}

class TakePictureScreenState extends State<TakePictureScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;

  // XFile is the format for a captured file in Flutter plugins.
  XFile? _capturedImage;

  @override
  void initState() {
    super.initState();
    // To display the current output from the camera,
    // create a CameraController.
    _controller = CameraController(
      // Get a specific camera from the list of available cameras.
      widget.camera,
      // Define the resolution to use. High resolution is good for face recognition.
      ResolutionPreset.max,
      enableAudio: false, // We only need the image for face recognition
    );

    // Next, initialize the controller. This returns a Future.
    _initializeControllerFuture = _controller.initialize().catchError((e) {
      // Handle camera initialization errors (e.g., permissions denied).
      if (e is CameraException) {
        print('Camera init error: ${e.code} - ${e.description}');
        // Optionally show a dialog or message here
      } else {
        print('An unknown error occurred during camera initialization: $e');
      }
    });
  }

  @override
  void dispose() {
    // Dispose of the controller when the widget is disposed.
    _controller.dispose();
    super.dispose();
  }

  // Function to capture the image.
  Future<void> _captureImage() async {
    // Check if the controller is initialized and ready.
    if (!_controller.value.isInitialized) {
      return;
    }

    try {
      // Ensure the camera is initialized before taking a picture.
      await _initializeControllerFuture;

      // Attempt to take a picture and get the file `XFile`.
      final image = await _controller.takePicture();

      // Update the state to display the captured image.
      setState(() {
        _capturedImage = image;
      });

      // In a real app, you would send this 'image' file to your Python
      // face recognition backend here! (Using Dart's http client).
      print('Picture saved to: ${image.path}');
    } catch (e) {
      print(e);
    }
  }

  // Function to switch back to the camera preview.
  void _retakePicture() {
    setState(() {
      _capturedImage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Camera Preview'),
        backgroundColor: Colors.blueGrey,
      ),
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done &&
              _controller.value.isInitialized) {
            // If the Future is complete and the controller is ready,
            // show the camera preview or the captured image.
            return _capturedImage == null
                ? buildCameraPreview()
                : buildCapturedImage(context);
          } else if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Camera Error: ${snapshot.error}',
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          } else {
            // Otherwise, display a loading indicator.
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
      // Floating action button for taking pictures, visible only during preview.
      floatingActionButton: _capturedImage == null
          ? FloatingActionButton(
              onPressed: _captureImage,
              backgroundColor: Colors.blueGrey.shade700,
              child: const Icon(Icons.camera_alt, color: Colors.white),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  // Helper widget to display the camera feed, ensuring it fits the screen.
  Widget buildCameraPreview() {
    // AspectRatio ensures the preview maintains the camera's native aspect ratio.
    final size = MediaQuery.of(context).size;
    final scale = size.aspectRatio * _controller.value.aspectRatio;

    // Scale the preview only if the aspect ratio is greater than 1
    // (i.e., landscape mode on a portrait device).
    return Center(
      child: Transform.scale(
        scale: scale < 1 ? 1 : scale,
        child: AspectRatio(
          aspectRatio: _controller.value.aspectRatio,
          child: CameraPreview(_controller),
        ),
      ),
    );
  }

  // Helper widget to display the captured image.
  Widget buildCapturedImage(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.file(File(_capturedImage!.path), fit: BoxFit.cover),
        Positioned(
          bottom: 24,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Button to retake the photo
              ElevatedButton.icon(
                onPressed: _retakePicture,
                icon: const Icon(Icons.refresh),
                label: const Text('Retake'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade400,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
              // Button to confirm the photo (for future face recognition step)
              ElevatedButton.icon(
                onPressed: () {
                  // TODO: Your next step for face recognition goes here.
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Image confirmed! Ready for face recognition analysis.',
                      ),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                icon: const Icon(Icons.check),
                label: const Text('Use Photo'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade500,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
