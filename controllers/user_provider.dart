import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserProvider extends ChangeNotifier {
  String _role = "Loading...";
  String get role => _role;

  // Constructor: Fungsi ini akan otomatis berjalan saat aplikasi baru dibuka
  UserProvider() {
    // Memantau status Firebase Auth secara real-time
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null && user.email != null) {
        // Begitu user dikenali sistem, langsung gas ambil role-nya!
        _fetchRoleFromFirestore(user.email!);
      } else {
        // Jika tidak ada user login, kembalikan ke default
        _role = "STAFF";
        notifyListeners();
      }
    });
  }

  // Fungsi internal untuk menembak ke database Firestore
  Future<void> _fetchRoleFromFirestore(String email) async {
    try {
      var doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(email) // ID dokumen harus sama persis dengan email
          .get();

      if (doc.exists && doc.data() != null) {
        // Jika ketemu, ambil field 'role'
        _role = doc.data()!['role'] ?? 'STAFF';
      } else {
        // Jika email belum didaftarkan di tabel users, jadikan STAFF
        _role = 'STAFF';
      }
    } catch (e) {
      debugPrint("Error get role Firebase: $e");
      _role = 'STAFF'; // Pengaman jika internet putus/error
    }

    // Paksa seluruh layar (Drawer) untuk memperbarui tulisannya
    notifyListeners();
  }

  // Fungsi manual (opsional, jika ingin dipanggil paksa dari tombol Refresh)
  Future<void> fetchUserRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && user.email != null) {
      await _fetchRoleFromFirestore(user.email!);
    }
  }
}
