import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'controllers/airplay_controller.dart';
import 'views/home_view.dart';
import 'views/settings_view.dart';
import 'views/video_streaming_view.dart';
import 'views/debug_log_view.dart';
import 'views/connection_test_view.dart';
import 'views/automated_test_view.dart';
import 'constants/app_constants.dart';

void main() {
  runApp(const PadCastApp());
}

class PadCastApp extends StatelessWidget {
  const PadCastApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AirPlayController()),
      ],
      child: MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,

          // 针对平板优化的主题
          visualDensity: VisualDensity.adaptivePlatformDensity,

          // 卡片主题
          cardTheme: CardThemeData(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppConstants.cardRadius),
            ),
          ),

          // 按钮主题
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConstants.buttonRadius),
              ),
            ),
          ),

          // AppBar主题
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black87,
            elevation: 0,
            centerTitle: false,
          ),
        ),

        // 路由配置
        routes: {
          '/': (context) => const HomeView(),
          '/settings': (context) => const SettingsView(),
          '/video': (context) => const VideoStreamingView(),
          '/debug': (context) => const DebugLogView(),
          '/connectionTest': (context) => const ConnectionTestView(),
          '/automatedTest': (context) => const AutomatedTestView(),
        },

        initialRoute: '/',
      ),
    );
  }
}
