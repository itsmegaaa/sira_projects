class AppConstants {
  // MENGAPA private constructor (_):
  // Mencegah class ini di-instansiasi oleh developer lain (misal: AppConstants()).
  // Class ini murni hanya sebagai container variabel static.
  AppConstants._();

  // ==========================================
  // 1. INFO APLIKASI
  // ==========================================
  static const String appName = 'Gabut Tracker';
  static const String appVersion = '1.0.0';

  // ==========================================
  // 2. PATH FIRESTORE (Database Routes)
  // ==========================================
  // Path lama sebelum migrasi
  static const String legacyCollectionPath = 'data_notaris';

  // Path baru untuk arsitektur Multi-Bank (Fase 3)
  // MENGAPA menggunakan method: Agar path bisa dinamis sesuai bank yang di-passing
  static String getBankOrdersPath(String bankId) => 'banks/$bankId/orders';

  // Path untuk logs/histori global
  static const String logsCollectionPath = 'logs_notaris';
  static const String masterDataCollection = 'master_data';

  // ==========================================
  // 3. KUNCI SHARED PREFERENCES (Local Storage)
  // ==========================================
  static const String prefTargetSLA = 'target_sla';
  static const String prefTemaGelap = 'tema_gelap';
  static const String prefTerakhirNotif = 'terakhir_notif';

  // ==========================================
  // 4. NILAI DEFAULT (Konfigurasi Bisnis PPAT)
  // ==========================================
  static const int defaultTargetSLA = 30; // Hari
  static const int defaultPaginationLimit =
      50; // Jumlah dokumen ditarik per stream

  // ==========================================
  // 5. MASTER DATA STATIS (Untuk Portal UI)
  // ==========================================
  // Data ini digunakan di home_screen.dart untuk menggambar Card daftar bank
  static const List<Map<String, dynamic>> daftarBankTersedia = [
    {
      'id_bank': 'mandiri', // ID ini yang dilempar ke Repository saat diklik
      'nama': 'BANK MANDIRI',
      'gambar': 'assets/man.png',
      'gambar_loading': 'assets/mandiri_load.png',
      'warna_hex': 0xFF0D47A1, // Colors.blue.shade900
      'tersedia': true,
    },
    {
      'id_bank': 'bca',
      'nama': 'BANK BCA',
      'gambar': 'assets/bg_bca.png',
      'gambar_loading': 'assets/bg_bca.png',
      'warna_hex': 0xFF000000, // Black
      'tersedia': false,
    },
  ];
}
