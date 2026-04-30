import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:scanning_app/src/features/reading/presentation/reading_result_screen.dart';
import 'package:scanning_app/src/features/subscription/presentation/subscription_screen.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> with SingleTickerProviderStateMixin {
  CameraController? _cameraController;
  List<CameraDescription>? cameras;
  bool _isCameraInitialized = false;
  bool _isScanning = false;

  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      cameras = await availableCameras();
      if (cameras != null && cameras!.isNotEmpty) {
        _cameraController = CameraController(
          cameras![0],
          ResolutionPreset.high,
          enableAudio: false,
        );
        await _cameraController!.initialize();
        if (mounted) {
          setState(() {
            _isCameraInitialized = true;
          });
        }
      }
    } catch (e) {
      debugPrint('Error initializing camera: $e');
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _takePictureAndNavigate() async {
    if (!_isCameraInitialized || _cameraController == null) return;
    
    setState(() {
      _isScanning = true;
    });

    try {
      // Simulate scanning process time for a professional feel
      await Future.delayed(const Duration(seconds: 2));
      
      await _cameraController!.takePicture();
      
      if (mounted) {
        setState(() {
          _isScanning = false;
        });
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const ReadingResultScreen(),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isScanning = false;
        });
      }
      debugPrint('Error taking picture: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Palm Scanner')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: Card(
                clipBehavior: Clip.antiAlias,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                  side: BorderSide(color: Theme.of(context).colorScheme.primary.withOpacity(0.5), width: 2),
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: _isCameraInitialized && _cameraController != null
                      ? Stack(
                          fit: StackFit.expand,
                          children: [
                            CameraPreview(_cameraController!),
                            
                            // Hand Outline
                            Center(
                              child: Icon(
                                Icons.back_hand_outlined,
                                size: 280,
                                color: Colors.white.withOpacity(0.4),
                              ),
                            ),
                            
                            // Scanner Corner Brackets
                            CustomPaint(
                              painter: _ScannerOverlayPainter(),
                            ),

                            // Scanning Laser Animation
                            AnimatedBuilder(
                              animation: _animation,
                              builder: (context, child) {
                                return LayoutBuilder(
                                  builder: (context, constraints) {
                                    return Positioned(
                                      top: _animation.value * constraints.maxHeight,
                                      left: 0,
                                      right: 0,
                                      child: Container(
                                        height: 3,
                                        decoration: BoxDecoration(
                                          color: Colors.greenAccent,
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.greenAccent.withOpacity(0.8),
                                              blurRadius: 15,
                                              spreadRadius: 5,
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),

                            // Scanning Status Overlay (when taking photo)
                            if (_isScanning)
                              Container(
                                color: Colors.black.withOpacity(0.6),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const CircularProgressIndicator(color: Colors.greenAccent),
                                    const SizedBox(height: 24),
                                    const Text(
                                      'Analyzing Palm Lines...',
                                      style: TextStyle(
                                        color: Colors.greenAccent,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.2,
                                      ),
                                    ).animate(onPlay: (controller) => controller.repeat(reverse: true))
                                     .fade(duration: 800.ms),
                                  ],
                                ),
                              ),
                          ],
                        )
                      : const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 12),
                              Text('Initializing camera...'),
                            ],
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton.icon(
                onPressed: (_isCameraInitialized && !_isScanning) ? _takePictureAndNavigate : null,
                icon: const Icon(Icons.document_scanner),
                label: const Text('Start Palm Scan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const SubscriptionScreen(),
                  ),
                );
              },
              child: const Text('Unlock premium reading'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.greenAccent.withOpacity(0.7)
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const double cornerLength = 40.0;
    const double padding = 30.0;

    final path = Path();

    // Top Left
    path.moveTo(padding, padding + cornerLength);
    path.lineTo(padding, padding);
    path.lineTo(padding + cornerLength, padding);

    // Top Right
    path.moveTo(size.width - padding - cornerLength, padding);
    path.lineTo(size.width - padding, padding);
    path.lineTo(size.width - padding, padding + cornerLength);

    // Bottom Left
    path.moveTo(padding, size.height - padding - cornerLength);
    path.lineTo(padding, size.height - padding);
    path.lineTo(padding + cornerLength, size.height - padding);

    // Bottom Right
    path.moveTo(size.width - padding - cornerLength, size.height - padding);
    path.lineTo(size.width - padding, size.height - padding);
    path.lineTo(size.width - padding, size.height - padding - cornerLength);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
