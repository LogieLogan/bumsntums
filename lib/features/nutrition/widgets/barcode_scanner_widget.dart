// lib/features/nutrition/widgets/barcode_scanner_widget.dart
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/theme/color_palette.dart';
import '../../../shared/providers/analytics_provider.dart';
import '../services/ml_kit_service.dart';

class BarcodeScannerWidget extends ConsumerStatefulWidget {
  final Function(String) onBarcodeDetected;

  const BarcodeScannerWidget({super.key, required this.onBarcodeDetected});

  @override
  ConsumerState<BarcodeScannerWidget> createState() =>
      _BarcodeScannerWidgetState();
}

class _BarcodeScannerWidgetState extends ConsumerState<BarcodeScannerWidget> {
  late MobileScannerController _controller;
  bool _hasDetectedBarcode = false;
  bool _isTorchOn = false;
  bool _isInitialized = false;
  String _initErrorMessage = '';

  // Track analytics for scanner activity
  void _logScannerEvent(String eventName, {Map<String, Object>? parameters}) {
    ref
        .read(analyticsServiceProvider)
        .logEvent(name: eventName, parameters: parameters);
  }

  @override
  void initState() {
    super.initState();
    _initializeScanner();
    _logScannerEvent('barcode_scanner_started');
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      torchEnabled: false,
    );

    _logScannerEvent('barcode_scanner_started');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _initializeScanner() async {
    try {
      // Initialize MLKit first
      await MLKitService.initialize();

      // Then create the scanner controller
      _controller = MobileScannerController(
        detectionSpeed: DetectionSpeed.normal,
        facing: CameraFacing.back,
        torchEnabled: false,
      );

      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      setState(() {
        _initErrorMessage = 'Failed to initialize scanner: $e';
        _isInitialized = false;
      });
      _logScannerEvent(
        'barcode_scanner_init_error',
        parameters: {'error': e.toString()},
      );
    }
  }

  void _resetScanner() {
    setState(() {
      _hasDetectedBarcode = false;
    });
    _logScannerEvent('barcode_scanner_reset');
  }

  void _toggleTorch() {
    setState(() {
      _isTorchOn = !_isTorchOn;
      _controller.toggleTorch();
    });

    _logScannerEvent(
      'barcode_scanner_torch_toggled',
      parameters: {'torch_enabled': _isTorchOn},
    );
  }

  void _switchCamera() {
    _controller.switchCamera();
    _logScannerEvent('barcode_scanner_camera_switched');
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.pink),
            const SizedBox(height: 16),
            Text(
              _initErrorMessage.isEmpty
                  ? 'Initializing scanner...'
                  : _initErrorMessage,
              style: TextStyle(
                color: _initErrorMessage.isEmpty ? Colors.black : Colors.red,
              ),
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        // Scanner
        MobileScanner(
          controller: _controller,
          onDetect: (BarcodeCapture capture) {
            final List<Barcode> barcodes = capture.barcodes;

            // Only process the first detected barcode to avoid multiple callbacks
            if (barcodes.isNotEmpty && !_hasDetectedBarcode) {
              final String? code = barcodes.first.rawValue;
              final String format = barcodes.first.format.name;

              if (code != null) {
                setState(() {
                  _hasDetectedBarcode = true;
                });

                _logScannerEvent(
                  'barcode_detected',
                  parameters: {
                    'barcode_format': format ?? 'unknown',
                    'barcode_length': code.length,
                  },
                );

                widget.onBarcodeDetected(code);
              }
            }
          },
        ),

        // Scanner overlay
        Positioned.fill(child: CustomPaint(painter: ScannerOverlayPainter())),

        // Controls at the bottom
        Positioned(
          bottom: 20,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildControlButton(
                icon: _isTorchOn ? Icons.flash_on : Icons.flash_off,
                label: _isTorchOn ? 'Flash On' : 'Flash Off',
                onPressed: _toggleTorch,
              ),
              _buildControlButton(
                icon: Icons.flip_camera_android,
                label: 'Switch Camera',
                onPressed: _switchCamera,
              ),
              if (_hasDetectedBarcode)
                _buildControlButton(
                  icon: Icons.refresh,
                  label: 'Scan Again',
                  onPressed: _resetScanner,
                ),
            ],
          ),
        ),

        // Top guidance
        Positioned(
          top: 20,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              borderRadius: BorderRadius.circular(20),
            ),
            margin: const EdgeInsets.symmetric(horizontal: 40),
            child: const Text(
              'Point camera at a food barcode',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.5),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(icon, color: Colors.white),
            onPressed: onPressed,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            shadows: [
              Shadow(
                offset: Offset(0, 1),
                blurRadius: 3,
                color: Colors.black54,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Custom painter for scanner overlay
class ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Rect outerRect = Rect.fromLTWH(0, 0, size.width, size.height);

    // Define the scan area (center rectangle)
    final double scanAreaSize = size.width * 0.7;
    final Rect scanRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: scanAreaSize,
      height: scanAreaSize,
    );

    // Create a path for the overlay
    final Path path =
        Path()
          ..addRect(outerRect)
          ..addRect(scanRect);

    // Fill the path using even-odd to create the "hole" effect
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.black.withOpacity(0.5)
        ..style = PaintingStyle.fill
        ..blendMode = BlendMode.srcOut,
    );

    // Draw scan area border
    canvas.drawRect(
      scanRect,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );

    // Draw corner markers
    final double cornerSize = 20.0;
    final Paint cornerPaint =
        Paint()
          ..color =
              AppColors
                  .pink // Updated to use pink from updated color palette
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.0;

    // Top Left Corner
    canvas.drawPath(
      Path()
        ..moveTo(scanRect.left, scanRect.top + cornerSize)
        ..lineTo(scanRect.left, scanRect.top)
        ..lineTo(scanRect.left + cornerSize, scanRect.top),
      cornerPaint,
    );

    // Top Right Corner
    canvas.drawPath(
      Path()
        ..moveTo(scanRect.right - cornerSize, scanRect.top)
        ..lineTo(scanRect.right, scanRect.top)
        ..lineTo(scanRect.right, scanRect.top + cornerSize),
      cornerPaint,
    );

    // Bottom Left Corner
    canvas.drawPath(
      Path()
        ..moveTo(scanRect.left, scanRect.bottom - cornerSize)
        ..lineTo(scanRect.left, scanRect.bottom)
        ..lineTo(scanRect.left + cornerSize, scanRect.bottom),
      cornerPaint,
    );

    // Bottom Right Corner
    canvas.drawPath(
      Path()
        ..moveTo(scanRect.right - cornerSize, scanRect.bottom)
        ..lineTo(scanRect.right, scanRect.bottom)
        ..lineTo(scanRect.right, scanRect.bottom - cornerSize),
      cornerPaint,
    );

    // Add scan guide text
    TextPainter textPainter = TextPainter(
      text: const TextSpan(
        text: 'Align barcode within the frame',
        style: TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(
              offset: Offset(0, 1),
              blurRadius: 3.0,
              color: Colors.black54,
            ),
          ],
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    textPainter.layout(minWidth: 0, maxWidth: size.width);
    textPainter.paint(
      canvas,
      Offset((size.width - textPainter.width) / 2, scanRect.bottom + 20),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
