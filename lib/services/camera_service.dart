import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart' as picker;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:permission_handler/permission_handler.dart';

class CameraException implements Exception {
  final String message;
  CameraException(this.message);
  
  @override
  String toString() => message;
}

class CameraService {
  static final CameraService _instance = CameraService._internal();
  factory CameraService() => _instance;
  CameraService._internal();

  final picker.ImagePicker _picker = picker.ImagePicker();
  List<CameraDescription>? _cameras;
  CameraController? _controller;

  // Initialize cameras
  Future<void> initializeCameras() async {
    try {
      _cameras = await availableCameras();
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing cameras: $e');
      }
    }
  }

  // Get camera controller for custom camera screen
  Future<CameraController?> getCameraController() async {
    if (_cameras == null || _cameras!.isEmpty) {
      await initializeCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        return null;
      }
    }

    if (_controller != null) {
      await _controller!.dispose();
    }

    _controller = CameraController(
      _cameras!.first,
      ResolutionPreset.high,
      enableAudio: false,
    );

    try {
      await _controller!.initialize();
      return _controller;
    } catch (e) {
      print('Error initializing camera controller: $e');
      return null;
    }
  }

  // Take picture with custom camera
  Future<File?> takePictureWithCamera() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      final controller = await getCameraController();
      if (controller == null) return null;
    }

    try {
      final XFile image = await _controller!.takePicture();
      return File(image.path);
    } catch (e) {
      print('Error taking picture: $e');
      return null;
    }
  }

  // Take picture from camera using ImagePicker
  Future<File?> pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: picker.ImageSource.camera,
        imageQuality: 85,
        preferredCameraDevice: picker.CameraDevice.rear,
      );

      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      print('Error picking image from camera: $e');
      // Check if it's a permission issue
      final errorString = e.toString().toLowerCase();
      if (errorString.contains('permission') || 
          errorString.contains('denied') || 
          errorString.contains('camera access')) {
        throw CameraException('Camera permission denied. Please enable camera access in Settings.');
      }
      throw CameraException('Failed to access camera: ${e.toString()}');
    }
  }

  // Pick image from gallery
  Future<File?> pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: picker.ImageSource.gallery,
        imageQuality: 85,
      );

      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      print('Error picking image from gallery: $e');
      // Check if it's a permission issue
      final errorString = e.toString().toLowerCase();
      if (errorString.contains('permission') || 
          errorString.contains('denied') || 
          errorString.contains('photo') ||
          errorString.contains('library')) {
        throw CameraException('Photo library access denied. Please enable photo access in Settings.');
      }
      throw CameraException('Failed to access photo library: ${e.toString()}');
    }
  }

  // Save image to app documents directory
  Future<String> saveImageToAppDirectory(File imageFile) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final receiptDir = Directory(path.join(appDir.path, 'receipts'));
      
      if (!await receiptDir.exists()) {
        await receiptDir.create(recursive: true);
      }

      final fileName = 'receipt_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savedImagePath = path.join(receiptDir.path, fileName);
      
      await imageFile.copy(savedImagePath);
      return savedImagePath;
    } catch (e) {
      print('Error saving image: $e');
      throw Exception('Failed to save image');
    }
  }

  // Delete image file
  Future<bool> deleteImage(String imagePath) async {
    try {
      final file = File(imagePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      print('Error deleting image: $e');
      return false;
    }
  }

  // Check if image file exists
  Future<bool> imageExists(String imagePath) async {
    try {
      final file = File(imagePath);
      return await file.exists();
    } catch (e) {
      return false;
    }
  }

  // Get image file from path
  File? getImageFile(String imagePath) {
    try {
      final file = File(imagePath);
      return file;
    } catch (e) {
      return null;
    }
  }

  // Check permissions
  Future<bool> checkCameraPermission() async {
    final status = await Permission.camera.status;
    return status.isGranted;
  }

  Future<bool> checkPhotoPermission() async {
    final status = await Permission.photos.status;
    return status.isGranted;
  }

  // Request permissions
  Future<bool> requestCameraPermission() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  Future<bool> requestPhotoPermission() async {
    final status = await Permission.photos.request();
    return status.isGranted;
  }

  // Cleanup
  void dispose() {
    _controller?.dispose();
    _controller = null;
  }

  // Show image source selection dialog
  Future<File?> showImageSourceDialog(Function(String) showDialog) async {
    final result = await showDialog('Choose Image Source');
    
    switch (result) {
      case 'camera':
        return await pickImageFromCamera();
      case 'gallery':
        return await pickImageFromGallery();
      default:
        return null;
    }
  }
}
