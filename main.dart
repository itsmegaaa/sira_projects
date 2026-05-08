import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'package:provider/provider.dart';

// --- IMPOR UTILITAS & LAYAR UTAMA ---
import 'package:sira_projects/core/utils/globals.dart';
import 'package:sira_projects/ui/screens/auth/login_screen.dart';
import 'package:sira_projects/ui/screens/portal/home_screen.dart';

// --- IMPOR EKOSISTEM MANDIRI ---
import 'package:sira_projects/data/repositories/mandiri_repository.dart';
import 'package:sira_projects/controllers/mandiri_controller.dart';

// --- IMPOR EKOSISTEM BAPENDA ---
import 'package:sira_projects/data/repositories/bapenda_repository.dart';
import 'package:sira_projects/controllers/bapenda_controller.dart';

// --- IMPOR MASTER DATA ---
import 'package:sira_projects/data/repositories/master_data_repository.dart';
import 'package:sira_projects/controllers/user_provider.dart';

// --- BANK TEMPLATE ---
import 'package:sira_projects/controllers/sertifikat_controller.dart';
import 'package:sira_projects/data/repositories/sertifikat_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Pengaturan Cache Database Internal (Bisa digunakan offline sementara)
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: 40 * 1024 * 1024,
  );

  // Memuat pengaturan tema menggunakan ThemeController
  final themeController = ThemeController();
  await themeController.muatDariPrefs();

  runApp(
    // ========================================================
    // MULTIPROVIDER: PUSAT DEPENDENCY INJECTION (OTAK APLIKASI)
    // ========================================================
    MultiProvider(
      providers: [
        // 0. THEME CONTROLLER
        ChangeNotifierProvider<ThemeController>.value(value: themeController),

        // 1. LAYER DATA (REPOSITORIES) - Jalur ke Database
        Provider<MandiriRepository>(create: (_) => MandiriRepository()),
        Provider<BapendaRepository>(create: (_) => BapendaRepository()),
        Provider<MasterDataRepository>(
          create: (_) => MasterDataRepository(),
        ), // TAMBAHAN INJEKSI MASTER DATA
        // 2. LAYER LOGIKA BISNIS (CONTROLLERS) - Pengolah Data
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider<MandiriController>(
          create: (context) =>
              MandiriController(repo: context.read<MandiriRepository>()),
        ),
        ChangeNotifierProvider<BapendaController>(
          create: (context) =>
              BapendaController(repo: context.read<BapendaRepository>()),
        ),
        ChangeNotifierProvider(
          create: (_) => SertifikatController(repo: SertifikatRepository()),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Menggunakan ThemeController dari Provider (bukan ValueListenableBuilder global)
    final themeMode = context.watch<ThemeController>().themeMode;

    return MaterialApp(
      title: 'Laporan Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blueAccent,
          brightness: Brightness.dark,
          surface: const Color(0xFF121212),
        ),
        scaffoldBackgroundColor: const Color(0xFF121212),
        useMaterial3: true,
      ),
      themeMode: themeMode,
      home: const AuthGate(),
    );
  }
}

// === PENJAGA PINTU LOGIN (AUTH GATE) ===
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    // Memantau apakah user sedang login atau logout secara real-time
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Jika sudah ada data login (user session ada), langsung ke HomeScreen
        if (snapshot.hasData) {
          return const HomeScreen();
        }

        // Jika belum login, lempar ke halaman Login
        return const LoginScreen();
      },
    );
  }
}
