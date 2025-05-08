// lib/features/settings/screens/gdpr_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../shared/services/gdpr_service.dart';
import '../../../shared/theme/app_text_styles.dart';
import '../../../shared/components/buttons/primary_button.dart';
import '../../../shared/theme/app_colors.dart';

class GdprSettingsScreen extends ConsumerStatefulWidget {
  const GdprSettingsScreen({super.key});

  @override
  ConsumerState<GdprSettingsScreen> createState() => _GdprSettingsScreenState();
}

class _GdprSettingsScreenState extends ConsumerState<GdprSettingsScreen> {
  bool _isLoading = false;
  final GdprService _gdprService = GdprService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy Settings')),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Your Privacy Rights', style: AppTextStyles.h2),
                    const SizedBox(height: 16),
                    Text(
                      'Under GDPR and related privacy laws, you have the right to access and delete your personal data.',
                      style: AppTextStyles.body,
                    ),
                    const SizedBox(height: 24),
                    _buildDataExportSection(),
                    const SizedBox(height: 32),
                    _buildDataDeletionSection(),
                  ],
                ),
              ),
    );
  }

  Widget _buildDataExportSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Export Your Data', style: AppTextStyles.h3),
            const SizedBox(height: 8),
            Text(
              'Download a copy of all the data we have stored about you.',
              style: AppTextStyles.body,
            ),
            const SizedBox(height: 16),
            PrimaryButton(
              onPressed: _exportData,
              text: 'Export My Data',
              icon: Icons.download,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataDeletionSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Delete Your Account', style: AppTextStyles.h3),
            const SizedBox(height: 8),
            Text(
              'This will permanently delete your account and all associated data. This action cannot be undone.',
              style: AppTextStyles.body,
            ),
            const SizedBox(height: 16),
            PrimaryButton(
              onPressed: _confirmDeleteAccount,
              text: 'Delete My Account',
              backgroundColor: AppColors.error,
              icon: Icons.delete_forever,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportData() async {
    final user = _auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to export data')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final userData = await _gdprService.exportUserData(user.uid);

      // Convert data to JSON
      final jsonData = jsonEncode(userData);

      // Get temp directory
      final directory = await getTemporaryDirectory();
      final filePath = '${directory.path}/my_data.json';

      // Write to file
      final file = File(filePath);
      await file.writeAsString(jsonData);

      // Share the file
      await Share.shareXFiles([
        XFile(filePath),
      ], text: 'Here is your exported data from Bums & Tums');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your data has been exported successfully'),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error exporting data: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _confirmDeleteAccount() async {
    final result = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Account'),
            content: const Text(
              'Are you sure you want to delete your account? This action cannot be undone and all your data will be permanently deleted.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text('Delete', style: TextStyle(color: AppColors.error)),
              ),
            ],
          ),
    );

    if (result == true) {
      await _deleteAccount();
    }
  }

Future<void> _deleteAccount() async {
  final user = _auth.currentUser;
  if (user == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('You must be logged in to delete your account'),
      ),
    );
    return;
  }

  setState(() {
    _isLoading = true;
  });

  try {
    // Store the user ID before deleting
    final userId = user.uid;
    
    // Delete all data except the auth user
    await _gdprService.deleteUserDataWithoutAuth(userId);
    
    // Now delete the auth user
    await user.delete();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Your account has been deleted')),
    );

    // Navigate to login screen
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error deleting account: ${e.toString()}')),
    );
  } finally {
    setState(() {
      _isLoading = false;
    });
  }
}
}
