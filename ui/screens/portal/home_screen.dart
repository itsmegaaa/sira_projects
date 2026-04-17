import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:gabut_tracker/ui/screens/dashboard/mandiri_screen.dart';
import 'package:gabut_tracker/ui/screens/dashboard/bapenda_screen.dart';
import 'package:gabut_tracker/ui/screens/profil/profil_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  String _getSapaan() {
    var jam = DateTime.now().hour;
    if (jam >= 3 && jam < 11) {
      return 'Selamat Pagi';
    } else if (jam >= 11 && jam < 15) {
      return 'Selamat Siang';
    } else if (jam >= 15 && jam < 18) {
      return 'Selamat Sore';
    } else {
      return 'Selamat Malam';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Data untuk kartu Dashboard di Home Screen
    final List<Map<String, dynamic>> daftarBank = [
      {
        'nama': 'BANK MANDIRI',
        'gambar': 'assets/man.png',
        'warna': Colors.blue.shade900,
        'tersedia': true,
      },
      {
        'nama': 'BAPENDA',
        'gambar': 'assets/bg_bca.png',
        'warna': const Color.fromARGB(255, 202, 175, 51),
        'tersedia': true,
      },
    ];

    return Scaffold(
      backgroundColor: Colors.grey.shade200,
      appBar: AppBar(
        backgroundColor: Colors.grey.shade200,
        elevation: 0,
        titleSpacing: 20,
        toolbarHeight: 80,
        // Header profil yang bisa diklik untuk menuju ProfilScreen
        title: InkWell(
          borderRadius: BorderRadius.circular(30),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ProfilScreen()),
            );
          },
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.white,
                child: Text(
                  FirebaseAuth.instance.currentUser?.email?.isNotEmpty == true
                      ? FirebaseAuth.instance.currentUser!.email![0]
                            .toUpperCase()
                      : '?',
                  style: const TextStyle(
                    color: Colors.blueAccent,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 15),
              // --- TAMBAHKAN EXPANDED DI SINI ---
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Halo, ${_getSapaan()} 👋',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                        letterSpacing: -0.8,
                      ),
                      overflow: TextOverflow
                          .ellipsis, // Mencegah error teks kepanjangan
                    ),
                    const Text(
                      'Ketuk untuk lihat Profil',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                      overflow: TextOverflow
                          .ellipsis, // Mencegah error teks kepanjangan
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 20),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
              onPressed: () async {
                bool confirm = await _konfirmasiLogout(context);
                if (confirm) await FirebaseAuth.instance.signOut();
              },
            ),
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: daftarBank.length,
        itemBuilder: (context, index) {
          final bank = daftarBank[index];

          return Card(
            margin: const EdgeInsets.only(bottom: 20),
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () {
                if (bank['tersedia']) {
                  Widget screenTujuan = bank['nama'] == 'BAPENDA'
                      ? const BapendaScreen()
                      : const MandiriScreen();

                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => screenTujuan),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Dashboard ${bank['nama']} belum tersedia.',
                      ),
                    ),
                  );
                }
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    height: 140,
                    color: bank['warna'].withOpacity(0.1),
                    child: Image.asset(
                      bank['gambar'],
                      fit: BoxFit.cover,
                      errorBuilder: (context, e, s) => Icon(
                        Icons.account_balance,
                        size: 60,
                        color: bank['warna'],
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: Colors.white,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          bank['nama'],
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: bank['warna'],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: bank['warna'],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<bool> _konfirmasiLogout(BuildContext context) async {
    return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Keluar'),
            content: const Text('Yakin ingin keluar aplikasi?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('BATAL'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'KELUAR',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }
}
