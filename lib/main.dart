import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/api/graphql_client.dart';
import 'core/constants/app_sizes.dart';
import 'core/theme/app_theme.dart';
import 'presentation/views/auth/login_view.dart';
import 'presentation/views/home/main_screen.dart';
import 'presentation/views/onboarding/onboarding_view.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(AppTheme.systemBarsStyle);
  FindsApiClient.initialize();
  await FindsApiClient.restoreSession();
  FindsApiClient.onSessionExpired = () {
    navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginView()),
      (_) => false,
    );
  };
  runApp(const FindsApp());
}

class FindsApp extends StatelessWidget {
  const FindsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: AppSizes.fontScaleNotifier,
      builder: (context, scale, _) {
        return MaterialApp(
          title: 'Finds',
          navigatorKey: navigatorKey,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          builder: (context, child) {
            final mediaQuery =
                MediaQuery.maybeOf(context) ??
                MediaQueryData.fromView(View.of(context));
            return MediaQuery(
              data: mediaQuery.copyWith(textScaler: TextScaler.linear(scale)),
              child: child ?? const SizedBox.shrink(),
            );
          },
          home: FindsApiClient.isAuthenticated
              ? const MainScreen()
              : const OnboardingView(),
        );
      },
    );
  }
}

// Alias pour compatibilité
typedef MyApp = FindsApp;
