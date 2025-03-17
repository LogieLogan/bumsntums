// lib/features/nutrition/screens/scanner_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/food_scanner_provider.dart';
import '../services/barcode_scanner_service.dart';
import 'food_details_screen.dart';
import '../../../shared/components/buttons/primary_button.dart';
import '../../../shared/components/indicators/loading_indicator.dart';
import '../../../shared/theme/color_palette.dart';

class ScannerScreen extends ConsumerStatefulWidget {
  const ScannerScreen({super.key});

  @override
  ConsumerState<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends ConsumerState<ScannerScreen> {
  @override
  void initState() {
    super.initState();
    // Initialize the scanner state
    Future.microtask(() => ref.read(foodScannerProvider.notifier).initialize());
  }

  Future<void> _startScanning() async {
    final scannerService = ref.read(barcodeScannerServiceProvider);
    final scannerNotifier = ref.read(foodScannerProvider.notifier);
    
    // Check if we've reached scan limit
    final scannerState = ref.read(foodScannerProvider);
    if (scannerState.isScanLimitReached) {
      return;
    }
    
    // Start scanning UI state
    scannerNotifier.startScanning();
    
    // Initiate the scan
    final barcode = await scannerService.scanBarcode(context);
    
    // Handle scan result
    if (barcode != null && scannerService.isValidBarcode(barcode)) {
      await scannerNotifier.processBarcode(barcode);
    } else {
      // User canceled or invalid barcode
      scannerNotifier.stopScanning();
    }
  }

  @override
  Widget build(BuildContext context) {
    final scannerState = ref.watch(foodScannerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Food Scanner'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              // Show scan history here (not implemented in this update)
            },
          ),
        ],
      ),
      body: _buildBody(scannerState),
    );
  }

  Widget _buildBody(FoodScannerState state) {
    // Show loading indicator while processing
    if (state.isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            LoadingIndicator(),
            SizedBox(height: 16),
            Text('Processing barcode...'),
          ],
        ),
      );
    }

    // Show scanned product details
    if (state.status == ScanningStatus.success && state.scannedItem != null) {
      // Navigate to details screen after successful scan
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context)
            .push(
              MaterialPageRoute(
                builder: (context) =>
                    FoodDetailsScreen(foodItem: state.scannedItem!),
              ),
            )
            .then((_) {
              // Reset scanner when returning from details screen
              ref.read(foodScannerProvider.notifier).clearScan();
            });
      });
      return const Center(child: LoadingIndicator());
    }

    // Show error messages
    if (state.status == ScanningStatus.failure ||
        state.status == ScanningStatus.networkError ||
        state.status == ScanningStatus.productNotFound) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
              const SizedBox(height: 16),
              Text(
                state.errorMessage ?? 'Something went wrong',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                text: 'Try Again',
                onPressed: _startScanning,
              ),
            ],
          ),
        ),
      );
    }

    // Default idle state - show start scanning button
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.camera_alt_outlined,
              size: 80,
              color: AppColors.pink.withOpacity(0.8),
            ),
            const SizedBox(height: 24),
            const Text(
              'Scan food barcodes to track your nutrition',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 16),
            if (state.isScanLimitReached) ...[
              Text(
                'You have reached your daily scan limit (${state.scanCount}/${state.freeTierLimit})',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 16),
              PrimaryButton(
                text: 'Upgrade to Premium',
                onPressed: () {
                  // Implement upgrade flow
                },
              ),
            ] else ...[
              Text(
                'Scans remaining today: ${state.freeTierLimit - state.scanCount}',
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                text: 'Start Scanning',
                onPressed: _startScanning,
              ),
            ],
            const SizedBox(height: 16),
            if (state.recentScans.isNotEmpty) ...[
              const Text(
                'Recent Scans',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount:
                      state.recentScans.length > 5 ? 5 : state.recentScans.length,
                  itemBuilder: (context, index) {
                    final item = state.recentScans[index];
                    return Card(
                      margin: const EdgeInsets.only(right: 12),
                      child: InkWell(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) =>
                                  FoodDetailsScreen(foodItem: item),
                            ),
                          );
                        },
                        child: SizedBox(
                          width: 100,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Expanded(
                                child: item.imageUrl != null &&
                                        item.imageUrl!.isNotEmpty
                                    ? Image.network(
                                        item.imageUrl!,
                                        fit: BoxFit.contain,
                                        errorBuilder: (_, __, ___) =>
                                            const Icon(Icons.no_food),
                                      )
                                    : const Icon(Icons.no_food),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  item.name,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}