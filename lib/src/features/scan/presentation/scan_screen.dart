import 'dart:io';
import 'dart:math';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:scanning_app/src/core/palm_reading/palm_reading_service.dart';
import 'package:scanning_app/src/features/reading/presentation/reading_result_screen.dart';
import 'package:scanning_app/src/features/subscription/presentation/subscription_screen.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> with TickerProviderStateMixin {
  CameraController? _cameraController;
  List<CameraDescription>? cameras;
  bool _isCameraInitialized = false;
  bool _isScanning = false;
  String? _scannedImagePath;

  late AnimationController _animationController;
  late Animation<double> _animation;

  late AnimationController _scanAnimationController;
  late Animation<double> _scanAnimation;

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

    _scanAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    _scanAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scanAnimationController, curve: Curves.linear),
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
    _scanAnimationController.dispose();
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _takePictureAndNavigate() async {
    if (!_isCameraInitialized || _cameraController == null || _isScanning) return;
    
    try {
      final file = await _cameraController!.takePicture();
      if (!mounted) return;

      setState(() {
        _isScanning = true;
        _scannedImagePath = file.path;
      });

      // Run 4 seconds scan animation
      await _scanAnimationController.forward(from: 0.0);

      if (mounted) {
        final path = _scannedImagePath;
        setState(() {
          _isScanning = false;
          _scannedImagePath = null;
        });
        if (path != null) {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => ReadingResultScreen(imagePath: path),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isScanning = false;
          _scannedImagePath = null;
        });
      }
      debugPrint('Error taking picture: $e');
    }
  }

  void _showApiKeyDialog(BuildContext context) {
    final currentKey = PalmReadingService.apiKey;
    final controller = TextEditingController(text: currentKey);

    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.auto_awesome, color: Colors.greenAccent),
              SizedBox(width: 8),
              Text('Gemini AI Settings'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Enter your Gemini API Key to enable real AI palm reading analysis.',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: controller,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Gemini API Key',
                    border: OutlineInputBorder(),
                    hintText: 'AIzaSy...',
                    prefixIcon: Icon(Icons.key),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Your key is saved securely on this device and sent directly to Google Gemini APIs. You can obtain a free key from Google AI Studio.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            if (currentKey.isNotEmpty)
              TextButton(
                onPressed: () async {
                  await PalmReadingService.saveCustomApiKey('');
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('API Key cleared. Resetting to demo mode.')),
                    );
                  }
                },
                child: const Text('Clear Key'),
              ),
            FilledButton(
              onPressed: () async {
                final newKey = controller.text.trim();
                await PalmReadingService.saveCustomApiKey(newKey);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        newKey.isEmpty
                            ? 'API Key cleared.'
                            : 'API Key saved! AI analysis is now enabled.',
                      ),
                    ),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  String _getScanningMessage(double progress) {
    if (progress < 0.25) {
      return 'CALIBRATING SCANNER...';
    } else if (progress < 0.5) {
      return 'MAPPING PALM GEOMETRY...';
    } else if (progress < 0.75) {
      return 'DECODING PALM LINES...';
    } else {
      return 'AI ANALYSIS IN PROGRESS...';
    }
  }

  Widget _buildBiometricStatusText(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.55),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.3), width: 0.5),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          fontFamily: 'monospace',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Palm Scanner'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Gemini AI Settings',
            onPressed: () => _showApiKeyDialog(context),
          ),
        ],
      ),
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
                            
                            // Image freeze frame when scanning
                            if (_isScanning && _scannedImagePath != null) ...[
                              ColorFiltered(
                                colorFilter: ColorFilter.mode(
                                  Colors.greenAccent.withOpacity(0.4),
                                  BlendMode.color,
                                ),
                                child: Image.file(
                                  File(_scannedImagePath!),
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
                                ),
                              ),
                              Container(
                                color: Colors.black.withOpacity(0.35),
                              ),
                            ],

                            // Interactive Holographic Laboratory overlay
                            AnimatedBuilder(
                              animation: Listenable.merge([_scanAnimation, _animation]),
                              builder: (context, child) {
                                return CustomPaint(
                                  painter: _LaboratoryScannerPainter(
                                    scanProgress: _isScanning ? _scanAnimation.value : 0.0,
                                    pulseProgress: _animation.value,
                                    isScanning: _isScanning,
                                  ),
                                );
                              },
                            ),

                            // Biometric diagnostic status readouts (when scanning)
                            if (_isScanning) ...[
                              Positioned(
                                top: 30,
                                left: 30,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildBiometricStatusText('SYS.STATUS', 'ACTIVE', Colors.greenAccent),
                                    const SizedBox(height: 6),
                                    _buildBiometricStatusText('DERMAL.RES', '1080p', Colors.cyanAccent),
                                    const SizedBox(height: 6),
                                    _buildBiometricStatusText('TEMP.IND', '36.6 C', Colors.greenAccent),
                                  ],
                                ),
                              ),
                              Positioned(
                                top: 30,
                                right: 30,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    _buildBiometricStatusText('BIOM.INDEX', '94.2%', Colors.cyanAccent),
                                    const SizedBox(height: 6),
                                    _buildBiometricStatusText('AI.MODE', 'PALMISTRY', Colors.amberAccent),
                                    const SizedBox(height: 6),
                                    _buildBiometricStatusText('GRID.CAL', 'OK', Colors.greenAccent),
                                  ],
                                ),
                              ),
                              // Bottom diagnostics status panel
                              Positioned(
                                bottom: 30,
                                left: 30,
                                right: 30,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.8),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: Colors.greenAccent.withOpacity(0.3), width: 1),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      AnimatedBuilder(
                                        animation: _scanAnimation,
                                        builder: (context, child) {
                                          final progress = _scanAnimation.value;
                                          final pct = (progress * 100).toInt();
                                          return Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                _getScanningMessage(progress),
                                                style: const TextStyle(
                                                  color: Colors.greenAccent,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                  letterSpacing: 1.0,
                                                ),
                                              ),
                                              Text(
                                                '$pct%',
                                                style: const TextStyle(
                                                  color: Colors.greenAccent,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  fontFamily: 'monospace',
                                                ),
                                              ),
                                            ],
                                          );
                                        },
                                      ),
                                      const SizedBox(height: 8),
                                      AnimatedBuilder(
                                        animation: _scanAnimation,
                                        builder: (context, child) {
                                          return LinearProgressIndicator(
                                            value: _scanAnimation.value,
                                            backgroundColor: Colors.greenAccent.withOpacity(0.15),
                                            color: Colors.greenAccent,
                                            minHeight: 4,
                                            borderRadius: BorderRadius.circular(2),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
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

class _LaboratoryScannerPainter extends CustomPainter {
  _LaboratoryScannerPainter({
    required this.scanProgress,
    required this.pulseProgress,
    required this.isScanning,
  });

  final double scanProgress;
  final double pulseProgress;
  final bool isScanning;

  // Maps 0..1 relative coords → actual canvas pixels
  // Hand fills ~85% of the canvas width and ~80% of height, centred
  static double _px(double rx, double w) => w * (0.075 + rx * 0.85);
  static double _py(double ry, double h) => h * (0.05  + ry * 0.88);

  Path _getHandPath(Size size) {
    final w = size.width;
    final h = size.height;
    double px(double rx) => _px(rx, w);
    double py(double ry) => _py(ry, h);

    final path = Path();

    // Open left palm facing camera — fingers up, thumb right.
    // Finger length order: middle > index > ring > pinky.
    // Trace the outer contour counter-clockwise from wrist-left.

    // Wrist bottom-left
    path.moveTo(px(0.28), py(0.97));

    // Left palm edge up toward pinky
    path.cubicTo(
      px(0.14), py(0.90),
      px(0.08), py(0.76),
      px(0.10), py(0.62),
    );

    // Pinky (shortest) — outer edge, rounded tip, inner web
    path.cubicTo(
      px(0.07), py(0.50),
      px(0.06), py(0.40),
      px(0.09), py(0.32),
    );
    path.cubicTo(
      px(0.12), py(0.40),
      px(0.14), py(0.48),
      px(0.18), py(0.52),
    );

    // Ring finger
    path.cubicTo(
      px(0.19), py(0.40),
      px(0.20), py(0.28),
      px(0.22), py(0.22),
    );
    path.cubicTo(
      px(0.24), py(0.28),
      px(0.26), py(0.40),
      px(0.30), py(0.50),
    );

    // Middle finger (longest)
    path.cubicTo(
      px(0.32), py(0.36),
      px(0.34), py(0.18),
      px(0.36), py(0.11),
    );
    path.cubicTo(
      px(0.38), py(0.18),
      px(0.40), py(0.36),
      px(0.44), py(0.48),
    );

    // Index finger
    path.cubicTo(
      px(0.46), py(0.34),
      px(0.48), py(0.22),
      px(0.50), py(0.17),
    );
    path.cubicTo(
      px(0.52), py(0.22),
      px(0.54), py(0.36),
      px(0.56), py(0.52),
    );

    // Thumb — natural outward angle
    path.cubicTo(
      px(0.62), py(0.54),
      px(0.74), py(0.48),
      px(0.84), py(0.44),
    );
    path.cubicTo(
      px(0.90), py(0.48),
      px(0.86), py(0.58),
      px(0.76), py(0.66),
    );

    // Right palm edge down to wrist
    path.cubicTo(
      px(0.68), py(0.78),
      px(0.62), py(0.90),
      px(0.58), py(0.97),
    );

    path.lineTo(px(0.28), py(0.97));
    path.close();
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    _drawCorners(canvas, size);

    final handPath = _getHandPath(size);
    final pulseOpacity = 0.4 + 0.3 * sin(pulseProgress * pi);

    final outlinePaint = Paint()
      ..color = isScanning ? Colors.greenAccent : Colors.greenAccent.withOpacity(pulseOpacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = isScanning ? 3.0 : 2.0
      ..maskFilter = MaskFilter.blur(BlurStyle.solid, isScanning ? 4.0 : 2.0);

    canvas.drawPath(handPath, outlinePaint);

    if (isScanning) {
      final haloPaint = Paint()
        ..color = Colors.greenAccent.withOpacity(0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8.0
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8.0);
      canvas.drawPath(handPath, haloPaint);
    }

    canvas.save();
    canvas.clipPath(handPath);

    final gridPaint = Paint()
      ..color = Colors.greenAccent.withOpacity(0.08)
      ..strokeWidth = 0.8;
    const double gridSize = 20.0;
    for (double x = 0; x < w; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, h), gridPaint);
    }
    for (double y = 0; y < h; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(w, y), gridPaint);
    }

    final double sweepRatio = isScanning ? (scanProgress * 2) % 1.0 : pulseProgress;
    final double sweepY = h * (0.12 + sweepRatio * 0.76);

    if (isScanning) {
      final trailHeight = h * 0.20;
      final trailPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Colors.greenAccent.withOpacity(0.35),
            Colors.greenAccent.withOpacity(0.0),
          ],
        ).createShader(Rect.fromLTRB(0, sweepY - trailHeight, w, sweepY));
      canvas.drawRect(
        Rect.fromLTRB(0, sweepY - trailHeight, w, sweepY),
        trailPaint..blendMode = BlendMode.srcATop,
      );
    }

    canvas.restore();

    // Skeleton nodes — same 0..1 relative space as _px/_py
    final nodes = [
      // 0: wrist centre
      const Offset(0.43, 0.97),
      // 1: palm centre
      const Offset(0.38, 0.66),
      // Thumb: 2=base, 3=mid, 4=tip
      const Offset(0.60, 0.62),
      const Offset(0.72, 0.54),
      const Offset(0.84, 0.44),
      // Index: 5=base, 6=mid, 7=tip
      const Offset(0.53, 0.54),
      const Offset(0.51, 0.36),
      const Offset(0.50, 0.17),
      // Middle: 8=base, 9=mid, 10=tip
      const Offset(0.42, 0.50),
      const Offset(0.38, 0.30),
      const Offset(0.36, 0.11),
      // Ring: 11=base, 12=mid, 13=tip
      const Offset(0.28, 0.52),
      const Offset(0.24, 0.36),
      const Offset(0.22, 0.22),
      // Pinky: 14=base, 15=mid, 16=tip
      const Offset(0.16, 0.54),
      const Offset(0.12, 0.42),
      const Offset(0.09, 0.32),
    ];

    final connections = [
      [0, 1],
      [1, 2], [2, 3], [3, 4],
      [1, 5], [5, 6], [6, 7],
      [1, 8], [8, 9], [9, 10],
      [1, 11], [11, 12], [12, 13],
      [1, 14], [14, 15], [15, 16],
    ];

    double scaleX(double rx) => _px(rx, w);
    double scaleY(double ry) => _py(ry, h);

    for (final conn in connections) {
      final p1Raw = nodes[conn[0]];
      final p2Raw = nodes[conn[1]];
      final p1 = Offset(scaleX(p1Raw.dx), scaleY(p1Raw.dy));
      final p2 = Offset(scaleX(p2Raw.dx), scaleY(p2Raw.dy));

      final maxNodeY = p1.dy > p2.dy ? p1.dy : p2.dy;
      final bool isAcquired = isScanning ? sweepY >= maxNodeY : false;
      
      final connPaint = Paint()
        ..color = isAcquired 
            ? Colors.cyanAccent.withOpacity(0.7) 
            : (isScanning ? Colors.greenAccent.withOpacity(0.15) : Colors.cyan.withOpacity(0.2))
        ..strokeWidth = isAcquired ? 1.8 : 1.0;

      canvas.drawLine(p1, p2, connPaint);
    }

    for (int i = 0; i < nodes.length; i++) {
      final rawPos = nodes[i];
      final pos = Offset(scaleX(rawPos.dx), scaleY(rawPos.dy));

      final bool isAcquired = isScanning ? sweepY >= pos.dy : false;
      final nodePulse = 2.0 * sin(pulseProgress * pi + i);
      final double radius = isAcquired ? (5.0 + nodePulse) : 3.5;

      final nodePaint = Paint()
        ..color = isAcquired 
            ? Colors.cyanAccent 
            : (isScanning ? Colors.greenAccent.withOpacity(0.3) : Colors.cyan.withOpacity(0.4))
        ..style = PaintingStyle.fill;

      if (isAcquired) {
        final nodeGlow = Paint()
          ..color = Colors.cyanAccent.withOpacity(0.5)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);
        canvas.drawCircle(pos, radius + 3, nodeGlow);
      }

      canvas.drawCircle(pos, radius, nodePaint);
    }

    _drawPalmistryLines(canvas, size, sweepY, scaleX, scaleY);
    _drawFingertipRings(canvas, scaleX, scaleY, sweepY);

    final laserPaint = Paint()
      ..color = Colors.greenAccent
      ..strokeWidth = 3.5
      ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 4.0);
    
    final laserCorePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 1.2;

    canvas.drawLine(Offset(w * 0.05, sweepY), Offset(w * 0.95, sweepY), laserPaint);
    canvas.drawLine(Offset(w * 0.05, sweepY), Offset(w * 0.95, sweepY), laserCorePaint);
  }

  void _drawPalmistryLines(
    Canvas canvas,
    Size size,
    double sweepY,
    double Function(double) scaleX,
    double Function(double) scaleY,
  ) {
    final heartPath = Path()
      ..moveTo(scaleX(0.06), scaleY(0.58))
      ..cubicTo(scaleX(0.20), scaleY(0.54),
                scaleX(0.36), scaleY(0.52),
                scaleX(0.52), scaleY(0.54));

    final headPath = Path()
      ..moveTo(scaleX(0.54), scaleY(0.60))
      ..cubicTo(scaleX(0.38), scaleY(0.62),
                scaleX(0.20), scaleY(0.64),
                scaleX(0.08), scaleY(0.62));

    final lifePath = Path()
      ..moveTo(scaleX(0.54), scaleY(0.60))
      ..cubicTo(scaleX(0.48), scaleY(0.72),
                scaleX(0.42), scaleY(0.84),
                scaleX(0.36), scaleY(0.95));

    final heartLineTrigger = scaleY(0.54);
    final headLineTrigger  = scaleY(0.62);
    final lifeLineTrigger  = scaleY(0.70);

    void drawNeonLine(Path path, bool isActive, Color activeColor) {
      final paint = Paint()
        ..color = isScanning 
            ? (isActive ? activeColor : Colors.greenAccent.withOpacity(0.15))
            : activeColor.withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = isActive ? 2.5 : 1.2
        ..strokeCap = StrokeCap.round;

      if (isActive && isScanning) {
        final glowPaint = Paint()
          ..color = activeColor.withOpacity(0.4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6.0
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5.0);
        canvas.drawPath(path, glowPaint);
      }
      canvas.drawPath(path, paint);
    }

    drawNeonLine(heartPath, sweepY >= heartLineTrigger, const Color(0xFFFF2E93));
    drawNeonLine(headPath, sweepY >= headLineTrigger, const Color(0xFFFFC700));
    drawNeonLine(lifePath, sweepY >= lifeLineTrigger, const Color(0xFF00E5FF));
  }

  void _drawFingertipRings(
    Canvas canvas,
    double Function(double) scaleX,
    double Function(double) scaleY,
    double sweepY,
  ) {
    // Fingertip positions: pinky, ring, middle, index, thumb
    final tips = [
      const Offset(0.09, 0.32),
      const Offset(0.22, 0.22),
      const Offset(0.36, 0.11),
      const Offset(0.50, 0.17),
      const Offset(0.84, 0.44),
    ];

    for (int i = 0; i < tips.length; i++) {
      final tip = tips[i];
      final pos = Offset(scaleX(tip.dx), scaleY(tip.dy));
      final acquired = isScanning && sweepY >= pos.dy;
      final ringColor = acquired ? Colors.greenAccent : Colors.cyanAccent.withOpacity(0.5);
      const ringRadius = 14.0;

      final glowPaint = Paint()
        ..color = ringColor.withOpacity(acquired ? 0.35 : 0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6.0
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6.0);
      canvas.drawCircle(pos, ringRadius, glowPaint);

      final ringPaint = Paint()
        ..color = ringColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.drawCircle(pos, ringRadius, ringPaint);

      if (acquired) {
        final dotPaint = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill;
        canvas.drawCircle(pos, 2.5, dotPaint);
      }
    }
  }

  void _drawCorners(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isScanning ? Colors.greenAccent : Colors.greenAccent.withOpacity(0.5)
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const double cornerLength = 30.0;
    const double padding = 20.0;
    final w = size.width;
    final h = size.height;

    final path = Path();

    path.moveTo(padding, padding + cornerLength);
    path.lineTo(padding, padding);
    path.lineTo(padding + cornerLength, padding);

    path.moveTo(w - padding - cornerLength, padding);
    path.lineTo(w - padding, padding);
    path.lineTo(w - padding, padding + cornerLength);

    path.moveTo(padding, h - padding - cornerLength);
    path.lineTo(padding, h - padding);
    path.lineTo(padding + cornerLength, h - padding);

    path.moveTo(w - padding - cornerLength, h - padding);
    path.lineTo(w - padding, h - padding);
    path.lineTo(w - padding, h - padding - cornerLength);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _LaboratoryScannerPainter oldDelegate) {
    return oldDelegate.scanProgress != scanProgress ||
        oldDelegate.pulseProgress != pulseProgress ||
        oldDelegate.isScanning != isScanning;
  }
}
