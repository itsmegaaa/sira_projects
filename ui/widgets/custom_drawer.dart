// ignore_for_file: curly_braces_in_flow_control_structures, deprecated_member_use
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:sira_projects/ui/screens/portal/home_screen.dart';
import 'package:sira_projects/ui/screens/dashboard/mandiri_screen.dart';
import 'package:sira_projects/ui/screens/dashboard/bapenda_screen.dart';
import 'package:sira_projects/ui/screens/dashboard/sertifikat_screen.dart';
import 'package:sira_projects/ui/screens/profil/profil_screen.dart';
import 'package:sira_projects/controllers/user_provider.dart';

class CustomDrawer extends StatelessWidget {
  final String activeRoute;

  const CustomDrawer({super.key, required this.activeRoute});

  @override
  Widget build(BuildContext context) {
    final userRole = context.watch<UserProvider>().role;

    bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color navyColor = const Color(0xFF0F172A);
    final Color goldColor = const Color(0xFFD4AF37);
    Color currentBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    Color currentText = isDark ? Colors.white : navyColor;

    final userEmail = FirebaseAuth.instance.currentUser?.email ?? 'User';

    return Drawer(
      backgroundColor: currentBg,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(
              top: 60,
              bottom: 24,
              left: 24,
              right: 24,
            ),
            decoration: BoxDecoration(color: navyColor),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 60,
                  width: 60,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: Text(
                      userEmail.isNotEmpty ? userEmail[0].toUpperCase() : '?',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: goldColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'SIRA TRACKER',
                  style: TextStyle(
                    color: goldColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
                Text(
                  userEmail,
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: goldColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'ROLE: $userRole',
                    style: TextStyle(
                      color: goldColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 12),
              physics: const BouncingScrollPhysics(),
              children: [
                _buildItem(
                  context,
                  'Beranda',
                  Icons.home_rounded,
                  'HOME',
                  const HomeScreen(),
                  currentText,
                  goldColor,
                ),
                _buildItem(
                  context,
                  'Modul Mandiri',
                  Icons.account_balance_rounded,
                  'MANDIRI',
                  const MandiriScreen(),
                  currentText,
                  goldColor,
                ),
                _buildItem(
                  context,
                  'Modul Bapenda',
                  Icons.domain_rounded,
                  'BAPENDA',
                  const BapendaScreen(),
                  currentText,
                  goldColor,
                ),
                _buildItem(
                  context,
                  'Monitoring Sertifikat',
                  Icons.assignment_rounded,
                  'SERTIFIKAT',
                  const SertifikatScreen(),
                  currentText,
                  goldColor,
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  child: Divider(),
                ),
                _buildItem(
                  context,
                  'Profil Akun',
                  Icons.person_rounded,
                  'PROFIL',
                  const ProfilScreen(),
                  currentText,
                  goldColor,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItem(
    BuildContext context,
    String title,
    IconData icon,
    String routeId,
    Widget destination,
    Color textColor,
    Color activeColor,
  ) {
    bool isActive = activeRoute == routeId;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        tileColor: isActive ? activeColor.withOpacity(0.1) : Colors.transparent,
        leading: Icon(
          icon,
          color: isActive ? activeColor : Colors.grey.shade500,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isActive ? activeColor : textColor,
            fontWeight: isActive ? FontWeight.w900 : FontWeight.w600,
          ),
        ),
        onTap: () {
          Navigator.pop(context);
          if (!isActive) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => destination),
            );
          }
        },
      ),
    );
  }
}
