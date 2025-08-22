import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

/// 主题工具类
class ThemeUtils {
  // 颜色常量
  static const Color primaryBlue = Color(0xFF2196F3);
  static const Color secondaryBlue = Color(0xFF1976D2);
  static const Color accentBlue = Color(0xFF03DAC6);
  
  static const Color successGreen = Color(0xFF4CAF50);
  static const Color warningOrange = Color(0xFFFF9800);
  static const Color errorRed = Color(0xFFF44336);
  
  static const Color surfaceColor = Color(0xFFFAFAFA);
  static const Color cardColor = Colors.white;
  static const Color dividerColor = Color(0xFFE0E0E0);
  
  /// 获取应用主题
  static ThemeData getAppTheme() {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryBlue,
        brightness: Brightness.light,
        surface: surfaceColor,
      ),
      useMaterial3: true,
      
      // 字体
      fontFamily: 'system-ui',
      
      // 视觉密度
      visualDensity: VisualDensity.adaptivePlatformDensity,
      
      // 卡片主题
      cardTheme: CardThemeData(
        elevation: 2,
        color: cardColor,
        shadowColor: Colors.black.withValues(alpha: 0.1),
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
          elevation: 2,
          shadowColor: Colors.black.withValues(alpha: 0.1),
        ),
      ),
      
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.buttonRadius),
          ),
          side: const BorderSide(color: primaryBlue, width: 1.5),
        ),
      ),
      
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.buttonRadius),
          ),
        ),
      ),
      
      // AppBar主题
      appBarTheme: const AppBarTheme(
        backgroundColor: cardColor,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
      
      // 输入框主题
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: dividerColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: dividerColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primaryBlue, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      
      // Divider主题
      dividerTheme: const DividerThemeData(
        color: dividerColor,
        thickness: 1,
        space: 1,
      ),
      
      // Switch主题
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryBlue;
          }
          return Colors.grey[400];
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryBlue.withValues(alpha: 0.5);
          }
          return Colors.grey[300];
        }),
      ),
      
      // SnackBar主题
      snackBarTheme: SnackBarThemeData(
        backgroundColor: Colors.grey[800],
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      
      // Dialog主题
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.cardRadius),
        ),
        elevation: 8,
      ),
    );
  }
  
  /// 获取暗色主题
  static ThemeData getDarkTheme() {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryBlue,
        brightness: Brightness.dark,
      ),
      useMaterial3: true,
      fontFamily: 'system-ui',
      visualDensity: VisualDensity.adaptivePlatformDensity,
      
      // 其他暗色主题配置...
    );
  }
  
}

/// 状态颜色
class StatusColors {
  static const Color success = ThemeUtils.successGreen;
  static const Color warning = ThemeUtils.warningOrange;
  static const Color error = ThemeUtils.errorRed;
  static const Color info = ThemeUtils.primaryBlue;
  
  static Color successLight = ThemeUtils.successGreen.withValues(alpha: 0.1);
  static Color warningLight = ThemeUtils.warningOrange.withValues(alpha: 0.1);
  static Color errorLight = ThemeUtils.errorRed.withValues(alpha: 0.1);
  static Color infoLight = ThemeUtils.primaryBlue.withValues(alpha: 0.1);
}

/// 阴影样式
class Shadows {
    static List<BoxShadow> get small => [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.1),
        offset: const Offset(0, 1),
        blurRadius: 3,
        spreadRadius: 0,
      ),
    ];
    
    static List<BoxShadow> get medium => [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.1),
        offset: const Offset(0, 2),
        blurRadius: 6,
        spreadRadius: 0,
      ),
    ];
    
    static List<BoxShadow> get large => [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.15),
        offset: const Offset(0, 4),
        blurRadius: 12,
        spreadRadius: 0,
      ),
    ];
    
    static List<BoxShadow> get floating => [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.2),
        offset: const Offset(0, 8),
        blurRadius: 24,
        spreadRadius: 0,
      ),
    ];
  }

/// 获取主题颜色
Color getThemeColor(BuildContext context, String colorName) {
  final theme = Theme.of(context);
  switch (colorName) {
    case 'primary':
      return theme.colorScheme.primary;
    case 'secondary':
      return theme.colorScheme.secondary;
    case 'surface':
      return theme.colorScheme.surface;
    case 'background':
      return theme.colorScheme.surface;
    case 'error':
      return theme.colorScheme.error;
    default:
      return theme.colorScheme.primary;
  }
}
  
/// 获取文本颜色
Color getTextColor(BuildContext context, {bool isSecondary = false}) {
  final theme = Theme.of(context);
  return isSecondary 
      ? theme.colorScheme.onSurface.withValues(alpha: 0.6)
      : theme.colorScheme.onSurface;
}

/// 间距
class Spacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

/// 边框半径
class BorderRadiusValues {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double circle = 50;
}

/// 渐变样式
class Gradients {
  static const LinearGradient primary = LinearGradient(
    colors: [ThemeUtils.primaryBlue, ThemeUtils.secondaryBlue],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient success = LinearGradient(
    colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient warning = LinearGradient(
    colors: [Color(0xFFFF9800), Color(0xFFE65100)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient error = LinearGradient(
    colors: [Color(0xFFF44336), Color(0xFFC62828)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static LinearGradient get shimmer => LinearGradient(
    colors: [
      Colors.grey[300]!,
      Colors.grey[100]!,
      Colors.grey[300]!,
    ],
    stops: const [0.0, 0.5, 1.0],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
}

/// 字体样式
class TextStyles {
  static const TextStyle heading1 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 1.2,
  );
  
  static const TextStyle heading2 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );
  
  static const TextStyle heading3 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );
  
  static const TextStyle body1 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );
  
  static const TextStyle body2 = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.4,
  );
  
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.3,
  );
  
  static TextStyle button = const TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
  );
}