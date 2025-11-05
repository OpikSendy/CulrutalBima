// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Config
import 'core/config/supabase_config.dart';
import 'core/constants/app_strings.dart';

import 'core/theme/app_theme.dart';

// ViewModels
import 'viewmodels/budaya_viewmodel.dart';
import 'viewmodels/wisata_viewmodel.dart';

// Screens
import 'views/screens/splash_screen.dart';
import 'views/screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // Initialize Supabase
  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Budaya ViewModel
        ChangeNotifierProvider(
          create: (_) => BudayaViewModel(),
        ),
        // Wisata ViewModel
        ChangeNotifierProvider(
          create: (_) => WisataViewModel(),
        ),
      ],
      child: MaterialApp(
        title: AppStrings.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.naturalTheme,
        home: const SplashScreen(),
        // Route configuration
        routes: {
          '/home': (context) => const HomeScreen(),
        },
      ),
    );
  }
}