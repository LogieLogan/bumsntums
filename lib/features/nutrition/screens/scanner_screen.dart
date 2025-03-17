// lib/features/nutrition/screens/scanner_screen.dart
import 'package:bums_n_tums/features/nutrition/models/food_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/barcode_scanner_widget.dart';
import '../providers/food_scanner_provider.dart';
import 'food_details_screen.dart';
import '../../../shared/theme/color_palette.dart';
import '../../../shared/theme/text_styles.dart';
import '../services/permissions_service.dart';
import '../../../shared/providers/analytics_provider.dart';
import 'package:lottie/lottie.dart';

class ScannerScreen extends ConsumerStatefulWidget {
  const ScannerScreen({super.key});

  @override
  ConsumerState<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends ConsumerState<ScannerScreen> {
  bool _isPermissionChecked = false;
  bool _hasCameraPermission = false;

  @override
  void initState() {
    super.initState();
    _checkCameraPermission();

    // Initialize scanner
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(foodScannerProvider.notifier).initialize();
      ref
          .read(analyticsServiceProvider)
          .logScreenView(screenName: 'scanner_screen');
    });
  }

  Future<void> _checkCameraPermission() async {
    final permissionsService = ref.read(permissionsServiceProvider);
    final analyticsService = ref.read(analyticsServiceProvider);

    final hasPermission = await permissionsService.hasCameraPermission();

    setState(() {
      _isPermissionChecked = true;
      _hasCameraPermission = hasPermission;
    });

    if (!hasPermission) {
      analyticsService.logEvent(
        name: 'camera_permission_check',
        parameters: {'status': 'denied'},
      );

      // Check if it's permanently denied
      final isPermanent = await permissionsService.isPermanentlyDenied();

      if (isPermanent) {
        analyticsService.logEvent(
          name: 'camera_permission_check',
          parameters: {'status': 'permanently_denied'},
        );
        // Don't automatically request - we'll show UI for the user to go to settings
        return;
      }

      // Request permission if not permanently denied
      final granted = await permissionsService.requestCameraPermission();

      analyticsService.logEvent(
        name: 'camera_permission_request_result',
        parameters: {
          'granted': granted ? 'true' : 'false',
        }, // Convert boolean to string
      );

      setState(() {
        _hasCameraPermission = granted;
      });
    } else {
      analyticsService.logEvent(
        name: 'camera_permission_check',
        parameters: {'status': 'granted'},
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scannerState = ref.watch(foodScannerProvider);

    if (!_isPermissionChecked) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: AppColors.pink),
              const SizedBox(height: 16),
              Text('Checking camera permissions...', style: AppTextStyles.body),
            ],
          ),
        ),
      );
    }

    if (!_hasCameraPermission) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Food Scanner'),
          backgroundColor: AppColors.pink,
        ),
        body: _buildPermissionDeniedView(),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Food Scanner'),
        backgroundColor: AppColors.pink,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              // TODO: Navigate to scan history screen
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Scan history coming soon')),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Free tier usage indicator
          if (!scannerState.isScanning) _buildScanLimitIndicator(scannerState),

          // Scanner or results area
          Expanded(child: _buildScannerContent(scannerState)),

          // Bottom area with instructions or actions
          _buildBottomArea(scannerState),
        ],
      ),
    );
  }

  Widget _buildScanLimitIndicator(FoodScannerState state) {
    final remainingScans = state.freeTierLimit - state.scanCount;
    final isLimited = remainingScans < state.freeTierLimit;

    if (!isLimited) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      color:
          remainingScans <= 0
              ? Colors.red[100]
              : (remainingScans <= 2 ? Colors.amber[100] : Colors.green[100]),
      child: Row(
        children: [
          Icon(
            remainingScans <= 0
                ? Icons.warning
                : (remainingScans <= 2
                    ? Icons.info_outline
                    : Icons.check_circle),
            color:
                remainingScans <= 0
                    ? Colors.red[700]
                    : (remainingScans <= 2
                        ? Colors.amber[700]
                        : Colors.green[700]),
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              remainingScans <= 0
                  ? 'Daily scan limit reached. Upgrade for unlimited scans.'
                  : 'Free scans remaining today: $remainingScans',
              style: AppTextStyles.small.copyWith(
                color:
                    remainingScans <= 0
                        ? Colors.red[700]
                        : (remainingScans <= 2
                            ? Colors.amber[700]
                            : Colors.green[700]),
              ),
            ),
          ),
          if (remainingScans <= 0)
            TextButton(
              onPressed: () {
                // TODO: Navigate to upgrade page
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Upgrade coming soon')),
                );
              },
              child: Text(
                'Upgrade',
                style: AppTextStyles.small.copyWith(
                  color: AppColors.pink,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildScannerContent(FoodScannerState state) {
    // Show loading indicator during processing
    if (state.isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.pink),
            const SizedBox(height: 24),
            Text('Looking up product...', style: AppTextStyles.body),
          ],
        ),
      );
    }

    // Show scanner when actively scanning
    if (state.status == ScanningStatus.scanning) {
      return BarcodeScannerWidget(
        onBarcodeDetected: (barcode) {
          ref.read(foodScannerProvider.notifier).processBarcode(barcode);
        },
      );
    }

    // Show error states
    if (state.status == ScanningStatus.networkError) {
      return _buildErrorView(
        icon: Icons.signal_wifi_off,
        title: 'No Internet Connection',
        message: 'Please check your connection and try again',
        actionLabel: 'Try Again',
        onAction: () => ref.read(foodScannerProvider.notifier).retryScanning(),
      );
    }

    if (state.status == ScanningStatus.productNotFound) {
      return _buildErrorView(
        icon: Icons.search_off,
        title: 'Product Not Found',
        message: 'We couldn\'t find this product in our database',
        actionLabel: 'Scan Another',
        onAction: () => ref.read(foodScannerProvider.notifier).retryScanning(),
      );
    }

    if (state.status == ScanningStatus.failure && state.errorMessage != null) {
      return _buildErrorView(
        icon: Icons.error_outline,
        title: 'Something Went Wrong',
        message: state.errorMessage!,
        actionLabel: 'Try Again',
        onAction: () => ref.read(foodScannerProvider.notifier).retryScanning(),
      );
    }

    // Show results if we have them
    if (state.scannedItem != null) {
      return _buildResultsView(state.scannedItem!);
    }

    // Show recent scans or start scan button as default view
    return _buildStartScanView(state);
  }

  Widget _buildStartScanView(FoodScannerState state) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Use a more visually appealing camera icon
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.pink.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.camera_alt, size: 60, color: AppColors.pink),
          ),
          const SizedBox(height: 24),
          Text('Scan Food Labels', style: AppTextStyles.h2),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Point your camera at a barcode to scan nutritional information',
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(color: AppColors.mediumGrey),
            ),
          ),
          const SizedBox(height: 32),
          _buildPrimaryButton(
            icon: Icons.qr_code_scanner,
            label: 'Start Scanning',
            onPressed:
                state.canScanMore
                    ? () =>
                        ref.read(foodScannerProvider.notifier).startScanning()
                    : null, // Disable if scan limit reached
          ),

          if (!state.canScanMore)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                'Daily scan limit reached',
                style: AppTextStyles.small.copyWith(color: Colors.red),
              ),
            ),

          // Recent scans section
          if (state.recentScans.isNotEmpty) ...[
            const SizedBox(height: 40),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Recently Scanned', style: AppTextStyles.h3),
                  TextButton(
                    onPressed: () {
                      // TODO: Navigate to full history screen
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Full history coming soon'),
                        ),
                      );
                    },
                    child: Text(
                      'See All',
                      style: AppTextStyles.small.copyWith(
                        color: AppColors.pink,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount:
                    state.recentScans.length > 3 ? 3 : state.recentScans.length,
                itemBuilder: (context, index) {
                  final item = state.recentScans[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child:
                            item.imageUrl != null
                                ? Image.network(
                                  item.imageUrl!,
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                  errorBuilder:
                                      (_, __, ___) => Container(
                                        width: 60,
                                        height: 60,
                                        color: Colors.grey[200],
                                        child: const Icon(
                                          Icons.no_food,
                                          color: Colors.grey,
                                        ),
                                      ),
                                )
                                : Container(
                                  width: 60,
                                  height: 60,
                                  color: Colors.grey[200],
                                  child: const Icon(
                                    Icons.no_food,
                                    color: Colors.grey,
                                  ),
                                ),
                      ),
                      title: Text(
                        item.name,
                        style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (item.brand != null)
                            Text(
                              item.brand!,
                              style: AppTextStyles.small.copyWith(
                                color: AppColors.mediumGrey,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          Text(
                            _formatDate(item.scannedAt),
                            style: AppTextStyles.caption,
                          ),
                        ],
                      ),
                      trailing: Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: AppColors.mediumGrey,
                      ),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder:
                                (context) => FoodDetailsScreen(foodItem: item),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final dateToCheck = DateTime(date.year, date.month, date.day);

    if (dateToCheck == today) {
      return 'Today, ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (dateToCheck == yesterday) {
      return 'Yesterday';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  Widget _buildResultsView(FoodItem item) {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Success animation
            Lottie.asset(
              'assets/animations/success.json', // You'll need to add this animation file
              width: 120,
              height: 120,
              fit: BoxFit.contain,
              repeat: false,
            ),
            const SizedBox(height: 16),
            Text('Product Found!', style: AppTextStyles.h2),
            const SizedBox(height: 16),
            if (item.imageUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  item.imageUrl!,
                  width: 150,
                  height: 150,
                  fit: BoxFit.contain,
                  errorBuilder:
                      (_, __, ___) => Container(
                        width: 150,
                        height: 150,
                        color: Colors.grey[200],
                        child: const Icon(
                          Icons.no_food,
                          color: Colors.grey,
                          size: 50,
                        ),
                      ),
                ),
              ),
            const SizedBox(height: 16),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 32),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 1,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    item.name,
                    style: AppTextStyles.h3,
                    textAlign: TextAlign.center,
                  ),
                  if (item.brand != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      item.brand!,
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.mediumGrey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 16),
                  if (item.nutritionInfo != null) ...[
                    _buildNutritionPreview(item.nutritionInfo!),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildSecondaryButton(
                  icon: Icons.refresh,
                  label: 'Scan Again',
                  onPressed:
                      () => ref.read(foodScannerProvider.notifier).clearScan(),
                ),
                const SizedBox(width: 16),
                _buildPrimaryButton(
                  icon: Icons.visibility,
                  label: 'View Details',
                  onPressed: () {
                    Navigator.of(context)
                        .push(
                          MaterialPageRoute(
                            builder:
                                (context) => FoodDetailsScreen(foodItem: item),
                          ),
                        )
                        .then((_) {
                          // Clear scan when returning
                          ref.read(foodScannerProvider.notifier).clearScan();
                        });
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNutritionPreview(NutritionInfo nutrition) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Nutrition Summary',
          style: AppTextStyles.small.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNutrientCircle(
              'Calories',
              nutrition.calories?.toInt().toString() ?? '-',
              AppColors.popCoral,
            ),
            _buildNutrientCircle(
              'Protein',
              nutrition.protein != null
                  ? '${nutrition.protein!.toStringAsFixed(1)}g'
                  : '-',
              AppColors.popBlue,
            ),
            _buildNutrientCircle(
              'Carbs',
              nutrition.carbs != null
                  ? '${nutrition.carbs!.toStringAsFixed(1)}g'
                  : '-',
              AppColors.popYellow,
            ),
            _buildNutrientCircle(
              'Fat',
              nutrition.fat != null
                  ? '${nutrition.fat!.toStringAsFixed(1)}g'
                  : '-',
              AppColors.popTurquoise,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNutrientCircle(String label, String value, Color color) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withOpacity(0.2),
          ),
          child: Center(
            child: Text(
              value,
              style: AppTextStyles.small.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: AppTextStyles.caption),
      ],
    );
  }

  Widget _buildErrorView({
    required IconData icon,
    required String title,
    required String message,
    required String actionLabel,
    required VoidCallback onAction,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 72, color: AppColors.pink.withOpacity(0.7)),
            const SizedBox(height: 24),
            Text(title, style: AppTextStyles.h2, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            Text(
              message,
              style: AppTextStyles.body.copyWith(color: AppColors.mediumGrey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            _buildPrimaryButton(
              icon: Icons.refresh,
              label: actionLabel,
              onPressed: onAction,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomArea(FoodScannerState state) {
    // Don't show the bottom area when we're showing results or errors
    if (state.status == ScanningStatus.success ||
        state.status == ScanningStatus.failure ||
        state.status == ScanningStatus.networkError ||
        state.status == ScanningStatus.productNotFound) {
      return const SizedBox.shrink();
    }

    // Show cancel button during scanning
    if (state.status == ScanningStatus.scanning) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton.icon(
                icon: const Icon(Icons.close, color: Colors.white),
                label: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.white),
                ),
                onPressed: () {
                  ref.read(foodScannerProvider.notifier).stopScanning();
                },
              ),
            ],
          ),
        ),
      );
    }

    // Show spinner during loading
    if (state.isLoading) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    // Don't show anything in other states
    return const SizedBox.shrink();
  }

  Widget _buildPermissionDeniedView() {
    return StatefulBuilder(
      builder: (context, setLocalState) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.pink.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.no_photography,
                    size: 64,
                    color: AppColors.pink,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Camera Permission Required',
                  style: AppTextStyles.h3,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'To scan food barcodes, we need access to your camera. Please grant permission in your device settings.',
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.mediumGrey,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                _buildPrimaryButton(
                  icon: Icons.settings,
                  label: 'Open Settings',
                  onPressed: () async {
                    try {
                      ref
                          .read(analyticsServiceProvider)
                          .logEvent(
                            name: 'camera_permission_action',
                            parameters: {'action': 'open_settings'},
                          );

                      // Just open settings since we can't directly request permission anymore
                      await ref
                          .read(permissionsServiceProvider)
                          .openDeviceSettings();

                      // After returning from settings, check if permission was granted
                      // Add a delay since permission changes might not be detected immediately
                      await Future.delayed(const Duration(seconds: 2));
                      final hasPermission =
                          await ref
                              .read(permissionsServiceProvider)
                              .hasCameraPermission();

                      if (hasPermission) {
                        ref
                            .read(analyticsServiceProvider)
                            .logEvent(
                              name: 'camera_permission_granted',
                              parameters: {'source': 'settings'},
                            );
                      }

                      setState(() {
                        _hasCameraPermission = hasPermission;
                      });
                    } catch (e) {
                      debugPrint('Error handling permission action: $e');
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () async {
                    try {
                      // Force a direct permission request, even though it might not show UI
                      final granted =
                          await ref
                              .read(permissionsServiceProvider)
                              .requestCameraPermission();
                      setState(() {
                        _hasCameraPermission = granted;
                      });
                    } catch (e) {
                      debugPrint('Error requesting permission: $e');
                    }
                  },
                  child: Text(
                    'Try Permission Request Again',
                    style: AppTextStyles.small.copyWith(
                      color: AppColors.popBlue,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPrimaryButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
  }) {
    return ElevatedButton.icon(
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.pink,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        elevation: 3,
      ),
      onPressed: onPressed,
    );
  }

  Widget _buildSecondaryButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return OutlinedButton.icon(
      icon: Icon(icon),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.pink,
        side: BorderSide(color: AppColors.pink),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
      onPressed: onPressed,
    );
  }
}
