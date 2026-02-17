import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'dart:io' as io show Platform;
import 'providers/bhu_provider.dart';
import 'screens/bhu_home_page.dart';
import 'dialogs/welcome_dialog.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  if (!kIsWeb && io.Platform.isWindows) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  
  runApp(const BHUControlApp());
}

class BHUControlApp extends StatelessWidget {
  const BHUControlApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => BHUProvider(),
      child: Consumer<BHUProvider>(
        builder: (context, provider, child) {
          return MaterialApp(
            title: 'BHU Control',
            debugShowCheckedModeBanner: false,
            theme: _buildTheme(ThemeData.light()),
            darkTheme: _buildTheme(ThemeData.dark()),
            themeMode: provider.themeMode,
            home: Builder(
              builder: (context) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  WelcomeDialog.showIfFirstLaunch(context);
                });
                return const BHUHomePage();
              },
            ),
            builder: (context, child) {
              return ScrollConfiguration(
                behavior: const MaterialScrollBehavior().copyWith(
                  overscroll: false,
                ),
                child: child!,
              );
            },
          );
        },
      ),
    );
  }

  ThemeData _buildTheme(ThemeData base) {
    return base.copyWith(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF2E86C1), // Azul BHU
        brightness: base.brightness,
      ).copyWith(
        primary: const Color(0xFF2E86C1), // Azul BHU principal
        secondary: const Color(0xFF3498DB), // Azul secundario
        tertiary: const Color(0xFF27AE60), // Verde para ganancias
        surface: base.brightness == Brightness.light
            ? const Color(0xFFF0F8FF) // Azul claro
            : const Color(0xFF0F172A), // Azul oscuro
        error: const Color(0xFFE74C3C), // Rojo BHU
      ),

      // Tipografía
      textTheme: base.textTheme.copyWith(
        headlineLarge: base.textTheme.headlineLarge?.copyWith(
          fontWeight: FontWeight.bold,
        ),
        titleLarge: base.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
        ),
        titleMedium: base.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: base.textTheme.bodyLarge?.copyWith(
          fontSize: 16,
        ),
        bodyMedium: base.textTheme.bodyMedium?.copyWith(
          fontSize: 14,
        ),
      ),

      // AppBar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFF2E86C1),
        foregroundColor: Colors.white,
        elevation: 4,
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Color(0xFF2E86C1),
          statusBarIconBrightness: Brightness.light,
        ),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.symmetric(vertical: 4),
      ),

      // Filled Button Theme
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF2E86C1),
          foregroundColor: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),

      // Outlined Button Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF2E86C1),
          side: const BorderSide(color: Color(0xFF2E86C1)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),

      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFF2E86C1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: base.brightness == Brightness.light
            ? Colors.grey.shade50
            : Colors.grey.shade900,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Colors.grey.shade300,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Colors.grey.shade300,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFF2E86C1),
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFFE74C3C),
            width: 1,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFFE74C3C),
            width: 2,
          ),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        hintStyle: TextStyle(
          color: Colors.grey.shade500,
        ),
        prefixIconColor: Colors.grey.shade600,
      ),

      // Floating Action Button Theme
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: Color(0xFF2E86C1),
        foregroundColor: Colors.white,
        elevation: 4,
      ),

      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: base.brightness == Brightness.light
            ? Colors.grey.shade200
            : Colors.grey.shade800,
        selectedColor: const Color(0xFF2E86C1).withOpacity(0.2),
        pressElevation: 2,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        labelStyle: TextStyle(
          color: base.brightness == Brightness.light
              ? Colors.black87
              : Colors.white70,
        ),
        side: BorderSide(
          color: Colors.grey.shade300,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      // List Tile Theme
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),

      // Snack Bar Theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: base.brightness == Brightness.light
            ? const Color(0xFF2C3E50)
            : const Color(0xFF34495E),
        contentTextStyle: const TextStyle(
          color: Colors.white,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        behavior: SnackBarBehavior.floating,
        elevation: 4,
      ),

      // Dialog Theme
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 8,
        backgroundColor: base.colorScheme.surface,
      ),

      // Bottom Sheet Theme
      bottomSheetTheme: BottomSheetThemeData(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(20),
          ),
        ),
        elevation: 8,
        backgroundColor: base.colorScheme.surface,
      ),

      // Divider Theme
      dividerTheme: DividerThemeData(
        color: Colors.grey.shade300,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
