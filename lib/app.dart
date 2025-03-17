// lib/app.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'flavors.dart';
import 'shared/config/router.dart';
import 'shared/theme/app_theme.dart';
import 'shared/components/feedback/shake_to_report.dart';
import 'shared/providers/feedback_provider.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Track the current route for the shake-to-report feature
    final _navigatorKey = GlobalKey<NavigatorState>();

    // Function to get current screen name for feedback
    String _getCurrentScreen() {
      final context = _navigatorKey.currentContext;
      if (context == null) return 'unknown';

      final route = ModalRoute.of(context);
      return route?.settings.name ?? 'unknown';
    }

    // Get current user ID for feedback
    final userId = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';

    // Use Consumer widget to handle the provider properly
    return Consumer(
      builder: (context, ref, child) {
        // Get the router inside the Consumer builder
        final router = ref.watch(routerProvider);

        return ShakeToReportManager(
          userId:
              FirebaseAuth.instance.currentUser?.uid ??
              'anonymous', // Make sure this evaluates to a valid value
          getCurrentScreen: _getCurrentScreen,
          child: MaterialApp.router(
            title: F.title,
            theme: AppTheme.lightTheme,
            routerConfig: router,
            builder: (context, child) {
              return _flavorBanner(
                child: child ?? const SizedBox(),
                show: kDebugMode,
              );
            },
          ),
        );
      },
    );
  }

  Widget _flavorBanner({required Widget child, bool show = true}) =>
      show
          ? Banner(
            location: BannerLocation.topStart,
            message: F.name,
            color: Colors.green.withOpacity(0.6),
            textStyle: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 12.0,
              letterSpacing: 1.0,
            ),
            textDirection: TextDirection.ltr,
            child: child,
          )
          : child;
}
