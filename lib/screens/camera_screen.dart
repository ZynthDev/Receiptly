import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/camera_service.dart';
import '../utils/app_theme.dart';
import 'receipt_processing_screen.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  final CameraService _cameraService = CameraService();
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Scan Receipt'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(right: 24, left: 24, top: 12),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Header
                _buildHeader(),
                
                const SizedBox(height: 48),
                
                // Camera options
                _buildCameraOptions(),
                
                const SizedBox(height: 48),
                
                // Instructions
                _buildInstructions(),

                const SizedBox(height: 15,)
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryColor.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const Icon(
            Icons.camera_alt,
            size: 60,
            color: Colors.white,
          ),
        ),
        
        const SizedBox(height: 24),
        
        Text(
          'Capture Your Receipt',
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
        
        const SizedBox(height: 8),
        
        Text(
          'Take a photo or select from gallery to get started',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: AppTheme.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildCameraOptions() {
    return Column(
      children: [
        // Take Photo button
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: _isProcessing ? null : () => _captureImage(ImageSource.camera),
            icon: const Icon(Icons.camera_alt, size: 24),
            label: Text(
              _isProcessing ? 'Processing...' : 'Take Photo',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 4,
              shadowColor: AppTheme.primaryColor.withValues(alpha: 0.3),
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Choose from Gallery button
        SizedBox(
          width: double.infinity,
          height: 56,
          child: OutlinedButton.icon(
            onPressed: _isProcessing ? null : () => _captureImage(ImageSource.gallery),
            icon: const Icon(Icons.photo_library, size: 24),
            label: const Text(
              'Choose from Gallery',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.primaryColor,
              side: const BorderSide(
                color: AppTheme.primaryColor,
                width: 2,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInstructions() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.blue.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                color: Colors.blue[600],
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Tips for better results',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.blue[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._buildTips(),
        ],
      ),
    );
  }

  List<Widget> _buildTips() {
    final tips = [
      'Ensure good lighting when taking photos',
      'Keep the receipt flat and fully visible',
      'Avoid shadows and glare on the receipt',
      'Make sure text is clear and readable',
    ];

    return tips.map((tip) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            height: 4,
            margin: const EdgeInsets.only(top: 8, right: 12),
            decoration: BoxDecoration(
              color: Colors.blue[600],
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Text(
              tip,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.blue[700],
              ),
            ),
          ),
        ],
      ),
    )).toList();
  }

  Future<void> _captureImage(ImageSource source) async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      File? imageFile;
      
      if (source == ImageSource.camera) {
        imageFile = await _cameraService.pickImageFromCamera();
      } else {
        imageFile = await _cameraService.pickImageFromGallery();
      }

      if (imageFile != null) {
        // Navigate to processing screen
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ReceiptProcessingScreen(
              imageFile: imageFile!,
            ),
          ),
        );
      }
    } on CameraException catch (e) {
      // Handle permission-specific errors with better UX
      _showPermissionDialog(source, e.message);
    } catch (e) {
      // Handle other errors
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error capturing image: ${e.toString()}'),
          backgroundColor: AppTheme.errorColor,
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _showPermissionDialog(ImageSource source, String message) {
    final isCamera = source == ImageSource.camera;
    final alternativeSource = isCamera ? ImageSource.gallery : ImageSource.camera;
    final alternativeText = isCamera ? 'Choose from Gallery' : 'Take Photo';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${isCamera ? 'Camera' : 'Photo Library'} Access Required'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            const SizedBox(height: 16),
            Text(
              'You can:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text('• Try the other option (${alternativeText.toLowerCase()})'),
            Text('• Enable permissions in Settings'),
            Text('• Try again after enabling permissions'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _captureImage(alternativeSource); // Use alternative
            },
            child: Text(alternativeText),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              openAppSettings(); // Open settings
            },
            child: const Text('Open Settings'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _cameraService.dispose();
    super.dispose();
  }
}

// Add this enum for image source
enum ImageSource {
  camera,
  gallery,
}
